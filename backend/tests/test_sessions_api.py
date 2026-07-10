def test_enter_heartbeat_leave_session_flow(app_client, auth_headers):
    enter = app_client.post("/api/canais/1/entrar", headers=auth_headers["client1"])
    session_id = enter.json()["session_id"]

    heartbeat = app_client.post(f"/api/sessoes/{session_id}/heartbeat", headers=auth_headers["client1"])
    leave = app_client.post(f"/api/sessoes/{session_id}/sair", headers=auth_headers["client1"])

    assert enter.status_code == 200
    assert enter.json()["playlist_url"] == f"/api/sessoes/{session_id}/playlist.m3u"
    assert heartbeat.status_code == 200
    assert leave.status_code == 204


def test_wan_conflict_returns_409_with_active_channel(app_client, auth_headers):
    first_headers = {**auth_headers["client1"], "X-Forwarded-For": "192.168.0.10"}
    second_headers = {**auth_headers["client2"], "X-Forwarded-For": "192.168.0.11"}

    app_client.post("/api/canais/1/entrar", headers=first_headers)
    response = app_client.post("/api/canais/2/entrar", headers=second_headers)

    assert response.status_code == 409
    assert response.json()["detail"]["active_channel"] == 1
