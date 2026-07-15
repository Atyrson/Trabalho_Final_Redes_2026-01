import { api } from "./client";

export async function heartbeat(sessionId: number): Promise<void> {
  await api.post(`/sessoes/${sessionId}/heartbeat`);
}

export async function leaveSession(sessionId: number): Promise<void> {
  await api.post(`/sessoes/${sessionId}/sair`);
}

export async function downloadPlaylist(playlistUrl: string): Promise<Blob> {
  const response = await api.get(playlistUrl, { responseType: "blob" });
  return response.data;
}
