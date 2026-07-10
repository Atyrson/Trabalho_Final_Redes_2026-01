import pytest


def test_multicast_address_uses_profile_group_and_channel(app_client):
    from app.services.profiles import multicast_address

    assert multicast_address("LAN", 7, 3) == "239.10.7.3"
    assert multicast_address("WAN115K", 7, 3) == "239.20.7.3"


def test_lan_users_share_same_channel_stream(app_client):
    from app.services.sessions import enter_channel

    first = enter_channel(2, 1, "LAN")
    second = enter_channel(3, 1, "LAN")

    assert first.stream_id == second.stream_id


def test_lan_users_can_watch_different_channels(app_client):
    from app.services.sessions import enter_channel

    first = enter_channel(2, 1, "LAN")
    second = enter_channel(3, 2, "LAN")

    assert first.stream_id != second.stream_id


def test_wan_users_must_share_one_active_channel(app_client):
    from app.services.sessions import enter_channel

    first = enter_channel(2, 1, "WAN115K")
    second = enter_channel(3, 1, "WAN115K")

    assert first.stream_id == second.stream_id
    with pytest.raises(ValueError) as exc:
        enter_channel(3, 2, "WAN115K")
    assert "active_channel" in str(exc.value)


def test_last_wan_session_leave_stops_stream(app_client):
    from app import repositories as repo
    from app.services.sessions import enter_channel, leave_session

    first = enter_channel(2, 1, "WAN115K")
    second = enter_channel(3, 1, "WAN115K")

    leave_session(first.session_id, 2)
    assert repo.get_active_stream(first.stream_id) is not None

    leave_session(second.session_id, 3)
    assert repo.get_active_stream(first.stream_id) is None
