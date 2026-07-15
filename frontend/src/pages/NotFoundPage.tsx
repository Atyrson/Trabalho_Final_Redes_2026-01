import { Link } from "react-router-dom";

export function NotFoundPage() {
  return (
    <main className="flex min-h-screen items-center justify-center bg-panel px-4">
      <section className="rounded border border-line bg-white p-6 text-center shadow-soft">
        <h1 className="text-xl font-semibold">Pagina nao encontrada</h1>
        <Link className="button primary mt-5" to="/canais">
          Voltar
        </Link>
      </section>
    </main>
  );
}
