import { spawn } from "node:child_process";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
	pi.on("before_agent_start", async (event, ctx) => {
		if (event.messageType !== "user" || !event.prompt.trim()) return;
		if (Buffer.byteLength(event.prompt, "utf8") > 256 * 1024) return;

		const home = process.env.HOME;
		if (!home) return;
		const child = spawn("@AGENT_MEMORY_BIN@", ["codex-hook"], {
			cwd: ctx.cwd,
			env: {
				...process.env,
				AGENT_MEMORY_WORKSPACE: home,
				AGENT_MEMORY_STORE_REPOSITORY: `${home}/.local/share/agent-memory/home-chat`,
			},
			stdio: ["pipe", "pipe", "ignore"],
		});
		const output = await new Promise<string>((resolve) => {
			let stdout = "";
			let settled = false;
			const finish = (value: string) => {
				if (settled) return;
				settled = true;
				clearTimeout(timeout);
				resolve(value);
			};
			const timeout = setTimeout(() => {
				child.kill();
				finish("");
			}, 5000);
			child.stdout.setEncoding("utf8");
			child.stdout.on("data", (chunk: string) => {
				stdout += chunk;
				if (stdout.length > 16384) {
					child.kill();
					finish("");
				}
			});
			child.on("error", () => finish(""));
			child.stdin.on("error", () => finish(""));
			child.on("close", (code) => finish(code === 0 ? stdout : ""));
			child.stdin.end(
				JSON.stringify({
					hook_event_name: "UserPromptSubmit",
					cwd: ctx.cwd,
					prompt: event.prompt,
				}),
			);
		});
		if (!output) return;
		try {
			const context = JSON.parse(output).hookSpecificOutput?.additionalContext;
			if (typeof context !== "string" || !context) return;
			return {
				message: {
					customType: "agent-memory",
					content: context,
					display: false,
				},
			};
		} catch {
			return;
		}
	});
}
