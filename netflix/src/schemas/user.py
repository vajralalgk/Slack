"""User-related request/response schemas."""

import uuid
from datetime import datetime

from pydantic import BaseModel, EmailStr, Field


class UserRegister(BaseModel):
    """Schema for user registration."""

    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
    full_name: str = Field(min_length=1, max_length=255)


class UserLogin(BaseModel):
    """Schema for user login."""

    email: EmailStr
    password: str


class UserResponse(BaseModel):
    """Schema for user response."""

    id: uuid.UUID
    email: str
    full_name: str
    is_active: bool
    is_verified: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class TokenResponse(BaseModel):
    """Schema for authentication token response."""

    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class ProfileCreate(BaseModel):
    """Schema for creating a profile."""

    name: str = Field(min_length=1, max_length=100)
    is_kids: bool = False
    language: str = "en"
    maturity_level: str = "R"


class ProfileResponse(BaseModel):
    """Schema for profile response."""

    id: uuid.UUID
    name: str
    avatar_url: str | None
    is_kids: bool
    language: str
    maturity_level: str
    created_at: datetime

    model_config = {"from_attributes": True}
