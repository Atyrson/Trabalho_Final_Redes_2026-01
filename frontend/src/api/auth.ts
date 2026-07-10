import { api } from "./client";
import type { AuthToken } from "./types";

export async function login(username: string, password: string): Promise<AuthToken> {
  const body = new URLSearchParams();
  body.set("username", username);
  body.set("password", password);

  const response = await api.post<AuthToken>("/oauth/token", body, {
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
  });
  return response.data;
}
