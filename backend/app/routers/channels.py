from fastapi import APIRouter, Depends, HTTPException, Request, Response

from app import repositories as repo
from app.dependencies import detect_client_profile, get_current_user
from app.services import playlists
from app.services.sessions import WanConflict, cleanup_stale_sessions, enter_channel, heartbeat, leave_session


router = APIRouter(prefix="/api", tags=["channels"])


@router.get("/canais")
def list_channels(current_user: dict = Depends(get_current_user)):
    cleanup_stale_sessions()
    return [
        {
            "id": channel["id"],
            "number": channel["number"],
            "name": channel["name"],
            "description": channel["description"],
            "status": channel["status"],
            "viewer_count": channel["viewer_count"],
        }
        for channel in repo.list_channels()
    ]


@router.get("/canais/{channel_id}")
def channel_detail(channel_id: int, current_user: dict = Depends(get_current_user)):
    channel = repo.get_channel_detail(channel_id)
    if not channel:
        raise HTTPException(status_code=404, detail="channel not found")
    return channel


@router.post("/canais/{channel_id}/entrar")
def enter(channel_id: int, request: Request, current_user: dict = Depends(get_current_user)):
    profile = detect_client_profile(request)
    try:
        decision = enter_channel(current_user["id"], channel_id, profile)
    except WanConflict as exc:
        raise HTTPException(status_code=409, detail={"active_channel": exc.active_channel}) from exc
    except LookupError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    return {
        "session_id": decision.session_id,
        "profile": decision.profile,
        "multicast_address": decision.multicast_address,
        "port": decision.port,
        "playlist_url": f"/api/sessoes/{decision.session_id}/playlist.m3u",
    }


@router.post("/sessoes/{session_id}/heartbeat")
def session_heartbeat(session_id: int, current_user: dict = Depends(get_current_user)):
    try:
        heartbeat(session_id, current_user["id"])
    except PermissionError as exc:
        raise HTTPException(status_code=403, detail=str(exc)) from exc
    except LookupError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    return {"status": "ok"}


@router.post("/sessoes/{session_id}/sair", status_code=204)
def session_leave(session_id: int, current_user: dict = Depends(get_current_user)):
    try:
        leave_session(session_id, current_user["id"])
    except PermissionError as exc:
        raise HTTPException(status_code=403, detail=str(exc)) from exc
    return Response(status_code=204)


@router.get("/sessoes/{session_id}/playlist.m3u")
def session_playlist(session_id: int, current_user: dict = Depends(get_current_user)):
    session = repo.get_session(session_id)
    if not session:
        raise HTTPException(status_code=404, detail="session not found")
    if session["user_id"] != current_user["id"] and current_user["role"] != "admin":
        raise HTTPException(status_code=403, detail="session owner required")
    channel = repo.get_channel(session["channel_id"])
    return Response(playlists.generate_m3u(channel, session), media_type="audio/x-mpegurl")
