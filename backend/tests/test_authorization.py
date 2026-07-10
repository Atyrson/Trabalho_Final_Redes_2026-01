def test_protected_routes_require_bearer_token(app_client):
    response = app_client.get("/api/canais")

    assert response.status_code == 401


def test_admin_routes_reject_client_role(app_client, auth_headers):
    response = app_client.get("/api/admin/dashboard", headers=auth_headers["client1"])

    assert response.status_code == 403


def test_profile_defaults_to_lan(app_client, auth_headers):
    response = app_client.post("/api/canais/1/entrar", headers=auth_headers["client1"])

    assert response.status_code == 200
    assert response.json()["profile"] == "LAN"


def test_profile_uses_x_forwarded_for_for_wan(app_client, auth_headers):
    headers = {**auth_headers["client1"], "X-Forwarded-For": "192.168.0.10"}

    response = app_client.post("/api/canais/1/entrar", headers=headers)

    assert response.status_code == 200
    assert response.json()["profile"] == "WAN115K"
