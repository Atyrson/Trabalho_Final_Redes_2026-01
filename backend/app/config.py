import os
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class Settings:
    database_url: str
    iptv_group_id: int
    wan_cidrs: list[str]
    media_root: Path
    session_timeout_seconds: int
    oidc_issuer_url: str
    oidc_jwks_url: str
    oidc_audience: str
    oidc_jwks_json: str | None


def get_settings() -> Settings:
    return Settings(
        database_url=os.getenv("DATABASE_URL", "sqlite:///./mini_iptv.sqlite3"),
        iptv_group_id=int(os.getenv("IPTV_GROUP_ID", "1")),
        wan_cidrs=[cidr.strip() for cidr in os.getenv("WAN_CIDRS", "192.168.0.0/24").split(",") if cidr.strip()],
        media_root=Path(os.getenv("MEDIA_ROOT", "./media")),
        session_timeout_seconds=int(os.getenv("SESSION_TIMEOUT_SECONDS", "60")),
        oidc_issuer_url=os.getenv("OIDC_ISSUER_URL", "http://127.0.0.1:8080/realms/mini-iptv"),
        oidc_jwks_url=os.getenv(
            "OIDC_JWKS_URL",
            "http://127.0.0.1:8080/realms/mini-iptv/protocol/openid-connect/certs",
        ),
        oidc_audience=os.getenv("OIDC_AUDIENCE", "mini-iptv-frontend"),
        oidc_jwks_json=os.getenv("OIDC_JWKS_JSON"),
    )


def sqlite_path(database_url: str) -> Path:
    prefix = "sqlite:///"
    if not database_url.startswith(prefix):
        raise ValueError("Only sqlite:/// DATABASE_URL values are supported")
    return Path(database_url[len(prefix) :])
