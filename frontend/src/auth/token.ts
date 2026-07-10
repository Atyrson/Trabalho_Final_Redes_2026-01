import { jwtDecode } from "jwt-decode";
import type { JwtClaims } from "../api/types";

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
    return jwtDecode<JwtClaims>(token);
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
