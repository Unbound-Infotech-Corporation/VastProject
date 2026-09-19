import { spawn } from "node:child_process";
import { resolve } from "node:path";

export const SAFE_COMPONENTS = ["Storage", "GPU", "Docker", "Network", "All"] as const;
export type SafeComponent = (typeof SAFE_COMPONENTS)[number];

const COMPONENT_TO_SCRIPT: Record<Exclude<SafeComponent, "All">, string> = {
  Storage: "storage",
  GPU: "gpu",
  Docker: "docker",
  Network: "network",
};

export function isSafeComponent(value: string): value is SafeComponent {
  return (SAFE_COMPONENTS as readonly string[]).includes(value);
}

function scriptPath(): string {
  return resolve(process.cwd(), "scripts/host/optimize-safe.sh");
}

export async function runSafeOptimize(
  component: SafeComponent,
  options: { dryRun: boolean },
): Promise<{ ok: boolean; output: string }> {
  const args = component === "All" ? ["all"] : [COMPONENT_TO_SCRIPT[component]];
  if (options.dryRun) {
    args.push("--dry-run");
  }

  return await new Promise((resolvePromise) => {
    const child = spawn("bash", [scriptPath(), ...args], {
      timeout: 60_000,
      env: { ...process.env, VAST_DRY_RUN: options.dryRun ? "1" : "0" },
    });
    let output = "";
    child.stdout.on("data", (chunk: Buffer) => {
      output += chunk.toString();
    });
    child.stderr.on("data", (chunk: Buffer) => {
      output += chunk.toString();
    });
    child.on("error", (error) => {
      resolvePromise({ ok: false, output: error.message });
    });
    child.on("close", (code) => {
      resolvePromise({ ok: code === 0, output: output.trim() || `exit ${code ?? "unknown"}` });
    });
  });
}
