from urllib.parse import parse_qs

from fastapi import APIRouter, HTTPException, Request

from app import repositories as repo
from app.auth import create_access_token, verify_password


router = APIRouter(prefix="/api/oauth", tags=["oauth"])


@router.post("/token")
async def token(request: Request):
    form = parse_qs((await request.body()).decode())
    username = form.get("username", [""])[0]
    password = form.get("password", [""])[0]
    user = repo.find_user_by_login(username)
    if not user or not verify_password(password, user["password_hash"]):
        raise HTTPException(status_code=401, detail="invalid credentials")
    return {
        "access_token": create_access_token(user["id"], user["login"], user["role"]),
        "token_type": "bearer",
    }
