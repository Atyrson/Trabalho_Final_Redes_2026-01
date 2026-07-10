def test_playlist_contains_udp_multicast_url(app_client, auth_headers):
    enter = app_client.post("/api/canais/1/entrar", headers=auth_headers["client1"])
    session_id = enter.json()["session_id"]

    response = app_client.get(f"/api/sessoes/{session_id}/playlist.m3u", headers=auth_headers["client1"])

    assert response.status_code == 200
    assert response.text.splitlines() == [
        "#EXTM3U",
        "#EXTINF:-1,Canal 1",
        "udp://@239.10.7.1:5004",
    ]


def test_playlist_is_limited_to_owner_or_admin(app_client, auth_headers):
    enter = app_client.post("/api/canais/1/entrar", headers=auth_headers["client1"])
    session_id = enter.json()["session_id"]

    forbidden = app_client.get(f"/api/sessoes/{session_id}/playlist.m3u", headers=auth_headers["client2"])
    allowed = app_client.get(f"/api/sessoes/{session_id}/playlist.m3u", headers=auth_headers["admin"])

    assert forbidden.status_code == 403
    assert allowed.status_code == 200
