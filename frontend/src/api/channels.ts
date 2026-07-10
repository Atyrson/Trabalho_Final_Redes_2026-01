import { api } from "./client";
import type { ChannelDetail, ChannelSummary, SessionDecision } from "./types";

export async function listChannels(): Promise<ChannelSummary[]> {
  const response = await api.get<ChannelSummary[]>("/canais");
  return response.data;
}

export async function getChannel(channelId: number): Promise<ChannelDetail> {
  const response = await api.get<ChannelDetail>(`/canais/${channelId}`);
  return response.data;
}

export async function enterChannel(channelId: number): Promise<SessionDecision> {
  const response = await api.post<SessionDecision>(`/canais/${channelId}/entrar`);
  return response.data;
}
