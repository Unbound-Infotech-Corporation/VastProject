import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { isSafeComponent, SAFE_COMPONENTS } from "./optimizer";

describe("optimizer allowlist", () => {
  it("accepts only documented components", () => {
    for (const component of SAFE_COMPONENTS) {
      assert.equal(isSafeComponent(component), true);
    }
    assert.equal(isSafeComponent("Storage; rm -rf /"), false);
    assert.equal(isSafeComponent("mkfs"), false);
    assert.equal(isSafeComponent(""), false);
  });
});
