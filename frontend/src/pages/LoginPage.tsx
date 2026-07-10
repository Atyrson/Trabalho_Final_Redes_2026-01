import { useState } from "react";
import { zodResolver } from "@hookform/resolvers/zod";
import { LogIn, MonitorPlay } from "lucide-react";
import { useForm } from "react-hook-form";
import { Navigate, useLocation, useNavigate } from "react-router-dom";
import { z } from "zod";
import { login } from "../api/auth";
import { useAuth } from "../auth/AuthProvider";
import { ErrorNotice } from "../components/ErrorNotice";

const schema = z.object({
  username: z.string().min(1, "Informe o usuario"),
  password: z.string().min(1, "Informe a senha"),
});

type LoginForm = z.infer<typeof schema>;

export function LoginPage() {
  const auth = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const [error, setError] = useState<string | null>(null);
  const form = useForm<LoginForm>({ resolver: zodResolver(schema), defaultValues: { username: "", password: "" } });

  if (auth.isAuthenticated) {
    return <Navigate to={auth.claims?.role === "admin" ? "/admin" : "/canais"} replace />;
  }

  async function onSubmit(values: LoginForm) {
    setError(null);
    try {
      const token = await login(values.username, values.password);
      auth.loginWithToken(token.access_token);
      const from = (location.state as { from?: { pathname: string } } | null)?.from?.pathname;
      navigate(from ?? "/canais", { replace: true });
    } catch {
      setError("Usuario ou senha invalidos.");
    }
  }

  return (
    <main className="flex min-h-screen items-center justify-center bg-panel px-4">
      <section className="w-full max-w-md rounded border border-line bg-white p-6 shadow-soft">
        <div className="mb-6 flex items-center gap-3">
          <MonitorPlay className="h-8 w-8 text-signal" aria-hidden="true" />
          <div>
            <h1 className="text-xl font-semibold">Mini-IPTV</h1>
            <p className="text-sm text-slate-600">Acesso autenticado</p>
          </div>
        </div>
        {error ? <ErrorNotice message={error} /> : null}
        <form className="mt-5 space-y-4" onSubmit={form.handleSubmit(onSubmit)}>
          <div>
            <label className="label" htmlFor="username">
              Usuario
            </label>
            <input className="input" id="username" autoComplete="username" {...form.register("username")} />
            <p className="mt-1 text-xs text-alert">{form.formState.errors.username?.message}</p>
          </div>
          <div>
            <label className="label" htmlFor="password">
              Senha
            </label>
            <input className="input" id="password" type="password" autoComplete="current-password" {...form.register("password")} />
            <p className="mt-1 text-xs text-alert">{form.formState.errors.password?.message}</p>
          </div>
          <button className="button primary w-full" type="submit" disabled={form.formState.isSubmitting}>
            <LogIn className="h-4 w-4" aria-hidden="true" />
            {form.formState.isSubmitting ? "Entrando..." : "Entrar"}
          </button>
        </form>
      </section>
    </main>
  );
}
