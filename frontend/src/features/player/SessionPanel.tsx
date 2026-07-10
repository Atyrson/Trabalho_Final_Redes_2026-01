import { Download, LogOut, RadioTower } from "lucide-react";
import { Link } from "react-router-dom";
import type { SessionDecision } from "../../api/types";
import { ErrorNotice } from "../../components/ErrorNotice";

interface SessionPanelProps {
  session: SessionDecision | null;
  error: { message: string; activeChannel?: number } | null;
  isEntering: boolean;
  onEnter: () => void;
  onLeave: () => void;
}

export function SessionPanel({ session, error, isEntering, onEnter, onLeave }: SessionPanelProps) {
  return (
    <section className="card">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h2 className="text-lg font-semibold">Sessao multicast</h2>
          <p className="mt-1 text-sm text-slate-600">A playlist baixada deve ser aberta no VLC Client.</p>
        </div>
        <RadioTower className="h-6 w-6 text-signal" aria-hidden="true" />
      </div>

      {error ? (
        <div className="mt-4 space-y-3">
          <ErrorNotice message={error.message} />
          {error.activeChannel ? (
            <Link className="button" to="/canais">
              Canal ativo: {error.activeChannel}
            </Link>
          ) : null}
        </div>
      ) : null}

      {session ? (
        <div className="mt-5 space-y-4">
          <dl className="grid gap-3 text-sm sm:grid-cols-2">
            <div>
              <dt className="text-slate-500">Perfil</dt>
              <dd className="font-semibold">{session.profile}</dd>
            </div>
            <div>
              <dt className="text-slate-500">Multicast</dt>
              <dd className="font-mono text-sm">
                {session.multicast_address}:{session.port}
              </dd>
            </div>
          </dl>
          <button className="button danger" type="button" onClick={onLeave}>
            <LogOut className="h-4 w-4" aria-hidden="true" />
            Sair do canal
          </button>
        </div>
      ) : (
        <button className="button primary mt-5 w-full sm:w-auto" type="button" onClick={onEnter} disabled={isEntering}>
          <Download className="h-4 w-4" aria-hidden="true" />
          {isEntering ? "Iniciando..." : "Baixar playlist"}
        </button>
      )}
    </section>
  );
}
