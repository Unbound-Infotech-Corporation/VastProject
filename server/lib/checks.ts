import { existsSync, readFileSync } from "node:fs";
import { commandExists, runAllowed } from "./commandRunner";
import {
  dockerHasNvidiaRuntime,
  isSupportedUbuntu,
  mountLooksLikeXfsPquota,
  parseMemTotalKb,
  parseNvidiaQueryCsv,
  parseOsRelease,
  parsePortRange,
  parseSshdPasswordAuth,
} from "./parsers";

export type CheckSeverity = "ok" | "warn" | "fail" | "unknown";

export type ComponentCheck = {
  verified: boolean;
  message: string;
  severity: CheckSeverity;
  details: string[];
};

export type SystemStatus = {
  os: ComponentCheck;
  storage: ComponentCheck;
  gpu: ComponentCheck;
  docker: ComponentCheck;
  network: ComponentCheck;
  host: ComponentCheck;
  ssh: ComponentCheck;
  readiness: {
    ready: boolean;
    blockers: string[];
    warnings: string[];
  };
};

function fail(message: string, details: string[] = []): ComponentCheck {
  return { verified: false, message, severity: "fail", details };
}

function warn(message: string, details: string[] = []): ComponentCheck {
  return { verified: false, message, severity: "warn", details };
}

function ok(message: string, details: string[] = []): ComponentCheck {
  return { verified: true, message, severity: "ok", details };
}

function unknown(message: string, details: string[] = []): ComponentCheck {
  return { verified: false, message, severity: "unknown", details };
}

async function checkOs(): Promise<ComponentCheck> {
  if (!existsSync("/etc/os-release")) {
    return unknown("Not a Linux host with /etc/os-release (dashboard is running off-box).");
  }
  const release = parseOsRelease(readFileSync("/etc/os-release", "utf8"));
  const kernel = (await runAllowed("uname", ["-r"])).stdout.trim();
  const details = [`os=${release.pretty}`, `kernel=${kernel}`];
  if (release.id !== "ubuntu") {
    return fail(`Unsupported OS ${release.pretty}. Vast host docs require Ubuntu Server.`, details);
  }
  if (!isSupportedUbuntu(release.versionId)) {
    return fail(
      `Ubuntu ${release.versionId} is not 22.04/24.04 LTS (Vast verification requirement).`,
      details,
    );
  }
  return ok(`Ubuntu ${release.versionId} Server-class host.`, details);
}

async function checkStorage(): Promise<ComponentCheck> {
  const root = await runAllowed("df", ["-Pk", "/"]);
  const rootLine = root.stdout.trim().split("\n")[1] ?? "";
  const rootAvailKb = Number.parseInt(rootLine.split(/\s+/)[3] ?? "0", 10);
  const rootAvailGb = Math.floor(rootAvailKb / 1024 / 1024);
  const details = [`root_free_gb=${rootAvailGb}`];

  const dockerMount = await runAllowed("findmnt", [
    "-n",
    "-o",
    "SOURCE,FSTYPE,OPTIONS,SIZE,AVAIL",
    "/var/lib/docker",
  ]);
  if (dockerMount.code !== 0) {
    return warn(
      "No dedicated /var/lib/docker mount. Vast verification requires a dedicated SSD (≥200 GB). Do not wipe a disk from this dashboard.",
      details,
    );
  }
  const [source, fstype, options, size, avail] = dockerMount.stdout.trim().split(/\s+/);
  details.push(`docker_source=${source}`, `fstype=${fstype}`, `options=${options}`, `size=${size}`, `avail=${avail}`);
  if (!mountLooksLikeXfsPquota(fstype ?? "", options ?? "")) {
    return warn(
      `Docker data is ${fstype ?? "unknown"} without pquota. Official host setup uses XFS with pquota for Docker quotas.`,
      details,
    );
  }
  if (rootAvailGb < 20) {
    return warn(`Docker mount looks correct, but / has only ${rootAvailGb} GiB free (need ≥20).`, details);
  }
  return ok("Dedicated XFS Docker volume with pquota.", details);
}

async function checkGpu(): Promise<ComponentCheck> {
  if (!(await commandExists("nvidia-smi"))) {
    return warn("nvidia-smi not found. Install a currently supported NVIDIA driver before listing.");
  }
  const query = await runAllowed("nvidia-smi", [
    "--query-gpu=name,memory.total,persistence_mode,driver_version",
    "--format=csv,noheader",
  ]);
  if (query.code !== 0) {
    return fail("nvidia-smi failed. Driver is missing or the NVIDIA kernel module did not load.", [
      query.stderr.trim(),
    ]);
  }
  const gpus = parseNvidiaQueryCsv(query.stdout);
  if (gpus.length === 0) {
    return fail("nvidia-smi returned no GPUs.");
  }
  const names = new Set(gpus.map((gpu) => gpu.name));
  const details = gpus.map(
    (gpu, index) =>
      `gpu${index}=${gpu.name} ${gpu.memoryMiB}MiB persist=${gpu.persistence} driver=${gpu.driver}`,
  );
  if (names.size > 1) {
    return fail("Mixed GPU models on one machine. Vast requires identical GPUs.", details);
  }
  const persistOff = gpus.filter((gpu) => gpu.persistence !== "enabled");
  if (persistOff.length > 0) {
    return warn(
      `${gpus.length}× ${gpus[0]?.name} detected; persistence mode is off. Safe fix: nvidia-smi -pm 1`,
      details,
    );
  }
  return ok(`${gpus.length}× ${gpus[0]?.name}, persistence enabled, driver ${gpus[0]?.driver}.`, details);
}

async function checkDocker(): Promise<ComponentCheck> {
  if (!(await commandExists("docker"))) {
    return warn("Docker is not installed. Vast's host installer or scripts/host/30-docker.sh can add it.");
  }
  const info = await runAllowed("docker", ["info", "--format", "{{json .Runtimes}}"]);
  const details: string[] = [];
  let runtimeOk = info.code === 0 && /nvidia/i.test(info.stdout);
  if (!runtimeOk && existsSync("/etc/docker/daemon.json")) {
    runtimeOk = dockerHasNvidiaRuntime(readFileSync("/etc/docker/daemon.json", "utf8"));
    details.push("checked /etc/docker/daemon.json");
  }
  if (!runtimeOk) {
    return warn("Docker is present but the NVIDIA runtime is not configured (nvidia-ctk runtime configure --runtime=docker).", details);
  }
  return ok("Docker reports an NVIDIA runtime.", details);
}

async function checkNetwork(): Promise<ComponentCheck> {
  const details: string[] = [];
  if (existsSync("/var/lib/vastai_kaalia/host_port_range")) {
    const raw = readFileSync("/var/lib/vastai_kaalia/host_port_range", "utf8");
    const parsed = parsePortRange(raw);
    if (!parsed) {
      return fail(`Invalid host_port_range '${raw.trim()}'.`, details);
    }
    details.push(`port_range=${parsed.start}-${parsed.end}`, `port_count=${parsed.count}`);
    if (parsed.count < 5) {
      return warn(
        `Only ${parsed.count} ports configured. Verification docs require 5 per GPU (100 recommended).`,
        details,
      );
    }
    return ok(`Host port range ${parsed.start}-${parsed.end} (${parsed.count} ports). Confirm WAN forward TCP+UDP.`, details);
  }
  return warn(
    "No /var/lib/vastai_kaalia/host_port_range yet. The Vast installer writes this after you choose a range.",
    details,
  );
}

async function checkHost(): Promise<ComponentCheck> {
  const details: string[] = [];
  const hasId = existsSync("/var/lib/vastai_kaalia/machine_id");
  const hasKey = existsSync("/var/lib/vastai_kaalia/api_key");
  details.push(`machine_id=${hasId ? "present" : "missing"}`, `api_key=${hasKey ? "present" : "missing"}`);
  const unit = await runAllowed("systemctl", ["is-active", "vastai"]);
  const active = unit.stdout.trim() === "active";
  details.push(`vastai.service=${unit.stdout.trim() || "unknown"}`);
  if (!hasId || !hasKey) {
    return warn(
      "Vast daemon identity files missing. Copy a fresh command from https://cloud.vast.ai/host/setup/ — do not invent flags.",
      details,
    );
  }
  if (!active) {
    return warn("Identity files exist but vastai.service is not active.", details);
  }
  return ok("Vast host daemon identity present and vastai.service is active.", details);
}

async function checkSsh(): Promise<ComponentCheck> {
  if (!(await commandExists("sshd"))) {
    return unknown("sshd not found on this host.");
  }
  const probed = await runAllowed("sshd", ["-T"]);
  const setting = parseSshdPasswordAuth(probed.stdout);
  if (setting === "no") {
    return ok("SSH password authentication is disabled.");
  }
  if (setting === "yes") {
    return warn(
      "SSH password login is enabled. Verification fails until it is disabled. Confirm a key works first: https://docs.vast.ai/host/disable-ssh-password-login",
    );
  }
  return unknown("Could not read sshd PasswordAuthentication.");
}

export async function collectSystemStatus(): Promise<SystemStatus> {
  const [os, storage, gpu, docker, network, host, ssh] = await Promise.all([
    checkOs(),
    checkStorage(),
    checkGpu(),
    checkDocker(),
    checkNetwork(),
    checkHost(),
    checkSsh(),
  ]);

  const checks = { os, storage, gpu, docker, network, host, ssh };
  const blockers: string[] = [];
  const warnings: string[] = [];
  for (const [name, check] of Object.entries(checks)) {
    if (check.severity === "fail") {
      blockers.push(`${name}: ${check.message}`);
    } else if (check.severity === "warn" || check.severity === "unknown") {
      warnings.push(`${name}: ${check.message}`);
    }
  }

  return {
    ...checks,
    readiness: {
      ready: blockers.length === 0 && warnings.length === 0,
      blockers,
      warnings,
    },
  };
}

export function toLegacyStatus(status: SystemStatus) {
  return {
    storage: { verified: status.storage.verified, message: status.storage.message },
    gpu: { verified: status.gpu.verified, message: status.gpu.message },
    docker: { verified: status.docker.verified, message: status.docker.message },
    network: { verified: status.network.verified, message: status.network.message },
  };
}
