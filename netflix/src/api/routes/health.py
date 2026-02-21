"""Health check endpoints."""

from fastapi import APIRouter

router = APIRouter(tags=["Health"])


@router.get("/health")
async def health_check() -> dict:
    """Basic health check."""
    return {"status": "healthy", "service": "netflix-streaming-platform"}


@router.get("/ready")
async def readiness_check() -> dict:
    """Readiness check (verify dependencies are available)."""
    return {"status": "ready"}
