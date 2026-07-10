import { api } from "./client";
import type { AdminDashboard, ChannelDetail, ChannelPayload, Video, VideoPayload } from "./types";

export async function getDashboard(): Promise<AdminDashboard> {
  const response = await api.get<AdminDashboard>("/admin/dashboard");
  return response.data;
}

export async function createChannel(payload: ChannelPayload): Promise<ChannelDetail> {
  const response = await api.post<ChannelDetail>("/admin/canais", payload);
  return response.data;
}

export async function updateChannel(channelId: number, payload: ChannelPayload): Promise<ChannelDetail> {
  const response = await api.put<ChannelDetail>(`/admin/canais/${channelId}`, payload);
  return response.data;
}

export async function deleteChannel(channelId: number): Promise<void> {
  await api.delete(`/admin/canais/${channelId}`);
}

export async function listVideos(): Promise<Video[]> {
  const response = await api.get<Video[]>("/admin/videos");
  return response.data;
}

export async function createVideo(payload: VideoPayload): Promise<Video> {
  const response = await api.post<Video>("/admin/videos", payload);
  return response.data;
}

export async function updateVideo(videoId: number, payload: VideoPayload): Promise<Video> {
  const response = await api.put<Video>(`/admin/videos/${videoId}`, payload);
  return response.data;
}

export async function deleteVideo(videoId: number): Promise<void> {
  await api.delete(`/admin/videos/${videoId}`);
}

export async function updateVideoMetadata(videoId: number): Promise<Video> {
  const response = await api.post<Video>(`/admin/videos/${videoId}/metadata`);
  return response.data;
}
