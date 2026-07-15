import { useQuery } from "@tanstack/react-query";
import { listChannels } from "../api/channels";
import { ChannelGrid } from "../components/ChannelGrid";
import { ErrorNotice } from "../components/ErrorNotice";

export function ChannelsPage() {
  const channels = useQuery({
    queryKey: ["channels"],
    queryFn: listChannels,
    refetchInterval: 10_000,
  });

  return (
    <div className="space-y-5">
      <div>
        <h1 className="text-2xl font-semibold">Canais</h1>
        <p className="mt-1 text-sm text-slate-600">Escolha um canal e baixe a playlist da sessao autenticada.</p>
      </div>
      {channels.isError ? <ErrorNotice message="Nao foi possivel carregar os canais." /> : null}
      {channels.isLoading ? <p className="text-sm text-slate-600">Carregando canais...</p> : null}
      {channels.data ? <ChannelGrid channels={channels.data} /> : null}
    </div>
  );
}
