import pytest


def test_local_password_token_endpoint_is_not_registered(app_client):
    response = app_client.post(
        "/api/oauth/token",
        data={"username": "admin", "password": "admin123"},
    )

    assert response.status_code == 404


def test_decode_accepts_valid_oidc_token(app_client, token_factory):
    from app.auth import decode_access_token

    payload = decode_access_token(token_factory("admin", "admin"))

    assert payload["login"] == "admin"
    assert payload["role"] == "admin"


def test_decode_rejects_expired_oidc_token(app_client, token_factory):
    from app.auth import decode_access_token

    token = token_factory("admin", "admin", expires_delta_seconds=-1)

    with pytest.raises(ValueError):
        decode_access_token(token)


def test_decode_rejects_wrong_issuer(app_client, token_factory):
    from app.auth import decode_access_token

    token = token_factory("admin", "admin", issuer="http://wrong-issuer/realms/mini-iptv")

    with pytest.raises(ValueError):
        decode_access_token(token)


def test_decode_rejects_wrong_audience(app_client, token_factory):
    from app.auth import decode_access_token

    token = token_factory("admin", "admin", audience="other-client")

    with pytest.raises(ValueError):
        decode_access_token(token)
