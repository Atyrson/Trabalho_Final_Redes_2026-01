def test_admin_dashboard_lists_active_streams(app_client, auth_headers):
    app_client.post("/api/canais/1/entrar", headers=auth_headers["client1"])

    response = app_client.get("/api/admin/dashboard", headers=auth_headers["admin"])

    assert response.status_code == 200
    body = response.json()
    assert body["active_users"] == 1
    assert body["active_channels"] == [1]
    assert body["active_streams"][0]["multicast_address"] == "239.10.7.1"


def test_wan_active_channel_is_reported(app_client, auth_headers):
    headers = {**auth_headers["client1"], "X-Forwarded-For": "192.168.0.10"}
    app_client.post("/api/canais/2/entrar", headers=headers)

    response = app_client.get("/api/admin/dashboard", headers=auth_headers["admin"])

    assert response.json()["wan_active_channel"] == 2
