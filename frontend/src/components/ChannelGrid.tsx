import type { ChannelSummary } from "../api/types";
import { ChannelCard } from "./ChannelCard";
import { EmptyState } from "./EmptyState";

export function ChannelGrid({ channels }: { channels: ChannelSummary[] }) {
  if (channels.length === 0) {
    return <EmptyState title="Nenhum canal cadastrado" detail="Cadastre canais no painel administrativo." />;
  }

  return (
    <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
      {channels.map((channel) => (
        <ChannelCard key={channel.id} channel={channel} />
      ))}
    </div>
  );
}
