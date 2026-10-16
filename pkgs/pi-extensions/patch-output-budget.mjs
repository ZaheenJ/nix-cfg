import { readFileSync, writeFileSync, copyFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const PATCH_POINT = "restoreOutputBudget(parsed,session,log2,resolveConfiguredOutputLimit(opts.routes,route?.rewrittenUrl,parsed.model));";
const IMPORT = 'import { repairPiOutputBudget } from "./repair-output-budget.mjs";';
const REPAIR = "if(!countTokens&&!responsesCompact)repairPiOutputBudget(parsed,req.headers,protocol,isSideRequest(parsed,pluginRequestAgentHeader(req.headers)),session.id,log2);";

export function patchOutputBudget(source, version) {
	if (version !== "0.1.178") throw new Error(`Unsupported billion-context version: ${version}`);
	if (source.includes(IMPORT)) throw new Error("Billion Context output-budget patch is already applied");
	if (source.split(PATCH_POINT).length !== 2) {
		throw new Error("Expected exactly one Billion Context output-budget patch point");
	}
	const newline = source.indexOf("\n");
	if (!source.startsWith("#!") || newline < 0) throw new Error("Expected Billion Context CLI shebang");
	const patched = source.replace(PATCH_POINT, REPAIR + PATCH_POINT);
	return patched.slice(0, newline + 1) + IMPORT + "\n" + patched.slice(newline + 1);
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
	const packageDir = process.argv[2];
	if (!packageDir) throw new Error("Usage: patch-output-budget.mjs <billion-context package directory>");
	const { version } = JSON.parse(readFileSync(join(packageDir, "package.json"), "utf8"));
	const bundle = join(packageDir, "dist/index.js");
	const source = patchOutputBudget(readFileSync(bundle, "utf8"), version);
	copyFileSync(join(dirname(fileURLToPath(import.meta.url)), "repair-output-budget.mjs"), join(packageDir, "dist/repair-output-budget.mjs"));
	writeFileSync(bundle, source);
}
