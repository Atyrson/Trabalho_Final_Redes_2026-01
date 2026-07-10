import ipaddress

from fastapi import HTTPException, Request

from app.auth import decode_access_token
from app.config import get_settings
from app import repositories as repo


def get_current_user(request: Request) -> dict:
    header = request.headers.get("Authorization", "")
    if not header.lower().startswith("bearer "):
        raise HTTPException(status_code=401, detail="missing bearer token")
    try:
        payload = decode_access_token(header.split(" ", 1)[1])
        user = repo.get_user(int(payload["sub"]))
    except (KeyError, TypeError, ValueError):
        user = None
    if not user:
        raise HTTPException(status_code=401, detail="invalid token")
    return user


def require_admin(current_user: dict) -> dict:
    if current_user["role"] != "admin":
        raise HTTPException(status_code=403, detail="admin required")
    return current_user


def detect_client_profile(request: Request) -> str:
    forwarded = request.headers.get("X-Forwarded-For")
    client_ip = (forwarded.split(",", 1)[0].strip() if forwarded else None) or request.client.host
    try:
        ip = ipaddress.ip_address(client_ip)
    except ValueError:
        return "LAN"
    for cidr in get_settings().wan_cidrs:
        if ip in ipaddress.ip_network(cidr, strict=False):
            return "WAN115K"
    return "LAN"
