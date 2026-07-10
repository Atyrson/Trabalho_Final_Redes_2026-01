import { createContext, useCallback, useContext, useEffect, useMemo, useState } from "react";
import type { JwtClaims } from "../api/types";
import { clearToken, decodeToken, isExpired, readToken, writeToken } from "./token";

interface AuthState {
  token: string | null;
  claims: JwtClaims | null;
  isAuthenticated: boolean;
  loginWithToken: (token: string) => void;
  logout: () => void;
}

const AuthContext = createContext<AuthState | null>(null);

function loadInitialState(): Pick<AuthState, "token" | "claims"> {
  const token = readToken();
  const claims = token ? decodeToken(token) : null;
  if (!token || isExpired(claims)) {
    clearToken();
    return { token: null, claims: null };
  }
  return { token, claims };
}

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [state, setState] = useState(loadInitialState);

  const logout = useCallback(() => {
    clearToken();
    setState({ token: null, claims: null });
  }, []);

  const loginWithToken = useCallback((token: string) => {
    const claims = decodeToken(token);
    if (isExpired(claims)) {
      clearToken();
      setState({ token: null, claims: null });
      return;
    }
    writeToken(token);
    setState({ token, claims });
  }, []);

  useEffect(() => {
    window.addEventListener("mini-iptv:auth-expired", logout);
    return () => window.removeEventListener("mini-iptv:auth-expired", logout);
  }, [logout]);

  const value = useMemo(
    () => ({
      token: state.token,
      claims: state.claims,
      isAuthenticated: Boolean(state.token && state.claims),
      loginWithToken,
      logout,
    }),
    [loginWithToken, logout, state.claims, state.token],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthState {
  const value = useContext(AuthContext);
  if (!value) {
    throw new Error("useAuth must be used inside AuthProvider");
  }
  return value;
}
