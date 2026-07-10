import { useEffect, useRef, useState } from "react";
import { Navigate } from "react-router-dom";
import { useAuth } from "../auth/AuthProvider";
import { ErrorNotice } from "../components/ErrorNotice";

export function AuthCallbackPage() {
  const { completeLogin } = useAuth();
  const completedRef = useRef(false);
  const [done, setDone] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (completedRef.current) {
      return;
    }
    completedRef.current = true;
    completeLogin()
      .then(() => setDone(true))
      .catch((unknownError) => {
        console.error("OIDC callback failed", unknownError);
        const message = unknownError instanceof Error ? unknownError.message : "Erro desconhecido";
        setError(message);
      });
  }, [completeLogin]);

  if (error) {
    return (
      <main className="flex min-h-screen items-center justify-center bg-panel px-4">
        <ErrorNotice message={`Nao foi possivel concluir o login pelo Keycloak: ${error}`} />
      </main>
    );
  }

  if (done) {
    return <Navigate to="/canais" replace />;
  }

  return (
    <main className="flex min-h-screen items-center justify-center bg-panel px-4">
      <p className="text-sm text-slate-600">Concluindo login...</p>
    </main>
  );
}
