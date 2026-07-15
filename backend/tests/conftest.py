import os
import sys
from pathlib import Path
from datetime import datetime, timedelta, timezone

import jwt
import pytest
from jwt.algorithms import RSAAlgorithm


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))


@pytest.fixture()
def oidc_keys():
    from cryptography.hazmat.primitives.asymmetric import rsa

    private_key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    jwk = RSAAlgorithm.to_jwk(private_key.public_key(), as_dict=True)
    jwk.update({"kid": "test-key", "alg": "RS256", "use": "sig"})
    return private_key, {"keys": [jwk]}


@pytest.fixture()
def token_factory(oidc_keys):
    private_key, _ = oidc_keys

    def build_token(username: str, role: str = "client", expires_delta_seconds: int = 3600, issuer: str = "http://testserver/realms/mini-iptv", audience: str | None = None):
        now = datetime.now(timezone.utc)
        payload = {
            "sub": f"test-{username}",
            "preferred_username": username,
            "azp": audience or "mini-iptv-frontend",
            "iat": now,
            "exp": now + timedelta(seconds=expires_delta_seconds),
            "iss": issuer,
            "realm_access": {"roles": [role]},
        }
        return jwt.encode(payload, private_key, algorithm="RS256", headers={"kid": "test-key"})

    return build_token


@pytest.fixture()
def app_client(tmp_path, monkeypatch, oidc_keys):
    _, jwks = oidc_keys
    monkeypatch.setenv("DATABASE_URL", f"sqlite:///{tmp_path / 'iptv.sqlite3'}")
    monkeypatch.setenv("IPTV_GROUP_ID", "7")
    monkeypatch.setenv("WAN_CIDRS", "192.168.0.0/24")
    monkeypatch.setenv("MEDIA_ROOT", str(tmp_path / "media"))
    monkeypatch.setenv("OIDC_ISSUER_URL", "http://testserver/realms/mini-iptv")
    monkeypatch.setenv("OIDC_AUDIENCE", "mini-iptv-frontend")
    monkeypatch.setenv("OIDC_JWKS_JSON", __import__("json").dumps(jwks))

    from fastapi.testclient import TestClient
    from app.main import create_app

    app = create_app()
    with TestClient(app) as client:
        yield client


@pytest.fixture()
def auth_headers(app_client, token_factory):
    return {
        "admin": {"Authorization": f"Bearer {token_factory('admin', 'admin')}"},
        "client1": {"Authorization": f"Bearer {token_factory('cliente1')}"},
        "client2": {"Authorization": f"Bearer {token_factory('cliente2')}"},
    }
