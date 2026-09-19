import { execFile } from "node:child_process";
import { promisify } from "node:util";

const execFileAsync = promisify(execFile);

export type CommandResult = {
  stdout: string;
  stderr: string;
  code: number;
};

const ALLOWED_BINARIES = new Set([
  "uname",
  "cat",
  "nvidia-smi",
  "findmnt",
  "df",
  "docker",
  "systemctl",
  "sshd",
  "lsblk",
  "nproc",
  "mokutil",
  "test",
  "bash",
]);

export async function runAllowed(
  file: string,
  args: readonly string[],
  timeoutMs = 8000,
): Promise<CommandResult> {
  const base = file.split("/").pop() ?? file;
  if (!ALLOWED_BINARIES.has(base)) {
    throw new Error(`Refusing to execute non-allowlisted binary: ${file}`);
  }
  try {
    const { stdout, stderr } = await execFileAsync(file, [...args], {
      timeout: timeoutMs,
      maxBuffer: 1024 * 1024,
    });
    return { stdout: stdout.toString(), stderr: stderr.toString(), code: 0 };
  } catch (error) {
    const err = error as { stdout?: string; stderr?: string; code?: number | string };
    return {
      stdout: err.stdout?.toString() ?? "",
      stderr: err.stderr?.toString() ?? (error instanceof Error ? error.message : String(error)),
      code: typeof err.code === "number" ? err.code : 1,
    };
  }
}

export async function commandExists(name: string): Promise<boolean> {
  const result = await runAllowed("bash", ["-lc", `command -v ${name}`], 3000);
  return result.code === 0 && result.stdout.trim().length > 0;
}
