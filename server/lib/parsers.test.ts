import assert from "node:assert/strict";
import { describe, it } from "node:test";
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

describe("parseNvidiaQueryCsv", () => {
  it("parses two identical GPUs", () => {
    const rows = parseNvidiaQueryCsv(
      "NVIDIA GeForce RTX 4090, 24564 MiB, Enabled, 560.35.03\nNVIDIA GeForce RTX 4090, 24564 MiB, Enabled, 560.35.03\n",
    );
    assert.equal(rows.length, 2);
    assert.equal(rows[0]?.name, "NVIDIA GeForce RTX 4090");
    assert.equal(rows[0]?.memoryMiB, 24564);
    assert.equal(rows[0]?.persistence, "enabled");
  });
});

describe("parseOsRelease", () => {
  it("reads Ubuntu 24.04", () => {
    const os = parseOsRelease('ID=ubuntu\nVERSION_ID="24.04"\nPRETTY_NAME="Ubuntu 24.04.1 LTS"\n');
    assert.equal(os.id, "ubuntu");
    assert.equal(os.versionId, "24.04");
    assert.equal(isSupportedUbuntu(os.versionId), true);
  });

  it("rejects 20.04 for current verification docs", () => {
    assert.equal(isSupportedUbuntu("20.04"), false);
  });
});

describe("parsePortRange", () => {
  it("accepts a high continuous range", () => {
    const parsed = parsePortRange("40000-40099");
    assert.deepEqual(parsed, { start: 40000, end: 40099, count: 100 });
  });

  it("rejects inverted or privileged ranges", () => {
    assert.equal(parsePortRange("80-90"), null);
    assert.equal(parsePortRange("50000-40000"), null);
    assert.equal(parsePortRange("abc"), null);
  });
});

describe("parseSshdPasswordAuth", () => {
  it("reads yes and no", () => {
    assert.equal(parseSshdPasswordAuth("passwordauthentication yes\n"), "yes");
    assert.equal(parseSshdPasswordAuth("PasswordAuthentication no\n"), "no");
  });
});

describe("dockerHasNvidiaRuntime", () => {
  it("detects nvidia runtime json", () => {
    assert.equal(
      dockerHasNvidiaRuntime('{"runtimes":{"nvidia":{"path":"nvidia-container-runtime"}}}'),
      true,
    );
    assert.equal(dockerHasNvidiaRuntime('{"runtimes":{}}'), false);
    assert.equal(dockerHasNvidiaRuntime("not-json"), false);
  });
});

describe("mountLooksLikeXfsPquota", () => {
  it("requires xfs + pquota", () => {
    assert.equal(mountLooksLikeXfsPquota("xfs", "rw,relatime,pquota,attr2"), true);
    assert.equal(mountLooksLikeXfsPquota("ext4", "rw,pquota"), false);
    assert.equal(mountLooksLikeXfsPquota("xfs", "rw,relatime"), false);
  });
});

describe("parseMemTotalKb", () => {
  it("reads MemTotal", () => {
    assert.equal(parseMemTotalKb("MemTotal:       32802580 kB\nMemFree: 100\n"), 32802580);
  });
});
