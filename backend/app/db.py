import sqlite3
from contextlib import contextmanager
from pathlib import Path

from app.auth import hash_password
from app.config import get_settings, sqlite_path


def connect() -> sqlite3.Connection:
    db_path = sqlite_path(get_settings().database_url)
    if str(db_path) != ":memory:":
        db_path.parent.mkdir(parents=True, exist_ok=True)
    connection = sqlite3.connect(db_path)
    connection.row_factory = sqlite3.Row
    connection.execute("PRAGMA foreign_keys = ON")
    return connection


@contextmanager
def transaction():
    connection = connect()
    try:
        yield connection
        connection.commit()
    except Exception:
        connection.rollback()
        raise
    finally:
        connection.close()


def init_db() -> None:
    schema = Path(__file__).with_name("schema.sql").read_text()
    with transaction() as connection:
        connection.executescript(schema)
        if connection.execute("SELECT COUNT(*) FROM users").fetchone()[0] > 0:
            return
        connection.executemany(
            "INSERT INTO users(login, password_hash, role) VALUES (?, ?, ?)",
            [
                ("admin", hash_password("admin123"), "admin"),
                ("cliente1", hash_password("cliente123"), "client"),
                ("cliente2", hash_password("cliente123"), "client"),
            ],
        )
        connection.executemany(
            """
            INSERT INTO videos(title, hd_path, ld_path, description, duration_seconds, bitrate, resolution, video_codec, audio_codec)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            [
                ("Video 1", "/srv/iptv/canal1-hd.mp4", "/srv/iptv/canal1-ld.mp4", "Video seed 1", 60, 4_000_000, "1920x1080", "h264", "aac"),
                ("Video 2", "/srv/iptv/canal2-hd.mp4", "/srv/iptv/canal2-ld.mp4", "Video seed 2", 60, 4_000_000, "1920x1080", "h264", "aac"),
                ("Video 3", "/srv/iptv/canal3-hd.mp4", "/srv/iptv/canal3-ld.mp4", "Video seed 3", 60, 4_000_000, "1920x1080", "h264", "aac"),
            ],
        )
        connection.executemany(
            "INSERT INTO channels(number, name, description, status, current_video_id) VALUES (?, ?, ?, ?, ?)",
            [
                (1, "Canal 1", "Canal principal", "active", 1),
                (2, "Canal 2", "Canal secundario", "active", 2),
                (3, "Canal 3", "Canal extra", "active", 3),
            ],
        )
