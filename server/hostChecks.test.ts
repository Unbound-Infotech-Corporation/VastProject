import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  emptyStatus,
  parseStatusPayload,
  summarizeStatus,
} from "./hostChecks";

describe("parseStatusPayload", () => {
  it("fills missing keys with unverified placeholders", () => {
    const status = parseStatusPayload({});
    assert.equal(status.storage.verified, false);
    assert.match(status.gpu.message, /did not return/);
    assert.equal(status.vast.verified, false);
  });

  it("accepts verified components and ignores junk fields", () => {
    const status = parseStatusPayload({
      storage: { verified: true, message: "XFS + pquota" },
      gpu: { verified: false, message: "persistence off" },
      extra: { verified: true, message: "nope" },
      docker: { verified: "yes", message: 12 },
    });
    assert.equal(status.storage.verified, true);
    assert.equal(status.storage.message, "XFS + pquota");
    assert.equal(status.gpu.verified, false);
    assert.equal(status.docker.verified, false);
    assert.equal(status.docker.message, "No details.");
    assert.equal(status.network.verified, false);
  });

  it("summarizes status for logs", () => {
    const status = emptyStatus("n/a");
    status.os = { verified: true, message: "Ubuntu 24.04" };
    const text = summarizeStatus(status);
    assert.match(text, /os: ok/);
    assert.match(text, /storage: issue/);
  });
});
