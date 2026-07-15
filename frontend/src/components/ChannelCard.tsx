import { Eye, Tv } from "lucide-react";
import { Link } from "react-router-dom";
import type { ChannelSummary } from "../api/types";
import { StatusBadge } from "./StatusBadge";

export function ChannelCard({ channel }: { channel: ChannelSummary }) {
  return (
    <article className="card flex min-h-48 flex-col justify-between">
      <div>
        <div className="flex items-start justify-between gap-3">
          <div className="flex items-center gap-3">
            <div className="channel-number">{channel.number}</div>
            <div>
              <h2 className="text-lg font-semibold">{channel.name}</h2>
              <p className="text-sm text-slate-600">{channel.description ?? "Sem descricao"}</p>
            </div>
          </div>
          <StatusBadge status={channel.status} />
        </div>
      </div>
      <div className="mt-6 flex items-center justify-between gap-3">
        <span className="inline-flex items-center gap-2 text-sm text-slate-600">
          <Eye className="h-4 w-4" aria-hidden="true" />
          {channel.viewer_count} espectadores
        </span>
        <Link className="button primary" to={`/canais/${channel.id}`}>
          <Tv className="h-4 w-4" aria-hidden="true" />
          Assistir
        </Link>
      </div>
    </article>
  );
}
