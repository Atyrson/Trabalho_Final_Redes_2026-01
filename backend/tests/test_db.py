def test_seed_data_is_available(app_client):
    from app import repositories as repo

    assert repo.find_user_by_login("admin")["role"] == "admin"
    assert repo.find_user_by_login("cliente1")["role"] == "client"
    assert len(repo.list_channels()) == 3
    assert len(repo.list_videos()) == 3
