from fastapi import FastAPI

from app.db import init_db
from app.routers import admin, channels, oauth


def create_app() -> FastAPI:
    init_db()
    app = FastAPI(
        title="Mini-IPTV Backend",
        docs_url="/api/docs",
        redoc_url="/api/redoc",
        openapi_url="/api/openapi.json",
    )
    app.include_router(oauth.router)
    app.include_router(channels.router)
    app.include_router(admin.router)

    @app.get("/api/health")
    def healthcheck():
        return {"status": "ok"}

    return app
