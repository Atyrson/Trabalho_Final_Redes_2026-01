import pytest


def test_login_returns_bearer_jwt(app_client):
    response = app_client.post(
        "/api/oauth/token",
        data={"username": "admin", "password": "admin123"},
    )

    assert response.status_code == 200
    body = response.json()
    assert body["token_type"] == "bearer"
    assert body["access_token"]


def test_login_rejects_invalid_password(app_client):
    response = app_client.post(
        "/api/oauth/token",
        data={"username": "admin", "password": "wrong"},
    )

    assert response.status_code == 401


def test_decode_rejects_expired_token(app_client):
    from app.auth import create_access_token, decode_access_token

    token = create_access_token(1, "admin", "admin", expires_delta_seconds=-1)

    with pytest.raises(ValueError):
        decode_access_token(token)
