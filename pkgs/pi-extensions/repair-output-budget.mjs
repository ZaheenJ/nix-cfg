const MODEL = "islamsidratul/Qwen3.8-27B-ByteShape-IQ4_XS-ASCII-GGUF:IQ4_XS";

function positiveInteger(value) {
	if (typeof value !== "string" || !/^[1-9]\d*$/.test(value)) return undefined;
	const parsed = Number(value);
	return Number.isSafeInteger(parsed) ? parsed : undefined;
}

export function repairPiOutputBudget(payload, headers, protocol, sideRequest, sessionId, log) {
	if (
		protocol !== "openai" ||
		sideRequest ||
		headers["x-bili-plugin"] !== "pi" ||
		headers["x-bili-plugin-bypass"] !== undefined ||
		headers["x-bili-plugin-model"] !== MODEL ||
		!payload ||
		payload.model !== MODEL ||
		payload.stream !== true ||
		!Array.isArray(payload.tools) ||
		payload.tools.length === 0
	) return;

	const contextWindow = positiveInteger(headers["x-bili-plugin-context-window"]);
	const maxOutput = positiveInteger(headers["x-bili-plugin-max-output"]);
	if (!contextWindow || !maxOutput) return;
	const ceiling = Math.min(contextWindow, maxOutput);
	const budget = payload.max_tokens;
	if (
		!Number.isSafeInteger(budget) ||
		budget <= 0 ||
		budget >= ceiling ||
		payload.max_completion_tokens !== undefined ||
		payload.max_output_tokens !== undefined
	) return;

	payload.max_tokens = ceiling;
	log("info", `[${sessionId}] pi output budget repaired ${budget} -> ${ceiling}; compressed-input clamp follows`);
}
