def generate_m3u(channel: dict, session: dict, port: int = 5004) -> str:
    return "\n".join(
        [
            "#EXTM3U",
            f"#EXTINF:-1,{channel['name']}",
            f"udp://@{session['multicast_address']}:{port}",
        ]
    )
