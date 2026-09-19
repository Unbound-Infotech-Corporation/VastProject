export type GpuRow = {
  name: string;
  memoryMiB: number;
  persistence: string;
  driver: string;
};

export function parseNvidiaQueryCsv(csv: string): GpuRow[] {
  return csv
    .split("\n")
    .map((line) => line.trim())
    .filter((line) => line.length > 0)
    .map((line) => {
      const parts = line.split(",").map((part) => part.trim());
      const memoryRaw = parts[1] ?? "0";
      const memoryMiB = Number.parseInt(memoryRaw.replace(/[^\d]/g, ""), 10);
      return {
        name: parts[0] ?? "unknown",
        memoryMiB: Number.isFinite(memoryMiB) ? memoryMiB : 0,
        persistence: (parts[2] ?? "Unknown").toLowerCase(),
        driver: parts[3] ?? "unknown",
      };
    });
}

export function parseOsRelease(text: string): { id: string; versionId: string; pretty: string } {
  const values: Record<string, string> = {};
  for (const line of text.split("\n")) {
    const eq = line.indexOf("=");
    if (eq <= 0) continue;
    const key = line.slice(0, eq);
    let value = line.slice(eq + 1).trim();
    if (value.startsWith('"') && value.endsWith('"')) {
      value = value.slice(1, -1);
    }
    values[key] = value;
  }
  return {
    id: values.ID ?? "unknown",
    versionId: values.VERSION_ID ?? "unknown",
    pretty: values.PRETTY_NAME ?? "unknown",
  };
}

export function parseMemTotalKb(meminfo: string): number {
  const match = meminfo.match(/^MemTotal:\s+(\d+)\s+kB/m);
  if (!match?.[1]) {
    return 0;
  }
  return Number.parseInt(match[1], 10);
}

export function parsePortRange(raw: string): { start: number; end: number; count: number } | null {
  const cleaned = raw.trim();
  const match = cleaned.match(/^(\d+)-(\d+)$/);
  if (!match?.[1] || !match[2]) {
    return null;
  }
  const start = Number.parseInt(match[1], 10);
  const end = Number.parseInt(match[2], 10);
  if (start >= end || start < 1024 || end > 65535) {
    return null;
  }
  return { start, end, count: end - start + 1 };
}

export function parseSshdPasswordAuth(sshdT: string): "yes" | "no" | "unknown" {
  const match = sshdT.match(/^passwordauthentication\s+(yes|no)/im);
  if (!match?.[1]) {
    return "unknown";
  }
  return match[1].toLowerCase() === "yes" ? "yes" : "no";
}

export function dockerHasNvidiaRuntime(daemonJson: string): boolean {
  try {
    const parsed: unknown = JSON.parse(daemonJson);
    if (!parsed || typeof parsed !== "object") {
      return false;
    }
    const runtimes = (parsed as { runtimes?: Record<string, unknown> }).runtimes;
    return Boolean(runtimes && typeof runtimes === "object" && "nvidia" in runtimes);
  } catch {
    return false;
  }
}

export function mountLooksLikeXfsPquota(fstype: string, options: string): boolean {
  return fstype === "xfs" && /(^|,)pquota(,|$)/.test(options);
}

export function isSupportedUbuntu(versionId: string): boolean {
  return versionId === "22.04" || versionId === "24.04";
}
