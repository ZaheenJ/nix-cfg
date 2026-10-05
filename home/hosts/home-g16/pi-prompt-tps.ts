import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const STATUS_KEY = "prompt-tps";
const UPDATE_INTERVAL_MS = 250;
const CHARS_PER_TOKEN = 4;

export default function (pi: ExtensionAPI) {
	let active = false;
	let completedTokens = 0;
	let completedDecodeMs = 0;
	let completedEstimate = false;
	let firstDeltaAt: number | undefined;
	let streamedChars = 0;
	let reportedTokens = 0;
	let lastUpdateAt = 0;
	let lastStatus: string | undefined;

	function setStatus(ctx: ExtensionContext, text: string | undefined) {
		if (text === lastStatus) return;
		lastStatus = text;
		ctx.ui.setStatus(STATUS_KEY, text);
	}

	function render(ctx: ExtensionContext, now: number, force = false) {
		if (!force && now - lastUpdateAt < UPDATE_INTERVAL_MS) return;
		lastUpdateAt = now;

		const live = firstDeltaAt !== undefined;
		const liveDecodeMs = firstDeltaAt === undefined ? 0 : Math.max(0, now - firstDeltaAt);
		const liveTokens = live ? reportedTokens || Math.ceil(streamedChars / CHARS_PER_TOKEN) : 0;
		const tokens = completedTokens + liveTokens;
		const decodeMs = completedDecodeMs + liveDecodeMs;
		if (tokens <= 0 || decodeMs <= 0 || (live && liveDecodeMs < 500)) return;

		const approximate = completedEstimate || (live && reportedTokens === 0);
		const rate = (tokens * 1000) / decodeMs;
		setStatus(ctx, `Prompt decode ${approximate ? "~" : ""}${rate.toFixed(1)} tok/s`);
	}

	function reset(ctx: ExtensionContext) {
		active = true;
		completedTokens = 0;
		completedDecodeMs = 0;
		completedEstimate = false;
		firstDeltaAt = undefined;
		streamedChars = 0;
		reportedTokens = 0;
		lastUpdateAt = 0;
		lastStatus = undefined;
		ctx.ui.setStatus(STATUS_KEY, undefined);
	}

	pi.on("session_start", (_event, ctx) => {
		reset(ctx);
		active = false;
	});

	pi.on("before_agent_start", (_event, ctx) => reset(ctx));
	pi.on("agent_start", () => {
		active = true;
	});

	pi.on("message_update", (event, ctx) => {
		if (!active || event.message.role !== "assistant") return;
		const update = event.assistantMessageEvent;
		if (update.type !== "text_delta" && update.type !== "thinking_delta" && update.type !== "toolcall_delta") return;
		if (!update.delta) return;

		const now = performance.now();
		firstDeltaAt ??= now;
		streamedChars += update.delta.length;
		const usage = update.partial.usage.output;
		if (Number.isFinite(usage) && usage > 0) reportedTokens = usage;
		render(ctx, now);
	});

	pi.on("message_end", (event, ctx) => {
		if (!active || event.message.role !== "assistant" || firstDeltaAt === undefined) return;
		const now = performance.now();
		const usage = event.message.usage.output;
		const exact = Number.isFinite(usage) && usage > 0;
		completedTokens += exact ? usage : Math.ceil(streamedChars / CHARS_PER_TOKEN);
		completedDecodeMs += Math.max(0, now - firstDeltaAt);
		completedEstimate ||= !exact;
		firstDeltaAt = undefined;
		streamedChars = 0;
		reportedTokens = 0;
		render(ctx, now, true);
	});

	pi.on("agent_end", (_event, ctx) => {
		active = false;
		render(ctx, performance.now(), true);
	});
}
