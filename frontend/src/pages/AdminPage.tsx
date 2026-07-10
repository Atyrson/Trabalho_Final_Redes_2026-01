import { useMemo, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { FileVideo, Pencil, RefreshCw, Trash2 } from "lucide-react";
import {
  createChannel,
  createVideo,
  deleteChannel,
  deleteVideo,
  getDashboard,
  listVideos,
  updateChannel,
  updateVideo,
  updateVideoMetadata,
} from "../api/admin";
import { getChannel, listChannels } from "../api/channels";
import type { ChannelDetail, ChannelPayload, ChannelSummary, Video, VideoPayload } from "../api/types";
import { EmptyState } from "../components/EmptyState";
import { ErrorNotice } from "../components/ErrorNotice";
import { ChannelForm } from "../features/admin/ChannelForm";
import { Dashboard } from "../features/admin/Dashboard";
import { StreamsTable } from "../features/admin/StreamsTable";
import { VideoForm } from "../features/admin/VideoForm";

export function AdminPage() {
  const queryClient = useQueryClient();
  const [editingChannelId, setEditingChannelId] = useState<number | null>(null);
  const [editingVideo, setEditingVideo] = useState<Video | null>(null);

  const dashboard = useQuery({ queryKey: ["admin", "dashboard"], queryFn: getDashboard, refetchInterval: 5_000 });
  const channels = useQuery({ queryKey: ["channels"], queryFn: listChannels });
  const videos = useQuery({ queryKey: ["admin", "videos"], queryFn: listVideos });
  const channelDetail = useQuery({
    queryKey: ["channel", editingChannelId],
    queryFn: () => getChannel(editingChannelId!),
    enabled: editingChannelId !== null,
  });

  const selectedChannel = useMemo<ChannelDetail | null>(() => channelDetail.data ?? null, [channelDetail.data]);

  const saveChannel = useMutation({
    mutationFn: (payload: ChannelPayload) =>
      selectedChannel ? updateChannel(selectedChannel.id, payload) : createChannel(payload),
    onSuccess: async () => {
      setEditingChannelId(null);
      await queryClient.invalidateQueries({ queryKey: ["channels"] });
    },
  });

  const removeChannel = useMutation({
    mutationFn: deleteChannel,
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["channels"] }),
  });

  const saveVideo = useMutation({
    mutationFn: (payload: VideoPayload) => (editingVideo ? updateVideo(editingVideo.id, payload) : createVideo(payload)),
    onSuccess: async () => {
      setEditingVideo(null);
      await queryClient.invalidateQueries({ queryKey: ["admin", "videos"] });
    },
  });

  const removeVideo = useMutation({
    mutationFn: deleteVideo,
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["admin", "videos"] }),
  });

  const metadata = useMutation({
    mutationFn: updateVideoMetadata,
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["admin", "videos"] }),
  });

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">Administracao</h1>
        <p className="mt-1 text-sm text-slate-600">Controle operacional dos canais, videos e fluxos multicast.</p>
      </div>

      {dashboard.isError || channels.isError || videos.isError ? (
        <ErrorNotice message="Nao foi possivel carregar parte dos dados administrativos." />
      ) : null}

      {dashboard.data ? <Dashboard data={dashboard.data} /> : null}

      <section className="space-y-3">
        <h2 className="text-lg font-semibold">Streams ativos</h2>
        {dashboard.data ? <StreamsTable streams={dashboard.data.active_streams} /> : null}
      </section>

      <section className="grid gap-5 xl:grid-cols-[1fr_24rem]">
        <div className="space-y-3">
          <h2 className="text-lg font-semibold">Canais</h2>
          {channels.data?.length ? (
            <div className="overflow-x-auto rounded border border-line bg-white">
              <table className="table">
                <thead>
                  <tr>
                    <th>Numero</th>
                    <th>Nome</th>
                    <th>Status</th>
                    <th>Espectadores</th>
                    <th>Acoes</th>
                  </tr>
                </thead>
                <tbody>
                  {channels.data.map((channel: ChannelSummary) => (
                    <tr key={channel.id}>
                      <td>{channel.number}</td>
                      <td>{channel.name}</td>
                      <td>{channel.status}</td>
                      <td>{channel.viewer_count}</td>
                      <td>
                        <div className="flex gap-2">
                          <button className="icon-button" type="button" onClick={() => setEditingChannelId(channel.id)} title="Editar canal">
                            <Pencil className="h-4 w-4" aria-hidden="true" />
                          </button>
                          <button
                            className="icon-button"
                            type="button"
                            onClick={() => window.confirm("Remover canal?") && removeChannel.mutate(channel.id)}
                            title="Remover canal"
                          >
                            <Trash2 className="h-4 w-4" aria-hidden="true" />
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          ) : (
            <EmptyState title="Nenhum canal cadastrado" />
          )}
        </div>
        <ChannelForm
          channel={selectedChannel}
          videos={videos.data ?? []}
          isSubmitting={saveChannel.isPending}
          onSubmit={(payload) => saveChannel.mutate(payload)}
        />
      </section>

      <section className="grid gap-5 xl:grid-cols-[1fr_24rem]">
        <div className="space-y-3">
          <h2 className="text-lg font-semibold">Videos</h2>
          {videos.data?.length ? (
            <div className="overflow-x-auto rounded border border-line bg-white">
              <table className="table">
                <thead>
                  <tr>
                    <th>Titulo</th>
                    <th>Resolucao</th>
                    <th>Caminho HD</th>
                    <th>Acoes</th>
                  </tr>
                </thead>
                <tbody>
                  {videos.data.map((video) => (
                    <tr key={video.id}>
                      <td>{video.title}</td>
                      <td>{video.resolution ?? "-"}</td>
                      <td className="max-w-md truncate font-mono">{video.hd_path}</td>
                      <td>
                        <div className="flex gap-2">
                          <button className="icon-button" type="button" onClick={() => setEditingVideo(video)} title="Editar video">
                            <Pencil className="h-4 w-4" aria-hidden="true" />
                          </button>
                          <button className="icon-button" type="button" onClick={() => metadata.mutate(video.id)} title="Ler metadados">
                            <RefreshCw className="h-4 w-4" aria-hidden="true" />
                          </button>
                          <button
                            className="icon-button"
                            type="button"
                            onClick={() => window.confirm("Remover video?") && removeVideo.mutate(video.id)}
                            title="Remover video"
                          >
                            <Trash2 className="h-4 w-4" aria-hidden="true" />
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          ) : (
            <EmptyState title="Nenhum video cadastrado" />
          )}
        </div>
        <div className="space-y-3">
          <VideoForm video={editingVideo} isSubmitting={saveVideo.isPending} onSubmit={(payload) => saveVideo.mutate(payload)} />
          <div className="notice">
            <FileVideo className="h-5 w-5" aria-hidden="true" />
            <span>Cadastre caminhos existentes no Host S; upload nao faz parte desta API.</span>
          </div>
        </div>
      </section>
    </div>
  );
}
