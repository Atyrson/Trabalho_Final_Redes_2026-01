import hashlib
import hmac
import json
import os

import jwt
from jwt import PyJWKClient
from jwt.algorithms import RSAAlgorithm

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


def decode_access_token(token: str) -> dict:
    settings = get_settings()
    try:
        signing_key = _resolve_signing_key(token)
        payload = jwt.decode(
            token,
            signing_key,
            algorithms=["RS256"],
            issuer=settings.oidc_issuer_url,
            options={"verify_aud": False},
        )
    except jwt.PyJWTError as exc:
        raise ValueError("invalid token") from exc
    role = _extract_role(payload)
    username = payload.get("preferred_username") or payload.get("login")
    if not username or not role:
        raise ValueError("invalid token")
    if not _matches_audience(payload, settings.oidc_audience):
        raise ValueError("invalid token")
    payload["login"] = username
    payload["role"] = role
    return payload


def _resolve_signing_key(token: str):
    settings = get_settings()
    if settings.oidc_jwks_json:
        header = jwt.get_unverified_header(token)
        key_id = header.get("kid")
        jwks = json.loads(settings.oidc_jwks_json)
        for jwk in jwks.get("keys", []):
            if jwk.get("kid") == key_id:
                return RSAAlgorithm.from_jwk(json.dumps(jwk))
        raise jwt.InvalidTokenError("signing key not found")
    return PyJWKClient(settings.oidc_jwks_url).get_signing_key_from_jwt(token).key


def _extract_role(payload: dict) -> str | None:
    roles = set(payload.get("realm_access", {}).get("roles", []))
    resource_access = payload.get("resource_access", {})
    for access in resource_access.values():
        roles.update(access.get("roles", []))
    if "admin" in roles:
        return "admin"
    if "client" in roles:
        return "client"
    return None


def _matches_audience(payload: dict, expected: str) -> bool:
    audience = payload.get("aud", [])
    if isinstance(audience, str):
        audience = [audience]
    return expected in audience or payload.get("azp") == expected
