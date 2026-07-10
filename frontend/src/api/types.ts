export type UserRole = "admin" | "client";
export type ClientProfile = "LAN" | "WAN115K";

export interface AuthToken {
  access_token: string;
  token_type: "bearer";
}

export interface JwtClaims {
  sub: string;
  preferred_username?: string;
  login?: string;
  role?: UserRole;
  azp?: string;
  aud?: string | string[];
  realm_access?: { roles?: string[] };
  resource_access?: Record<string, { roles?: string[] }>;
  exp: number;
}

export interface Video {
  id: number;
  title: string;
  hd_path: string;
  ld_path: string;
  description: string | null;
  duration_seconds: number | null;
  bitrate: number | null;
  resolution: string | null;
  video_codec: string | null;
  audio_codec: string | null;
}

export interface VideoPayload {
  title: string;
  hd_path: string;
  ld_path: string;
  description?: string | null;
  duration_seconds?: number | null;
  bitrate?: number | null;
  resolution?: string | null;
  video_codec?: string | null;
  audio_codec?: string | null;
}

export interface ChannelSummary {
  id: number;
  number: number;
  name: string;
  description: string | null;
  status: string;
  viewer_count: number;
}

export interface ChannelDetail extends Omit<ChannelSummary, "viewer_count"> {
  current_video_id: number | null;
  video: Video | null;
}

export interface ChannelPayload {
  number: number;
  name: string;
  description?: string | null;
  status: string;
  current_video_id?: number | null;
}

export interface SessionDecision {
  session_id: number;
  profile: ClientProfile;
  multicast_address: string;
  port: number;
  playlist_url: string;
}

export interface ActiveStream {
  id: number;
  channel_id: number;
  channel_number: number;
  channel_name: string;
  profile: ClientProfile;
  multicast_address: string;
  port: number;
  pid: number;
  started_at: string;
}

export interface MulticastFlow {
  profile: ClientProfile;
  channel: number;
  multicast_address: string;
  port: number;
}

export interface AdminDashboard {
  active_users: number;
  active_channels: number[];
  vlc_pids: number[];
  wan_active_channel: number | null;
  active_streams: ActiveStream[];
  active_multicast_flows: MulticastFlow[];
}

export interface ApiErrorDetail {
  detail?: string | { active_channel?: number };
}
