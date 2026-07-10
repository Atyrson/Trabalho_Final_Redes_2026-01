import json


def test_metadata_endpoint_stores_ffprobe_fields(app_client, auth_headers, monkeypatch):
    from app.services import media

    output = {
        "format": {"duration": "12.4", "bit_rate": "115000"},
        "streams": [
            {"codec_type": "video", "width": 640, "height": 360, "codec_name": "h264"},
            {"codec_type": "audio", "codec_name": "aac"},
        ],
    }

    monkeypatch.setattr(media.subprocess, "check_output", lambda command, text=True: json.dumps(output))

    response = app_client.post("/api/admin/videos/1/metadata", headers=auth_headers["admin"])

    assert response.status_code == 200
    body = response.json()
    assert body["duration_seconds"] == 12
    assert body["bitrate"] == 115000
    assert body["resolution"] == "640x360"
    assert body["video_codec"] == "h264"
    assert body["audio_codec"] == "aac"
