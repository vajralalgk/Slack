"""Tests for authentication endpoints."""

import pytest
from httpx import AsyncClient

from src.models.user import User


@pytest.mark.unit
async def test_register_user(client: AsyncClient):
    """Test user registration."""
    response = await client.post(
        "/api/v1/auth/register",
        json={
            "email": "newuser@netflix.com",
            "password": "SecurePass123!",
            "full_name": "New User",
        },
    )
    assert response.status_code == 201
    data = response.json()
    assert data["email"] == "newuser@netflix.com"
    assert data["full_name"] == "New User"
    assert "id" in data


@pytest.mark.unit
async def test_register_duplicate_email(client: AsyncClient, test_user: User):
    """Test registration with existing email fails."""
    response = await client.post(
        "/api/v1/auth/register",
        json={
            "email": "test@netflix.com",
            "password": "SecurePass123!",
            "full_name": "Duplicate User",
        },
    )
    assert response.status_code == 409


@pytest.mark.unit
async def test_login_success(client: AsyncClient, test_user: User):
    """Test successful login returns tokens."""
    response = await client.post(
        "/api/v1/auth/login",
        json={
            "email": "test@netflix.com",
            "password": "TestPass123!",
        },
    )
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert "refresh_token" in data
    assert data["token_type"] == "bearer"


@pytest.mark.unit
async def test_login_wrong_password(client: AsyncClient, test_user: User):
    """Test login with wrong password fails."""
    response = await client.post(
        "/api/v1/auth/login",
        json={
            "email": "test@netflix.com",
            "password": "WrongPassword!",
        },
    )
    assert response.status_code == 401
