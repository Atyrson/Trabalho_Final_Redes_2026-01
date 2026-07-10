import os
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class Settings:
    database_url: str
    jwt_secret: str
    iptv_group_id: int
    wan_cidrs: list[str]
    media_root: Path
    session_timeout_seconds: int


def get_settings() -> Settings:
    return Settings(
        database_url=os.getenv("DATABASE_URL", "sqlite:///./mini_iptv.sqlite3"),
        jwt_secret=os.getenv("JWT_SECRET", "dev-change-me-with-at-least-32-bytes"),
        iptv_group_id=int(os.getenv("IPTV_GROUP_ID", "1")),
        wan_cidrs=[cidr.strip() for cidr in os.getenv("WAN_CIDRS", "192.168.0.0/24").split(",") if cidr.strip()],
        media_root=Path(os.getenv("MEDIA_ROOT", "./media")),
        session_timeout_seconds=int(os.getenv("SESSION_TIMEOUT_SECONDS", "60")),
    )


def sqlite_path(database_url: str) -> Path:
    prefix = "sqlite:///"
    if not database_url.startswith(prefix):
        raise ValueError("Only sqlite:/// DATABASE_URL values are supported")
    return Path(database_url[len(prefix) :])
