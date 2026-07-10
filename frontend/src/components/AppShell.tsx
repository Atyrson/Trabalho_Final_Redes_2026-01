import { LogOut, MonitorPlay, ShieldCheck } from "lucide-react";
import { NavLink, Outlet, useNavigate } from "react-router-dom";
import { useAuth } from "../auth/AuthProvider";
import { displayLogin } from "../auth/token";

export function AppShell() {
  const auth = useAuth();
  const navigate = useNavigate();

  function handleLogout() {
    void auth.logout();
    navigate("/login", { replace: true });
  }

  return (
    <div className="min-h-screen bg-panel text-ink">
      <header className="border-b border-line bg-white">
        <div className="mx-auto flex max-w-7xl items-center justify-between px-4 py-3">
          <div className="flex items-center gap-3">
            <MonitorPlay className="h-6 w-6 text-signal" aria-hidden="true" />
            <div>
              <p className="text-sm font-semibold leading-none">Mini-IPTV</p>
              <p className="text-xs text-slate-500">{displayLogin(auth.claims)}</p>
            </div>
          </div>
          <nav className="flex items-center gap-2">
            <NavLink className="nav-link" to="/canais">
              Canais
            </NavLink>
            {auth.claims?.role === "admin" ? (
              <NavLink className="nav-link" to="/admin">
                <ShieldCheck className="h-4 w-4" aria-hidden="true" />
                Admin
              </NavLink>
            ) : null}
            <button className="icon-button" type="button" onClick={handleLogout} title="Sair">
              <LogOut className="h-5 w-5" aria-hidden="true" />
            </button>
          </nav>
        </div>
      </header>
      <main className="mx-auto max-w-7xl px-4 py-6">
        <Outlet />
      </main>
    </div>
  );
}
