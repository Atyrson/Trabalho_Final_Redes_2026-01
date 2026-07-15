import { Navigate, Outlet } from "react-router-dom";
import { useAuth } from "./AuthProvider";

export function AdminRoute() {
  const auth = useAuth();

  if (auth.isLoading) {
    return <p className="p-6 text-sm text-slate-600">Validando sessao...</p>;
  }

  if (!auth.isAuthenticated) {
    return <Navigate to="/login" replace />;
  }

  if (auth.claims?.role !== "admin") {
    return <Navigate to="/canais" replace />;
  }

  return <Outlet />;
}
