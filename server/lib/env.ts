import { readFileSync, existsSync } from "node:fs";
import { resolve } from "node:path";

/** Load a local .env if present. Systemd EnvironmentFile still wins in production. */
export function loadDotEnv(filename = ".env"): void {
  const path = resolve(process.cwd(), filename);
  if (!existsSync(path)) {
    return;
  }
  const text = readFileSync(path, "utf8");
  for (const rawLine of text.split("\n")) {
    const line = rawLine.trim();
    if (!line || line.startsWith("#")) {
      continue;
    }
    const eq = line.indexOf("=");
    if (eq <= 0) {
      continue;
    }
    const key = line.slice(0, eq).trim();
    let value = line.slice(eq + 1).trim();
    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }
    if (process.env[key] === undefined) {
      process.env[key] = value;
    }
  }
}

export function isProduction(): boolean {
  return process.env.NODE_ENV === "production";
}
