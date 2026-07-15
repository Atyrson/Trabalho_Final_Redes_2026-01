import { jwtDecode } from "jwt-decode";
import type { JwtClaims, UserRole } from "../api/types";

const STORAGE_KEY = "mini-iptv-token";

export function readToken(): string | null {
  return localStorage.getItem(STORAGE_KEY);
}

export function writeToken(token: string): void {
  localStorage.setItem(STORAGE_KEY, token);
}

export function clearToken(): void {
  localStorage.removeItem(STORAGE_KEY);
}

export function decodeToken(token: string): JwtClaims | null {
  try {
    const claims = jwtDecode<JwtClaims>(token);
    return { ...claims, role: extractRole(claims) };
  } catch {
    return null;
  }
}

export function isExpired(claims: JwtClaims | null): boolean {
  if (!claims) {
    return true;
  }
  return claims.exp * 1000 <= Date.now();
}

export function displayLogin(claims: JwtClaims | null): string {
  return claims?.preferred_username ?? claims?.login ?? claims?.sub ?? "";
}

function extractRole(claims: JwtClaims): UserRole | undefined {
  const roles = new Set<string>(claims.realm_access?.roles ?? []);
  Object.values(claims.resource_access ?? {}).forEach((access) => {
    access.roles?.forEach((role) => roles.add(role));
  });
  if (roles.has("admin")) {
    return "admin";
  }
  if (roles.has("client")) {
    return "client";
  }
  return claims.role;
}
