import hashlib
import hmac
import os
from datetime import datetime, timedelta, timezone

import jwt

from app.config import get_settings


def hash_password(password: str) -> str:
    salt = os.urandom(16)
    digest = hashlib.pbkdf2_hmac("sha256", password.encode(), salt, 120_000)
    return f"pbkdf2_sha256${salt.hex()}${digest.hex()}"


def verify_password(password: str, stored_hash: str) -> bool:
    try:
        algorithm, salt_hex, digest_hex = stored_hash.split("$", 2)
    except ValueError:
        return False
    if algorithm != "pbkdf2_sha256":
        return False
    salt = bytes.fromhex(salt_hex)
    expected = bytes.fromhex(digest_hex)
    actual = hashlib.pbkdf2_hmac("sha256", password.encode(), salt, 120_000)
    return hmac.compare_digest(actual, expected)


def create_access_token(user_id: int, login: str, role: str, expires_delta_seconds: int = 3600) -> str:
    now = datetime.now(timezone.utc)
    payload = {
        "sub": str(user_id),
        "login": login,
        "role": role,
        "iat": now,
        "exp": now + timedelta(seconds=expires_delta_seconds),
    }
    return jwt.encode(payload, get_settings().jwt_secret, algorithm="HS256")


def decode_access_token(token: str) -> dict:
    try:
        return jwt.decode(token, get_settings().jwt_secret, algorithms=["HS256"])
    except jwt.PyJWTError as exc:
        raise ValueError("invalid token") from exc
