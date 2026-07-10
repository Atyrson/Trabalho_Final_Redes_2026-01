from dataclasses import dataclass

from app import repositories as repo
from app.config import get_settings
from app.services.profiles import multicast_address
from app.services import streaming


@dataclass(frozen=True)
class SessionDecision:
    session_id: int
    stream_id: int
    profile: str
    multicast_address: str
    port: int


class WanConflict(ValueError):
    def __init__(self, active_channel: int):
        super().__init__(f"active_channel={active_channel}")
        self.active_channel = active_channel


def enter_channel(user_id: int, channel_id: int, profile: str) -> SessionDecision:
    channel = repo.get_channel(channel_id)
    if not channel:
        raise LookupError("channel not found")
    if profile == "WAN115K":
        for stream in repo.list_active_streams("WAN115K"):
            if stream["channel_id"] != channel_id:
                raise WanConflict(stream["channel_number"])

    address = multicast_address(profile, get_settings().iptv_group_id, channel["number"])
    stream = repo.find_active_stream(profile, channel_id)
    if not stream:
        video = repo.get_video(channel["current_video_id"]) if channel.get("current_video_id") else None
        if not video:
            raise LookupError("channel has no video")
        video_path = video["hd_path"] if profile == "LAN" else video["ld_path"]
        pid = streaming.start_stream(video_path, address, 5004)
        stream = repo.create_active_stream(channel_id, profile, address, 5004, pid)

    session = repo.create_session(user_id, channel_id, profile, address)
    return SessionDecision(session["id"], stream["id"], profile, address, stream["port"])


def heartbeat(session_id: int, user_id: int) -> None:
    session = repo.get_session(session_id)
    if not session or not session["active"]:
        raise LookupError("session not found")
    if session["user_id"] != user_id:
        raise PermissionError("session owner required")
    repo.touch_session(session_id)


def leave_session(session_id: int, user_id: int) -> None:
    session = repo.get_session(session_id)
    if not session or not session["active"]:
        return
    if session["user_id"] != user_id:
        raise PermissionError("session owner required")

    repo.deactivate_session(session_id)
    if repo.count_active_sessions(session["channel_id"], session["profile"]) > 0:
        return

    stream = repo.find_active_stream(session["profile"], session["channel_id"])
    if stream:
        streaming.stop_stream(stream["pid"])
        repo.delete_active_stream(stream["id"])
