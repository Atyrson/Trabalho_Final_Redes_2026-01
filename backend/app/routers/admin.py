from fastapi import APIRouter, Depends, HTTPException, Response
from pydantic import BaseModel

from app import repositories as repo
from app.dependencies import get_current_user, require_admin
from app.services.media import probe_metadata
from app.services.sessions import cleanup_stale_sessions


router = APIRouter(prefix="/api/admin", tags=["admin"])


class ChannelPayload(BaseModel):
    number: int
    name: str
    description: str | None = None
    status: str = "active"
    current_video_id: int | None = None


class VideoPayload(BaseModel):
    title: str
    hd_path: str
    ld_path: str
    description: str | None = None
    duration_seconds: int | None = None
    bitrate: int | None = None
    resolution: str | None = None
    video_codec: str | None = None
    audio_codec: str | None = None


def _admin(current_user: dict = Depends(get_current_user)):
    return require_admin(current_user)


@router.get("/dashboard")
def dashboard(current_user: dict = Depends(_admin)):
    cleanup_stale_sessions()
    return repo.dashboard()


@router.post("/canais", status_code=201)
def create_channel(payload: ChannelPayload, current_user: dict = Depends(_admin)):
    return repo.create_channel(payload.model_dump())


@router.put("/canais/{channel_id}")
def update_channel(channel_id: int, payload: ChannelPayload, current_user: dict = Depends(_admin)):
    channel = repo.update_channel(channel_id, payload.model_dump())
    if not channel:
        raise HTTPException(status_code=404, detail="channel not found")
    return channel


@router.delete("/canais/{channel_id}", status_code=204)
def delete_channel(channel_id: int, current_user: dict = Depends(_admin)):
    repo.delete_channel(channel_id)
    return Response(status_code=204)


@router.post("/videos", status_code=201)
def create_video(payload: VideoPayload, current_user: dict = Depends(_admin)):
    return repo.create_video(payload.model_dump())


@router.get("/videos")
def list_videos(current_user: dict = Depends(_admin)):
    return repo.list_videos()


@router.put("/videos/{video_id}")
def update_video(video_id: int, payload: VideoPayload, current_user: dict = Depends(_admin)):
    video = repo.update_video(video_id, payload.model_dump())
    if not video:
        raise HTTPException(status_code=404, detail="video not found")
    return video


@router.delete("/videos/{video_id}", status_code=204)
def delete_video(video_id: int, current_user: dict = Depends(_admin)):
    repo.delete_video(video_id)
    return Response(status_code=204)


@router.post("/videos/{video_id}/metadata")
def update_metadata(video_id: int, current_user: dict = Depends(_admin)):
    video = repo.get_video(video_id)
    if not video:
        raise HTTPException(status_code=404, detail="video not found")
    metadata = probe_metadata(video["hd_path"])
    return repo.update_video_metadata(video_id, metadata)
