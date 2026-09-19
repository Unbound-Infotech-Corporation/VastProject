import { execFile } from "child_process";
import { promisify } from "util";
import path from "path";
import { existsSync } from "fs";
import type { ComponentStatus, SystemStatusResponse } from "@shared/schema";

const execFileAsync = promisify(execFile);

export const CHECK_KEYS = [
  "storage",
  "gpu",
  "docker",
  "network",
  "os",
  "vast",
] as const;

export type CheckKey = (typeof CHECK_KEYS)[number];

const unknownCheck = (message: string): ComponentStatus => ({
  verified: false,
  message,
});

export function emptyStatus(message = "Status not collected yet."): SystemStatusResponse {
  return {
    storage: unknownCheck(message),
    gpu: unknownCheck(message),
    docker: unknownCheck(message),
    network: unknownCheck(message),
    os: unknownCheck(message),
    vast: unknownCheck(message),
  };
}

export function parseStatusPayload(raw: unknown): SystemStatusResponse {
  const src = raw && typeof raw === "object" ? (raw as Record<string, unknown>) : {};
  const status = emptyStatus("Check did not return a result.");
  for (const key of CHECK_KEYS) {
    const value = src[key];
    if (value && typeof value === "object") {
      const rec = value as Record<string, unknown>;
      status[key] = {
        verified: rec.verified === true,
        message: typeof rec.message === "string" && rec.message.trim()
          ? rec.message
          : "No details.",
      };
    }
  }
  return status;
}

export function scriptsRoot(cwd = process.cwd()): string {
  return path.resolve(cwd, "scripts");
}

export function collectStatusScript(cwd = process.cwd()): string {
  return path.join(scriptsRoot(cwd), "optimize", "collect-status.sh");
}

export function optimizeRunScript(cwd = process.cwd()): string {
  return path.join(scriptsRoot(cwd), "optimize", "run.sh");
}

async function runScript(
  script: string,
  args: string[],
  timeoutMs: number,
): Promise<{ stdout: string; stderr: string; code: number }> {
  try {
    const { stdout, stderr } = await execFileAsync("/bin/bash", [script, ...args], {
      timeout: timeoutMs,
      maxBuffer: 2 * 1024 * 1024,
      env: {
        ...process.env,
        // Status/optimize from the service must never wait on a sudo password.
        SUDO_ASKPASS: "",
      },
    });
    return { stdout, stderr, code: 0 };
  } catch (err) {
    const error = err as {
      stdout?: string;
      stderr?: string;
      code?: number;
      message?: string;
    };
    return {
      stdout: error.stdout ?? "",
      stderr: error.stderr ?? error.message ?? String(err),
      code: typeof error.code === "number" ? error.code : 1,
    };
  }
}

export async function collectHostStatus(
  cwd = process.cwd(),
): Promise<SystemStatusResponse> {
  const script = collectStatusScript(cwd);
  if (!existsSync(script)) {
    return emptyStatus(`Missing ${script}. Deploy the scripts/ directory with the app.`);
  }

  const result = await runScript(script, [], 20_000);
  const text = result.stdout.trim();
  if (!text) {
    return emptyStatus(
      result.stderr.trim() || "collect-status.sh produced no output (need bash + python3).",
    );
  }

  try {
    return parseStatusPayload(JSON.parse(text));
  } catch {
    return emptyStatus(`Could not parse status JSON: ${text.slice(0, 200)}`);
  }
}

export async function runOptimization(
  component: "Storage" | "GPU" | "Docker" | "Network" | "All",
  apply: boolean,
  cwd = process.cwd(),
): Promise<{ stdout: string; stderr: string; code: number; status: SystemStatusResponse }> {
  const script = optimizeRunScript(cwd);
  if (!existsSync(script)) {
    throw new Error(`Missing ${script}`);
  }

  const args: string[] = [component];
  if (apply) {
    args.push("--apply");
  }
  args.push("--json");

  const result = await runScript(script, args, 120_000);
  let status = emptyStatus("Optimizer finished but status JSON was not parsed.");
  const match = result.stdout.trim().split("\n").filter((line) => line.startsWith("{")).pop();
  if (match) {
    try {
      status = parseStatusPayload(JSON.parse(match));
    } catch {
      // keep emptyStatus
    }
  }
  return { ...result, status };
}

export function summarizeStatus(status: SystemStatusResponse): string {
  return CHECK_KEYS.map((key) => {
    const item = status[key];
    return `${key}: ${item.verified ? "ok" : "issue"} — ${item.message}`;
  }).join("\n");
}
