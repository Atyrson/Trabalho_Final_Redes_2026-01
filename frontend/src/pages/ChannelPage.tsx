import { useQuery } from "@tanstack/react-query";
import { Link, useParams } from "react-router-dom";
import { getChannel } from "../api/channels";
import { ErrorNotice } from "../components/ErrorNotice";
import { StatusBadge } from "../components/StatusBadge";
import { SessionPanel } from "../features/player/SessionPanel";
import { useChannelSession } from "../features/player/useChannelSession";

export function ChannelPage() {
  const params = useParams();
  const channelId = Number(params.channelId);
  const channel = useQuery({
    queryKey: ["channel", channelId],
    queryFn: () => getChannel(channelId),
    enabled: Number.isFinite(channelId),
  });
  const session = useChannelSession(channelId);

  if (!Number.isFinite(channelId)) {
    return <ErrorNotice message="Canal invalido." />;
  }

  return (
    <div className="space-y-5">
      <Link className="text-sm font-medium text-signal" to="/canais">
        Voltar para canais
      </Link>
      {channel.isLoading ? <p className="text-sm text-slate-600">Carregando canal...</p> : null}
      {channel.isError ? <ErrorNotice message="Nao foi possivel carregar o canal." /> : null}
      {channel.data ? (
        <div className="grid gap-5 lg:grid-cols-[1fr_24rem]">
          <section className="card">
            <div className="flex items-start justify-between gap-4">
              <div>
                <p className="text-sm text-slate-500">Canal {channel.data.number}</p>
                <h1 className="text-2xl font-semibold">{channel.data.name}</h1>
                <p className="mt-2 text-sm text-slate-600">{channel.data.description ?? "Sem descricao."}</p>
              </div>
              <StatusBadge status={channel.data.status} />
            </div>
            <div className="mt-6 rounded border border-line bg-slate-50 p-4">
              <h2 className="text-base font-semibold">Video atual</h2>
              {channel.data.video ? (
                <dl className="mt-3 grid gap-3 text-sm sm:grid-cols-2">
                  <div>
                    <dt className="text-slate-500">Titulo</dt>
                    <dd className="font-medium">{channel.data.video.title}</dd>
                  </div>
                  <div>
                    <dt className="text-slate-500">Resolucao</dt>
                    <dd>{channel.data.video.resolution ?? "Nao informada"}</dd>
                  </div>
                  <div className="sm:col-span-2">
                    <dt className="text-slate-500">HD</dt>
                    <dd className="break-all font-mono text-xs">{channel.data.video.hd_path}</dd>
                  </div>
                  <div className="sm:col-span-2">
                    <dt className="text-slate-500">LD</dt>
                    <dd className="break-all font-mono text-xs">{channel.data.video.ld_path}</dd>
                  </div>
                </dl>
              ) : (
                <p className="mt-2 text-sm text-slate-600">Nenhum video associado.</p>
              )}
            </div>
          </section>
          <SessionPanel
            session={session.session}
            error={session.error}
            isEntering={session.isEntering}
            onEnter={session.enter}
            onLeave={session.leave}
          />
        </div>
      ) : null}
    </div>
  );
}
