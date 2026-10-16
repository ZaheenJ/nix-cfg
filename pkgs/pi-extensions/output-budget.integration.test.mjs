import assert from "node:assert/strict";
import { once } from "node:events";
import { mkdir, mkdtemp, readFile, writeFile, rm } from "node:fs/promises";
import { createServer } from "node:http";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import { pathToFileURL } from "node:url";

const MODEL = "islamsidratul/Qwen3.8-27B-ByteShape-IQ4_XS-ASCII-GGUF:IQ4_XS";
const packageDir = process.env.BILI_PACKAGE_DIR;

test("patched pinned proxy repairs budgets before its real compressed-input clamp", { skip: !packageDir, timeout: 30000 }, async (context) => {
	const temporary = await mkdtemp(join(tmpdir(), "pi-output-budget-"));
	const originalEnv = { ...process.env };
	context.after(async () => {
		for (const key of Object.keys(process.env)) if (!(key in originalEnv)) delete process.env[key];
		Object.assign(process.env, originalEnv);
		await rm(temporary, { recursive: true, force: true });
	});
	for (const key of Object.keys(process.env)) {
		if (/proxy/i.test(key) || key.startsWith("ACP_") || key.startsWith("BILI_")) delete process.env[key];
	}
	Object.assign(process.env, {
		HOME: temporary,
		XDG_CONFIG_HOME: join(temporary, "config"),
		XDG_DATA_HOME: join(temporary, "data"),
		XDG_STATE_HOME: join(temporary, "state"),
		XDG_CACHE_HOME: join(temporary, "cache"),
		BILI_PERSIST: "0",
		ACP_AUTO_UPDATE: "0",
	});
	const cacheDirectory = join(temporary, "cache", "billion-context");
	await mkdir(cacheDirectory, { recursive: true });
	await writeFile(join(cacheDirectory, "models-dev.json"), JSON.stringify({ models: {}, costs: { test: { input: 1, output: 1 } } }));
	const bundlePath = join(packageDir, "dist/index.js");
	const helperUrl = pathToFileURL(join(packageDir, "dist/repair-output-budget.mjs")).href;
	const source = (await readFile(bundlePath, "utf8"))
		.replace('from "./repair-output-budget.mjs"', `from ${JSON.stringify(helperUrl)}`);
	assert.ok(source.includes("repairPiOutputBudget(parsed,req.headers"));
	const instrumented = join(temporary, "proxy.mjs");
	await writeFile(instrumented, source + "\nexport { startServer, loadOptions, clampOutputBudget };\n");
	const { startServer, loadOptions, clampOutputBudget } = await import(pathToFileURL(instrumented));
	assert.equal(clampOutputBudget(65536, 21663, 65536), 41825);
	assert.ok(clampOutputBudget(65536, 21663, 65536) > 32768);
	assert.equal(clampOutputBudget(3312, 21663, 65536), undefined);
	assert.equal(clampOutputBudget(65536, 60000, 65536), 2536);
	assert.equal(clampOutputBudget(65536, 65000, 65536), undefined);

	const forwarded = [];
	const upstream = createServer(async (request, response) => {
		let body = "";
		for await (const chunk of request) body += chunk;
		const payload = JSON.parse(body);
		forwarded.push(payload);
		const inputEstimate = payload.messages.some((message) => message.role === "user" && message.content.length > 200000) ? 65000 : 21663;
		if (inputEstimate + payload.max_tokens > 65536) {
			response.writeHead(400, { "content-type": "application/json" });
			response.end(JSON.stringify({ error: { message: "context window exceeded", type: "invalid_request_error" } }));
			return;
		}
		response.writeHead(200, { "content-type": "text/event-stream" });
		response.end('data: {"id":"test","choices":[{"index":0,"delta":{"content":"OK"},"finish_reason":null}]}\n\ndata: {"id":"test","choices":[{"index":0,"delta":{},"finish_reason":"stop"}],"usage":{"prompt_tokens":21663,"completion_tokens":1,"total_tokens":21664}}\n\ndata: [DONE]\n\n');
	});
	upstream.listen(0, "127.0.0.1");
	await once(upstream, "listening");
	context.after(() => { upstream.closeAllConnections(); upstream.close(); });
	const upstreamUrl = `http://127.0.0.1:${upstream.address().port}`;
	const logFile = join(temporary, "bili.log");
	const options = loadOptions({
		...process.env,
		ACP_UPSTREAM: upstreamUrl,
		ACP_LOG_FILE: logFile,
		ACP_MITM: "0",
	});
	const proxy = await startServer({ ...options, port: 0, host: "127.0.0.1" });
	if (!proxy.listening) await once(proxy, "listening");
	context.after(() => { proxy.closeAllConnections(); proxy.close(); });
	const proxyUrl = `http://127.0.0.1:${proxy.address().port}`;
	const tool = { type: "function", function: { name: "read", description: "Read a file", parameters: { type: "object", properties: {} } } };
	const headers = {
		"content-type": "application/json",
		"x-bili-plugin": "pi",
		"x-bili-plugin-model": MODEL,
		"x-bili-plugin-context-window": "65536",
		"x-bili-plugin-max-output": "65536",
	};
	async function send(overrides = {}, headerOverrides = {}, target = proxyUrl) {
		const payload = {
			model: MODEL, stream: true, max_tokens: 3312, tools: [tool],
			messages: [{ role: "user", content: "data ".repeat(17000) }],
			...overrides,
		};
		const response = await fetch(`${target}/v1/chat/completions`, {
			method: "POST", headers: { ...headers, "x-bili-plugin-conversation": crypto.randomUUID(), ...headerOverrides },
			body: JSON.stringify(payload), signal: AbortSignal.timeout(10000),
		});
		return { status: response.status, body: await response.text() };
	}
	const repaired = await send();
	assert.equal(repaired.status, 200, repaired.body);
	assert.ok(repaired.body.includes("[DONE]"));
	assert.ok(forwarded.at(-1).max_tokens > 32768);
	assert.ok(forwarded.at(-1).max_tokens < 65536);
	const logs = await readFile(logFile, "utf8");
	assert.match(logs, /pi output budget repaired 3312 -> 65536/);
	assert.match(logs, /output budget clamped 65536 ->/);

	const side = await send({}, { "x-bili-plugin-agent": "title" });
	assert.equal(side.status, 200, side.body);
	assert.equal(forwarded.at(-1).max_tokens, 3312);
	const other = await send({ model: "byteshape/Qwen3.8-27B-GGUF:IQ4_XS" });
	assert.equal(other.status, 200, other.body);
	assert.equal(forwarded.at(-1).max_tokens, 3312);
	const nearFull = await send({ messages: [{ role: "user", content: "data ".repeat(52000) }] });
	assert.ok(nearFull.status >= 400 || nearFull.body.includes('"error"'), nearFull.body.slice(0, 300));
	assert.match(await readFile(logFile, "utf8"), /over-window payload was NOT forwarded/);
	proxy.closeAllConnections();
	await new Promise((resolve, reject) => proxy.close((error) => error ? reject(error) : resolve()));
	await assert.rejects(() => send(), /fetch failed/);
	const direct = await send({}, {}, upstreamUrl);
	assert.equal(direct.status, 200, direct.body);
	assert.equal(forwarded.at(-1).max_tokens, 3312);
});
