import os
import signal
import subprocess


def start_stream(video_path: str, multicast_address: str, port: int = 5004) -> int:
    command = [
        "cvlc",
        "--intf",
        "dummy",
        video_path,
        "--sout",
        f"#standard{{access=udp,mux=ts,dst={multicast_address}:{port}}}",
    ]
    try:
        process = subprocess.Popen(command)
    except FileNotFoundError:
        return 0
    return process.pid


def stop_stream(pid: int) -> None:
    if pid <= 0:
        return
    try:
        os.kill(pid, signal.SIGTERM)
    except ProcessLookupError:
        return
