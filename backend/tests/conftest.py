import os
import sys
from pathlib import Path

import pytest


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))


@pytest.fixture()
def app_client(tmp_path, monkeypatch):
    monkeypatch.setenv("DATABASE_URL", f"sqlite:///{tmp_path / 'iptv.sqlite3'}")
    monkeypatch.setenv("JWT_SECRET", "test-secret-with-at-least-32-bytes")
    monkeypatch.setenv("IPTV_GROUP_ID", "7")
    monkeypatch.setenv("WAN_CIDRS", "192.168.0.0/24")
    monkeypatch.setenv("MEDIA_ROOT", str(tmp_path / "media"))

    from fastapi.testclient import TestClient
    from app.main import create_app

    app = create_app()
    with TestClient(app) as client:
        yield client


@pytest.fixture()
def auth_headers(app_client):
    def login(username, password="cliente123"):
        response = app_client.post(
            "/api/oauth/token",
            data={"username": username, "password": password},
        )
        assert response.status_code == 200
        token = response.json()["access_token"]
        return {"Authorization": f"Bearer {token}"}

    return {
        "admin": login("admin", "admin123"),
        "client1": login("cliente1"),
        "client2": login("cliente2"),
    }
