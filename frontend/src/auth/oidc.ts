import { UserManager, WebStorageStateStore } from "oidc-client-ts";

const authority = import.meta.env.VITE_OIDC_AUTHORITY ?? "http://127.0.0.1:8080/realms/mini-iptv";
const clientId = import.meta.env.VITE_OIDC_CLIENT_ID ?? "mini-iptv-frontend";
const redirectUri = import.meta.env.VITE_OIDC_REDIRECT_URI ?? `${window.location.origin}/auth/callback`;
const postLogoutRedirectUri = import.meta.env.VITE_OIDC_POST_LOGOUT_REDIRECT_URI ?? `${window.location.origin}/login`;

export const oidcUserManager = new UserManager({
  authority,
  client_id: clientId,
  redirect_uri: redirectUri,
  post_logout_redirect_uri: postLogoutRedirectUri,
  response_type: "code",
  scope: "openid profile",
  userStore: new WebStorageStateStore({ store: window.localStorage }),
  automaticSilentRenew: false,
});
