"""Tests for content endpoints."""

import pytest
from httpx import AsyncClient


@pytest.mark.unit
async def test_list_content(client: AsyncClient):
    """Test listing content returns empty list initially."""
    response = await client.get("/api/v1/content/")
    assert response.status_code == 200
    assert isinstance(response.json(), list)


@pytest.mark.unit
async def test_get_featured_content(client: AsyncClient):
    """Test getting featured content."""
    response = await client.get("/api/v1/content/featured")
    assert response.status_code == 200
    assert isinstance(response.json(), list)


@pytest.mark.unit
async def test_get_originals(client: AsyncClient):
    """Test getting Netflix originals."""
    response = await client.get("/api/v1/content/originals")
    assert response.status_code == 200
    assert isinstance(response.json(), list)


@pytest.mark.unit
async def test_get_genres(client: AsyncClient):
    """Test listing genres."""
    response = await client.get("/api/v1/content/genres")
    assert response.status_code == 200
    assert isinstance(response.json(), list)


@pytest.mark.unit
async def test_content_not_found(client: AsyncClient):
    """Test 404 for non-existent content."""
    response = await client.get("/api/v1/content/non-existent-slug")
    assert response.status_code == 404


@pytest.mark.unit
async def test_search_content(client: AsyncClient):
    """Test content search."""
    response = await client.get("/api/v1/search/", params={"q": "test"})
    assert response.status_code == 200
    assert isinstance(response.json(), list)
