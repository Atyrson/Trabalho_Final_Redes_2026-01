import { describe, expect, it, vi } from "vitest";
import { decodeToken, isExpired } from "./token";

function unsignedJwt(payload: object) {
  const encodedPayload = btoa(JSON.stringify(payload)).replace(/=/g, "");
  return `header.${encodedPayload}.signature`;
}

describe("token helpers", () => {
  it("decodes jwt claims", () => {
    const token = unsignedJwt({ sub: "cliente1", role: "client", exp: 4_102_444_800 });

    expect(decodeToken(token)).toMatchObject({ sub: "cliente1", role: "client" });
  });

  it("detects expired claims", () => {
    vi.setSystemTime(new Date("2026-01-01T00:00:00Z"));

    expect(isExpired({ sub: "cliente1", role: "client", exp: 1 })).toBe(true);
    expect(isExpired({ sub: "cliente1", role: "client", exp: 4_102_444_800 })).toBe(false);

    vi.useRealTimers();
  });
});
