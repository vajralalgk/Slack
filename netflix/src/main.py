"""Netflix Streaming Platform - Application Entry Point."""

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from src.api.routes import auth, content, health, profiles, search, watchlist
from src.core.config import get_settings
from src.core.logging import setup_logging

settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application startup and shutdown lifecycle."""
    setup_logging()
    yield


app = FastAPI(
    title=settings.app_name,
    description="Netflix-style streaming platform with content management, user profiles, and recommendations",
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register routes
app.include_router(health.router, prefix="/api/v1")
app.include_router(auth.router, prefix="/api/v1")
app.include_router(content.router, prefix="/api/v1")
app.include_router(profiles.router, prefix="/api/v1")
app.include_router(watchlist.router, prefix="/api/v1")
app.include_router(search.router, prefix="/api/v1")


@app.get("/")
async def root() -> dict:
    """Root endpoint."""
    return {
        "name": settings.app_name,
        "version": "1.0.0",
        "docs": "/docs",
    }
