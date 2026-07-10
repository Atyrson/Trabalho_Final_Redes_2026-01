import { createContext, useCallback, useContext, useEffect, useMemo, useState } from "react";
import type { JwtClaims } from "../api/types";
import { clearToken, decodeToken, isExpired, readToken, writeToken } from "./token";
import { oidcUserManager } from "./oidc";

interface AuthState {
  token: string | null;
  claims: JwtClaims | null;
  isLoading: boolean;
  isAuthenticated: boolean;
  login: () => Promise<void>;
  completeLogin: () => Promise<void>;
  logout: () => Promise<void>;
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
  const [isLoading, setIsLoading] = useState(true);

  const logout = useCallback(async () => {
    clearToken();
    setState({ token: null, claims: null });
    await oidcUserManager.signoutRedirect();
  }, []);

  const login = useCallback(async () => {
    await oidcUserManager.signinRedirect();
  }, []);

  const applyToken = useCallback((token: string | undefined) => {
    const claims = token ? decodeToken(token) : null;
    if (!token || isExpired(claims)) {
      clearToken();
      setState({ token: null, claims: null });
      return;
    }
    writeToken(token);
    setState({ token, claims });
  }, []);

  const completeLogin = useCallback(async () => {
    const user = await oidcUserManager.signinRedirectCallback();
    applyToken(user.access_token);
  }, [applyToken]);

  useEffect(() => {
    oidcUserManager.getUser().then((user) => {
      applyToken(user?.access_token);
      setIsLoading(false);
    });
  }, [applyToken]);

  useEffect(() => {
    function expireSession() {
      clearToken();
      setState({ token: null, claims: null });
    }
    window.addEventListener("mini-iptv:auth-expired", expireSession);
    return () => window.removeEventListener("mini-iptv:auth-expired", expireSession);
  }, []);

  const value = useMemo(
    () => ({
      token: state.token,
      claims: state.claims,
      isLoading,
      isAuthenticated: Boolean(state.token && state.claims),
      login,
      completeLogin,
      logout,
    }),
    [completeLogin, isLoading, login, logout, state.claims, state.token],
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
