def test_healthcheck_returns_ok(app_client):
    response = app_client.get("/api/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}
