import { Navigate, Outlet } from "react-router-dom";
import { useAuth } from "./AuthProvider";

export function AdminRoute() {
  const auth = useAuth();

  if (!auth.isAuthenticated) {
    return <Navigate to="/login" replace />;
  }

  if (auth.claims?.role !== "admin") {
    return <Navigate to="/canais" replace />;
  }

  return <Outlet />;
}
