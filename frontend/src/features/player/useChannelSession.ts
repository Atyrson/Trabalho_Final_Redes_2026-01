import { useCallback, useEffect, useRef, useState } from "react";
import axios from "axios";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { enterChannel } from "../../api/channels";
import { downloadPlaylist, heartbeat, leaveSession } from "../../api/sessions";
import type { SessionDecision } from "../../api/types";
import { readToken } from "../../auth/token";

interface SessionError {
  message: string;
  activeChannel?: number;
}

export function useChannelSession(channelId: number) {
  const queryClient = useQueryClient();
  const [session, setSession] = useState<SessionDecision | null>(null);
  const [error, setError] = useState<SessionError | null>(null);
  const heartbeatTimer = useRef<number | null>(null);

  const stopHeartbeat = useCallback(() => {
    if (heartbeatTimer.current) {
      window.clearInterval(heartbeatTimer.current);
      heartbeatTimer.current = null;
    }
  }, []);

  const leaveCurrentSession = useCallback(async () => {
    stopHeartbeat();
    if (session) {
      await leaveSession(session.session_id).catch(() => undefined);
      setSession(null);
      await queryClient.invalidateQueries({ queryKey: ["channels"] });
    }
  }, [queryClient, session, stopHeartbeat]);

  const enterMutation = useMutation({
    mutationFn: async () => {
      setError(null);
      if (session) {
        await leaveCurrentSession();
      }
      const decision = await enterChannel(channelId);
      const blob = await downloadPlaylist(decision.playlist_url);
      const href = URL.createObjectURL(blob);
      const anchor = document.createElement("a");
      anchor.href = href;
      anchor.download = `mini-iptv-canal-${channelId}.m3u`;
      anchor.click();
      URL.revokeObjectURL(href);
      return decision;
    },
    onSuccess: async (decision) => {
      setSession(decision);
      await queryClient.invalidateQueries({ queryKey: ["channels"] });
      heartbeatTimer.current = window.setInterval(() => {
        heartbeat(decision.session_id).catch(() => {
          stopHeartbeat();
          setSession(null);
        });
      }, 20_000);
    },
    onError: (unknownError) => {
      if (axios.isAxiosError(unknownError) && unknownError.response?.status === 409) {
        const detail = unknownError.response.data?.detail;
        setError({
          message: "A WAN115K ja esta ocupada por outro canal.",
          activeChannel: typeof detail === "object" ? detail.active_channel : undefined,
        });
        return;
      }
      if (axios.isAxiosError(unknownError) && unknownError.response?.status === 404) {
        setError({ message: "Canal indisponivel ou sem video associado." });
        return;
      }
      setError({ message: "Nao foi possivel iniciar a sessao do canal." });
    },
  });

  useEffect(() => {
    return () => {
      stopHeartbeat();
    };
  }, [stopHeartbeat]);

  useEffect(() => {
    function leaveOnPageHide() {
      if (!session) {
        return;
      }
      const token = readToken();
      const headers: HeadersInit = token ? { Authorization: `Bearer ${token}` } : {};
      fetch(`${import.meta.env.VITE_API_BASE_URL ?? "/api"}/sessoes/${session.session_id}/sair`, {
        method: "POST",
        headers,
        keepalive: true,
      }).catch(() => undefined);
    }

    window.addEventListener("pagehide", leaveOnPageHide);
    return () => window.removeEventListener("pagehide", leaveOnPageHide);
  }, [session]);

  return {
    session,
    error,
    isEntering: enterMutation.isPending,
    enter: enterMutation.mutate,
    leave: leaveCurrentSession,
  };
}
