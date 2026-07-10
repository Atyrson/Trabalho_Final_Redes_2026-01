import { LogIn, MonitorPlay } from "lucide-react";
import { Navigate } from "react-router-dom";
import { useAuth } from "../auth/AuthProvider";

export function LoginPage() {
  const auth = useAuth();

  if (auth.isLoading) {
    return (
      <main className="flex min-h-screen items-center justify-center bg-panel px-4">
        <p className="text-sm text-slate-600">Validando sessao...</p>
      </main>
    );
  }

  if (auth.isAuthenticated) {
    return <Navigate to={auth.claims?.role === "admin" ? "/admin" : "/canais"} replace />;
  }

  return (
    <main className="flex min-h-screen items-center justify-center bg-panel px-4">
      <section className="w-full max-w-md rounded border border-line bg-white p-6 shadow-soft">
        <div className="mb-6 flex items-center gap-3">
          <MonitorPlay className="h-8 w-8 text-signal" aria-hidden="true" />
          <div>
            <h1 className="text-xl font-semibold">Mini-IPTV</h1>
            <p className="text-sm text-slate-600">Acesso via Keycloak</p>
          </div>
        </div>
        <button className="button primary w-full" type="button" onClick={() => void auth.login()}>
          <LogIn className="h-4 w-4" aria-hidden="true" />
          Entrar com Keycloak
        </button>
      </section>
    </main>
  );
}
