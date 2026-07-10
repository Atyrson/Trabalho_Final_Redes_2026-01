def test_client_can_list_channels(app_client, auth_headers):
    response = app_client.get("/api/canais", headers=auth_headers["client1"])

    assert response.status_code == 200
    channels = response.json()
    assert channels[0]["number"] == 1
    assert "viewer_count" in channels[0]


def test_client_can_view_channel_detail_with_video(app_client, auth_headers):
    response = app_client.get("/api/canais/1", headers=auth_headers["client1"])

    assert response.status_code == 200
    body = response.json()
    assert body["id"] == 1
    assert body["video"]["hd_path"].endswith("canal1-hd.mp4")
