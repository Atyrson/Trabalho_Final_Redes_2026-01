def test_only_admin_can_create_channel(app_client, auth_headers):
    payload = {"number": 10, "name": "Novo", "description": "Teste", "status": "active"}

    forbidden = app_client.post(
        "/api/admin/canais",
        json=payload,
        headers=auth_headers["client1"],
    )
    allowed = app_client.post(
        "/api/admin/canais",
        json=payload,
        headers=auth_headers["admin"],
    )

    assert forbidden.status_code == 403
    assert allowed.status_code == 201
    assert allowed.json()["number"] == 10


def test_admin_can_create_update_delete_video(app_client, auth_headers):
    create = app_client.post(
        "/api/admin/videos",
        json={"title": "Novo Video", "hd_path": "/media/hd.mp4", "ld_path": "/media/ld.mp4"},
        headers=auth_headers["admin"],
    )
    video_id = create.json()["id"]

    update = app_client.put(
        f"/api/admin/videos/{video_id}",
        json={"title": "Video Atualizado", "hd_path": "/media/hd2.mp4", "ld_path": "/media/ld2.mp4"},
        headers=auth_headers["admin"],
    )
    delete = app_client.delete(f"/api/admin/videos/{video_id}", headers=auth_headers["admin"])

    assert create.status_code == 201
    assert update.status_code == 200
    assert update.json()["title"] == "Video Atualizado"
    assert delete.status_code == 204
