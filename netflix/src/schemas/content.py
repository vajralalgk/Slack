"""Content-related request/response schemas."""

import uuid
from datetime import datetime

from pydantic import BaseModel, Field


class GenreResponse(BaseModel):
    """Schema for genre response."""

    id: uuid.UUID
    name: str
    slug: str

    model_config = {"from_attributes": True}


class EpisodeResponse(BaseModel):
    """Schema for episode response."""

    id: uuid.UUID
    episode_number: int
    title: str
    description: str | None
    duration_minutes: int
    thumbnail_url: str | None
    air_date: datetime | None

    model_config = {"from_attributes": True}


class SeasonResponse(BaseModel):
    """Schema for season response."""

    id: uuid.UUID
    season_number: int
    title: str | None
    release_year: int | None
    episodes: list[EpisodeResponse] = []

    model_config = {"from_attributes": True}


class ContentSummary(BaseModel):
    """Compact content summary for listing pages."""

    id: uuid.UUID
    title: str
    slug: str
    content_type: str
    release_year: int
    maturity_rating: str
    thumbnail_url: str | None
    average_rating: float
    is_original: bool

    model_config = {"from_attributes": True}


class ContentDetail(BaseModel):
    """Full content detail for the detail page."""

    id: uuid.UUID
    title: str
    slug: str
    description: str
    content_type: str
    release_year: int
    maturity_rating: str
    duration_minutes: int | None
    thumbnail_url: str | None
    banner_url: str | None
    trailer_url: str | None
    average_rating: float
    total_views: int
    is_featured: bool
    is_original: bool
    cast: list[str] | None
    director: str | None
    genres: list[GenreResponse] = []
    seasons: list[SeasonResponse] = []
    created_at: datetime

    model_config = {"from_attributes": True}


class ContentCreate(BaseModel):
    """Schema for creating content (admin)."""

    title: str = Field(min_length=1, max_length=500)
    description: str = Field(min_length=1)
    content_type: str = Field(pattern="^(movie|series)$")
    release_year: int = Field(ge=1900, le=2030)
    maturity_rating: str = "PG-13"
    duration_minutes: int | None = None
    cast: list[str] | None = None
    director: str | None = None
    genre_ids: list[uuid.UUID] = []
    is_original: bool = False


class WatchHistoryCreate(BaseModel):
    """Schema for recording watch progress."""

    content_id: uuid.UUID
    episode_id: uuid.UUID | None = None
    progress_seconds: int = 0
    completed: bool = False


class WatchHistoryResponse(BaseModel):
    """Schema for watch history response."""

    id: uuid.UUID
    content_id: uuid.UUID
    episode_id: uuid.UUID | None
    progress_seconds: int
    completed: bool
    rating: int | None
    watched_at: datetime

    model_config = {"from_attributes": True}


class SearchQuery(BaseModel):
    """Schema for content search."""

    query: str = Field(min_length=1, max_length=200)
    genre: str | None = None
    content_type: str | None = None
    year_from: int | None = None
    year_to: int | None = None
    page: int = Field(default=1, ge=1)
    page_size: int = Field(default=20, ge=1, le=100)
