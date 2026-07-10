import { useEffect, useState } from "react";
import { Navigate } from "react-router-dom";
import { useAuth } from "../auth/AuthProvider";
import { ErrorNotice } from "../components/ErrorNotice";

export function AuthCallbackPage() {
  const { completeLogin } = useAuth();
  const [done, setDone] = useState(false);
  const [error, setError] = useState(false);

  useEffect(() => {
    completeLogin()
      .then(() => setDone(true))
      .catch(() => setError(true));
  }, [completeLogin]);

  if (error) {
    return (
      <main className="flex min-h-screen items-center justify-center bg-panel px-4">
        <ErrorNotice message="Nao foi possivel concluir o login pelo Keycloak." />
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
