import json
import subprocess


def probe_metadata(path: str) -> dict:
    command = [
        "ffprobe",
        "-v",
        "quiet",
        "-print_format",
        "json",
        "-show_format",
        "-show_streams",
        path,
    ]
    data = json.loads(subprocess.check_output(command, text=True))
    video = next((stream for stream in data.get("streams", []) if stream.get("codec_type") == "video"), {})
    audio = next((stream for stream in data.get("streams", []) if stream.get("codec_type") == "audio"), {})
    duration = data.get("format", {}).get("duration")
    bitrate = data.get("format", {}).get("bit_rate")
    return {
        "duration_seconds": int(float(duration)) if duration else None,
        "bitrate": int(bitrate) if bitrate else None,
        "resolution": f"{video.get('width')}x{video.get('height')}" if video.get("width") and video.get("height") else None,
        "video_codec": video.get("codec_name"),
        "audio_codec": audio.get("codec_name"),
    }
