import assert from "node:assert/strict";
import test from "node:test";
import { repairPiOutputBudget } from "./repair-output-budget.mjs";
import { patchOutputBudget } from "./patch-output-budget.mjs";

const MODEL = "islamsidratul/Qwen3.8-27B-ByteShape-IQ4_XS-ASCII-GGUF:IQ4_XS";
const PATCH_POINT = "restoreOutputBudget(parsed,session,log2,resolveConfiguredOutputLimit(opts.routes,route?.rewrittenUrl,parsed.model));";

function request(overrides = {}) {
	return { model: MODEL, stream: true, max_tokens: 3312, tools: [{ type: "function" }], ...overrides };
}

function headers(overrides = {}) {
	return {
		"x-bili-plugin": "pi",
		"x-bili-plugin-model": MODEL,
		"x-bili-plugin-context-window": "65536",
		"x-bili-plugin-max-output": "65536",
		...overrides,
	};
}

function repair(payload, requestHeaders = headers(), protocol = "openai", sideRequest = false) {
	const logs = [];
	repairPiOutputBudget(payload, requestHeaders, protocol, sideRequest, "test-session", (...args) => logs.push(args));
	return logs;
}

test("repairs the incident's stale pre-compression allowance without a 32k ceiling", () => {
	const payload = request({ max_tokens: 65536 - 57963 - 165 - 4096 });
	assert.equal(payload.max_tokens, 3312);
	assert.deepEqual(repair(payload), [["info", "[test-session] pi output budget repaired 3312 -> 65536; compressed-input clamp follows"]]);
	assert.equal(payload.max_tokens, 65536);
	assert.deepEqual(repair(payload), []);
});

test("uses advertised capabilities rather than hardcoding an output allowance", () => {
	const payload = request();
	repair(payload, headers({ "x-bili-plugin-max-output": "49152" }));
	assert.equal(payload.max_tokens, 49152);
	repair(payload, headers({ "x-bili-plugin-max-output": "131072" }));
	assert.equal(payload.max_tokens, 65536);
});

test("does not modify non-target, direct, side, or unsupported requests", () => {
	const scenarios = [
		[request({ model: "byteshape/Qwen3.8-27B-GGUF:IQ4_XS" }), headers()],
		[request(), headers({ "x-bili-plugin-model": "other" })],
		[request(), {}],
		[request(), headers({ "x-bili-plugin": "omp" })],
		[request(), headers({ "x-bili-plugin-bypass": "1" })],
		[request(), headers(), "anthropic"],
		[request(), headers(), "openai", true],
		[request({ stream: false }), headers()],
		[request({ tools: [] }), headers()],
		[request({ tools: undefined }), headers()],
		[request({ max_completion_tokens: 1000 }), headers()],
		[request({ max_output_tokens: 1000 }), headers()],
		[null, headers()],
	];
	for (const [payload, requestHeaders, protocol, sideRequest] of scenarios) {
		const original = structuredClone(payload);
		assert.deepEqual(repair(payload, requestHeaders, protocol, sideRequest), []);
		assert.deepEqual(payload, original);
	}
});

test("rejects missing or malformed limits and invalid existing budgets", () => {
	for (const field of ["x-bili-plugin-context-window", "x-bili-plugin-max-output"]) {
		for (const value of [undefined, "", "0", "-1", "NaN", "Infinity", "65536junk", "1.5", "9007199254740992", ["65536"]]) {
			const payload = request();
			assert.deepEqual(repair(payload, headers({ [field]: value })), []);
			assert.equal(payload.max_tokens, 3312);
		}
	}
	for (const value of [undefined, 0, -1, NaN, Infinity, 1.5, "3312", 65536, 100000]) {
		const payload = request({ max_tokens: value });
		assert.deepEqual(repair(payload), []);
		assert.equal(payload.max_tokens, value);
	}
});

test("patches only the expected pinned call site and preserves the shebang", () => {
	const source = `#!/usr/bin/env node\n${PATCH_POINT}\n`;
	const patched = patchOutputBudget(source, "0.1.178");
	assert.ok(patched.startsWith('#!/usr/bin/env node\nimport { repairPiOutputBudget }'));
	assert.ok(patched.includes(`session.id,log2);${PATCH_POINT}`));
	assert.throws(() => patchOutputBudget(patched, "0.1.178"), /already applied/);
	assert.throws(() => patchOutputBudget(source, "0.1.179"), /Unsupported/);
	assert.throws(() => patchOutputBudget("#!/usr/bin/env node\n", "0.1.178"), /exactly one/);
	assert.throws(() => patchOutputBudget(source + PATCH_POINT, "0.1.178"), /exactly one/);
	assert.throws(() => patchOutputBudget(PATCH_POINT, "0.1.178"), /shebang/);
});
