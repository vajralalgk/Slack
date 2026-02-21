"""Tests for health check endpoints."""

import pytest
from httpx import AsyncClient


@pytest.mark.unit
async def test_root_endpoint(client: AsyncClient):
    """Test the root endpoint returns app info."""
    response = await client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert "name" in data
    assert "version" in data


@pytest.mark.unit
async def test_health_check(client: AsyncClient):
    """Test the health check endpoint."""
    response = await client.get("/api/v1/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"


@pytest.mark.unit
async def test_readiness_check(client: AsyncClient):
    """Test the readiness check endpoint."""
    response = await client.get("/api/v1/ready")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ready"
