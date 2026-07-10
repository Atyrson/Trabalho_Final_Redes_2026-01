def test_e2e_lan_login_list_enter_playlist_leave(app_client):
    login = app_client.post(
        "/api/oauth/token",
        data={"username": "cliente1", "password": "cliente123"},
    )
    headers = {"Authorization": f"Bearer {login.json()['access_token']}"}

    channels = app_client.get("/api/canais", headers=headers)
    enter = app_client.post("/api/canais/1/entrar", headers=headers)
    session_id = enter.json()["session_id"]
    playlist = app_client.get(f"/api/sessoes/{session_id}/playlist.m3u", headers=headers)
    leave = app_client.post(f"/api/sessoes/{session_id}/sair", headers=headers)

    assert login.status_code == 200
    assert channels.status_code == 200
    assert enter.json()["multicast_address"] == "239.10.7.1"
    assert "udp://@239.10.7.1:5004" in playlist.text
    assert leave.status_code == 204


def test_e2e_wan_second_channel_is_blocked_but_same_channel_allowed(app_client, auth_headers):
    wan_x = {**auth_headers["client1"], "X-Forwarded-For": "192.168.0.10"}
    wan_y = {**auth_headers["client2"], "X-Forwarded-For": "192.168.0.11"}

    first = app_client.post("/api/canais/1/entrar", headers=wan_x)
    blocked = app_client.post("/api/canais/2/entrar", headers=wan_y)
    shared = app_client.post("/api/canais/1/entrar", headers=wan_y)

    assert first.status_code == 200
    assert first.json()["multicast_address"] == "239.20.7.1"
    assert blocked.status_code == 409
    assert shared.status_code == 200
    assert shared.json()["multicast_address"] == "239.20.7.1"
