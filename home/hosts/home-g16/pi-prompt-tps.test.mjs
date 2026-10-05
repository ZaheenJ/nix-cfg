import assert from "node:assert/strict";
import test from "node:test";
import promptTps from "./pi-prompt-tps.ts";

test("averages decode speed across model responses in one prompt", () => {
	const handlers = new Map();
	const statuses = [];
	const ctx = {
		ui: {
			setStatus(key, value) {
				assert.equal(key, "prompt-tps");
				statuses.push(value);
			},
		},
	};
	let now = 0;
	const originalPerformance = globalThis.performance;
	globalThis.performance = { now: () => now };

	try {
		promptTps({ on: (event, handler) => handlers.set(event, handler) });
		const emit = (event, data = {}) => handlers.get(event)(data, ctx);
		const delta = (text) =>
			emit("message_update", {
				message: { role: "assistant" },
				assistantMessageEvent: {
					type: "text_delta",
					delta: text,
					partial: { usage: { output: 0 } },
				},
			});
		const end = (tokens) => emit("message_end", { message: { role: "assistant", usage: { output: tokens } } });

		emit("agent_start");
		now = 100;
		delta("abcdefghijkl");
		now = 1100;
		delta("x".repeat(40));
		assert.equal(statuses.at(-1), "Prompt decode ~13.0 tok/s");
		now = 1200;
		end(20);
		assert.equal(statuses.at(-1), "Prompt decode 18.2 tok/s");

		now = 6200; // Tool execution time is excluded.
		delta("abcdefgh");
		assert.equal(statuses.at(-1), "Prompt decode 18.2 tok/s");
		now = 7200;
		delta("x".repeat(32));
		assert.equal(statuses.at(-1), "Prompt decode ~14.3 tok/s");
		now = 7300;
		end(15);
		emit("agent_end");
		assert.equal(statuses.at(-1), "Prompt decode 15.9 tok/s");

		emit("agent_start");
		assert.equal(statuses.at(-1), undefined);
	} finally {
		globalThis.performance = originalPerformance;
	}
});
