from typing import Any

from app.db import transaction


def _one(row) -> dict[str, Any] | None:
    return dict(row) if row is not None else None


def find_user_by_login(login: str) -> dict[str, Any] | None:
    with transaction() as con:
        return _one(con.execute("SELECT * FROM users WHERE login = ?", (login,)).fetchone())


def get_user(user_id: int) -> dict[str, Any] | None:
    with transaction() as con:
        return _one(con.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone())


def list_channels() -> list[dict[str, Any]]:
    with transaction() as con:
        rows = con.execute(
            """
            SELECT c.*,
                   COUNT(CASE WHEN s.active = 1 THEN 1 END) AS viewer_count
            FROM channels c
            LEFT JOIN sessions s ON s.channel_id = c.id AND s.active = 1
            GROUP BY c.id
            ORDER BY c.number
            """
        ).fetchall()
        return [dict(row) for row in rows]


def get_channel(channel_id: int) -> dict[str, Any] | None:
    with transaction() as con:
        return _one(con.execute("SELECT * FROM channels WHERE id = ?", (channel_id,)).fetchone())


def get_channel_by_number(number: int) -> dict[str, Any] | None:
    with transaction() as con:
        return _one(con.execute("SELECT * FROM channels WHERE number = ?", (number,)).fetchone())


def get_channel_detail(channel_id: int) -> dict[str, Any] | None:
    channel = get_channel(channel_id)
    if not channel:
        return None
    channel["video"] = get_video(channel["current_video_id"]) if channel.get("current_video_id") else None
    return channel


def create_channel(data: dict[str, Any]) -> dict[str, Any]:
    with transaction() as con:
        cursor = con.execute(
            "INSERT INTO channels(number, name, description, status, current_video_id) VALUES (?, ?, ?, ?, ?)",
            (
                data["number"],
                data["name"],
                data.get("description"),
                data.get("status", "active"),
                data.get("current_video_id"),
            ),
        )
        return _one(con.execute("SELECT * FROM channels WHERE id = ?", (cursor.lastrowid,)).fetchone())


def update_channel(channel_id: int, data: dict[str, Any]) -> dict[str, Any] | None:
    with transaction() as con:
        con.execute(
            "UPDATE channels SET number = ?, name = ?, description = ?, status = ?, current_video_id = ? WHERE id = ?",
            (
                data["number"],
                data["name"],
                data.get("description"),
                data.get("status", "active"),
                data.get("current_video_id"),
                channel_id,
            ),
        )
        return _one(con.execute("SELECT * FROM channels WHERE id = ?", (channel_id,)).fetchone())


def delete_channel(channel_id: int) -> None:
    with transaction() as con:
        con.execute("DELETE FROM channels WHERE id = ?", (channel_id,))


def list_videos() -> list[dict[str, Any]]:
    with transaction() as con:
        return [dict(row) for row in con.execute("SELECT * FROM videos ORDER BY id").fetchall()]


def get_video(video_id: int) -> dict[str, Any] | None:
    with transaction() as con:
        return _one(con.execute("SELECT * FROM videos WHERE id = ?", (video_id,)).fetchone())


def create_video(data: dict[str, Any]) -> dict[str, Any]:
    with transaction() as con:
        cursor = con.execute(
            """
            INSERT INTO videos(title, hd_path, ld_path, description, duration_seconds, bitrate, resolution, video_codec, audio_codec)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                data["title"],
                data["hd_path"],
                data["ld_path"],
                data.get("description"),
                data.get("duration_seconds"),
                data.get("bitrate"),
                data.get("resolution"),
                data.get("video_codec"),
                data.get("audio_codec"),
            ),
        )
        return _one(con.execute("SELECT * FROM videos WHERE id = ?", (cursor.lastrowid,)).fetchone())


def update_video(video_id: int, data: dict[str, Any]) -> dict[str, Any] | None:
    with transaction() as con:
        con.execute(
            """
            UPDATE videos
            SET title = ?, hd_path = ?, ld_path = ?, description = ?, duration_seconds = ?,
                bitrate = ?, resolution = ?, video_codec = ?, audio_codec = ?
            WHERE id = ?
            """,
            (
                data["title"],
                data["hd_path"],
                data["ld_path"],
                data.get("description"),
                data.get("duration_seconds"),
                data.get("bitrate"),
                data.get("resolution"),
                data.get("video_codec"),
                data.get("audio_codec"),
                video_id,
            ),
        )
        return _one(con.execute("SELECT * FROM videos WHERE id = ?", (video_id,)).fetchone())


def update_video_metadata(video_id: int, metadata: dict[str, Any]) -> dict[str, Any] | None:
    with transaction() as con:
        con.execute(
            """
            UPDATE videos
            SET duration_seconds = ?, bitrate = ?, resolution = ?, video_codec = ?, audio_codec = ?
            WHERE id = ?
            """,
            (
                metadata.get("duration_seconds"),
                metadata.get("bitrate"),
                metadata.get("resolution"),
                metadata.get("video_codec"),
                metadata.get("audio_codec"),
                video_id,
            ),
        )
        return _one(con.execute("SELECT * FROM videos WHERE id = ?", (video_id,)).fetchone())


def delete_video(video_id: int) -> None:
    with transaction() as con:
        con.execute("DELETE FROM videos WHERE id = ?", (video_id,))


def create_session(user_id: int, channel_id: int, profile: str, multicast_address: str) -> dict[str, Any]:
    with transaction() as con:
        cursor = con.execute(
            "INSERT INTO sessions(user_id, channel_id, profile, multicast_address) VALUES (?, ?, ?, ?)",
            (user_id, channel_id, profile, multicast_address),
        )
        return _one(con.execute("SELECT * FROM sessions WHERE id = ?", (cursor.lastrowid,)).fetchone())


def get_session(session_id: int) -> dict[str, Any] | None:
    with transaction() as con:
        return _one(con.execute("SELECT * FROM sessions WHERE id = ?", (session_id,)).fetchone())


def touch_session(session_id: int) -> None:
    with transaction() as con:
        con.execute("UPDATE sessions SET last_seen = CURRENT_TIMESTAMP WHERE id = ? AND active = 1", (session_id,))


def deactivate_session(session_id: int) -> None:
    with transaction() as con:
        con.execute("UPDATE sessions SET active = 0, last_seen = CURRENT_TIMESTAMP WHERE id = ?", (session_id,))


def count_active_sessions(channel_id: int | None = None, profile: str | None = None) -> int:
    query = "SELECT COUNT(*) FROM sessions WHERE active = 1"
    params: list[Any] = []
    if channel_id is not None:
        query += " AND channel_id = ?"
        params.append(channel_id)
    if profile is not None:
        query += " AND profile = ?"
        params.append(profile)
    with transaction() as con:
        return con.execute(query, params).fetchone()[0]


def list_active_sessions(profile: str | None = None) -> list[dict[str, Any]]:
    query = "SELECT * FROM sessions WHERE active = 1"
    params: list[Any] = []
    if profile:
        query += " AND profile = ?"
        params.append(profile)
    with transaction() as con:
        return [dict(row) for row in con.execute(query, params).fetchall()]


def list_stale_sessions(timeout_seconds: int) -> list[dict[str, Any]]:
    with transaction() as con:
        return [
            dict(row)
            for row in con.execute(
                """
                SELECT *
                FROM sessions
                WHERE active = 1
                  AND last_seen <= datetime('now', ?)
                """,
                (f"-{timeout_seconds} seconds",),
            ).fetchall()
        ]


def deactivate_sessions(session_ids: list[int]) -> None:
    if not session_ids:
        return
    placeholders = ",".join("?" for _ in session_ids)
    with transaction() as con:
        con.execute(
            f"UPDATE sessions SET active = 0, last_seen = CURRENT_TIMESTAMP WHERE id IN ({placeholders})",
            session_ids,
        )


def find_active_stream(profile: str, channel_id: int) -> dict[str, Any] | None:
    with transaction() as con:
        return _one(
            con.execute(
                "SELECT * FROM active_streams WHERE profile = ? AND channel_id = ?",
                (profile, channel_id),
            ).fetchone()
        )


def create_active_stream(channel_id: int, profile: str, multicast_address: str, port: int, pid: int) -> dict[str, Any]:
    with transaction() as con:
        cursor = con.execute(
            "INSERT INTO active_streams(channel_id, profile, multicast_address, port, pid) VALUES (?, ?, ?, ?, ?)",
            (channel_id, profile, multicast_address, port, pid),
        )
        return _one(con.execute("SELECT * FROM active_streams WHERE id = ?", (cursor.lastrowid,)).fetchone())


def get_active_stream(stream_id: int) -> dict[str, Any] | None:
    with transaction() as con:
        return _one(con.execute("SELECT * FROM active_streams WHERE id = ?", (stream_id,)).fetchone())


def list_active_streams(profile: str | None = None) -> list[dict[str, Any]]:
    query = """
        SELECT s.*, c.number AS channel_number, c.name AS channel_name
        FROM active_streams s
        JOIN channels c ON c.id = s.channel_id
    """
    params: list[Any] = []
    if profile:
        query += " WHERE s.profile = ?"
        params.append(profile)
    query += " ORDER BY s.started_at"
    with transaction() as con:
        return [dict(row) for row in con.execute(query, params).fetchall()]


def delete_active_stream(stream_id: int) -> None:
    with transaction() as con:
        con.execute("DELETE FROM active_streams WHERE id = ?", (stream_id,))


def dashboard() -> dict[str, Any]:
    streams = list_active_streams()
    sessions = list_active_sessions()
    wan_streams = [stream for stream in streams if stream["profile"] == "WAN115K"]
    return {
        "active_users": len({session["user_id"] for session in sessions}),
        "active_channels": sorted({stream["channel_number"] for stream in streams}),
        "vlc_pids": [stream["pid"] for stream in streams],
        "wan_active_channel": wan_streams[0]["channel_number"] if wan_streams else None,
        "active_streams": streams,
        "active_multicast_flows": [
            {
                "profile": stream["profile"],
                "channel": stream["channel_number"],
                "multicast_address": stream["multicast_address"],
                "port": stream["port"],
            }
            for stream in streams
        ],
    }
