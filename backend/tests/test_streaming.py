def test_start_stream_calls_cvlc_for_udp_multicast(monkeypatch):
    from app.services.streaming import start_stream

    calls = []

    class FakeProcess:
        pid = 4321

    def fake_popen(command):
        calls.append(command)
        return FakeProcess()

    monkeypatch.setattr("subprocess.Popen", fake_popen)

    pid = start_stream("/video.mp4", "239.10.7.1")

    assert pid == 4321
    assert calls[0][0] == "cvlc"
    assert "/video.mp4" in calls[0]
    assert "dst=239.10.7.1:5004" in calls[0][-1]


def test_session_uses_hd_for_lan_and_ld_for_wan(app_client, monkeypatch):
    from app.services.sessions import enter_channel

    started = []

    def fake_start(path, multicast_address, port=5004):
        started.append((path, multicast_address, port))
        return len(started) + 100

    monkeypatch.setattr("app.services.streaming.start_stream", fake_start)

    enter_channel(2, 1, "LAN")
    enter_channel(3, 2, "WAN115K")

    assert started[0][0].endswith("canal1-hd.mp4")
    assert started[1][0].endswith("canal2-ld.mp4")


def test_existing_compatible_stream_is_reused_and_last_leave_stops(app_client, monkeypatch):
    from app.services.sessions import enter_channel, leave_session

    started = []
    stopped = []

    monkeypatch.setattr(
        "app.services.streaming.start_stream",
        lambda path, multicast_address, port=5004: started.append(path) or 5000 + len(started),
    )
    monkeypatch.setattr("app.services.streaming.stop_stream", lambda pid: stopped.append(pid))

    first = enter_channel(2, 1, "LAN")
    second = enter_channel(3, 1, "LAN")
    leave_session(first.session_id, 2)
    leave_session(second.session_id, 3)

    assert len(started) == 1
    assert stopped == [5001]
