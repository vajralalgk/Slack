"""Content-related database models (movies, series, episodes)."""

import uuid
from datetime import datetime, timezone

from sqlalchemy import Boolean, Column, DateTime, Enum, Float, ForeignKey, Integer, String, Table, Text
from sqlalchemy.dialects.postgresql import ARRAY, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from src.core.database import Base

# Many-to-many relationship between content and genres
content_genres = Table(
    "content_genres",
    Base.metadata,
    Column("content_id", UUID(as_uuid=True), ForeignKey("content.id"), primary_key=True),
    Column("genre_id", UUID(as_uuid=True), ForeignKey("genres.id"), primary_key=True),
)


class Genre(Base):
    """Content genre (Action, Comedy, Drama, etc.)."""

    __tablename__ = "genres"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name: Mapped[str] = mapped_column(String(100), unique=True, nullable=False)
    slug: Mapped[str] = mapped_column(String(100), unique=True, nullable=False)

    # Relationships
    content: Mapped[list["Content"]] = relationship("Content", secondary=content_genres, back_populates="genres")


class Content(Base):
    """Movie or TV series content."""

    __tablename__ = "content"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    title: Mapped[str] = mapped_column(String(500), nullable=False, index=True)
    slug: Mapped[str] = mapped_column(String(500), unique=True, nullable=False)
    description: Mapped[str] = mapped_column(Text, nullable=False)
    content_type: Mapped[str] = mapped_column(
        Enum("movie", "series", name="content_type"), nullable=False
    )
    release_year: Mapped[int] = mapped_column(Integer, nullable=False)
    maturity_rating: Mapped[str] = mapped_column(
        Enum("G", "PG", "PG-13", "R", "NC-17", name="content_maturity"), default="PG-13"
    )
    duration_minutes: Mapped[int | None] = mapped_column(Integer)  # For movies
    thumbnail_url: Mapped[str | None] = mapped_column(String(500))
    banner_url: Mapped[str | None] = mapped_column(String(500))
    trailer_url: Mapped[str | None] = mapped_column(String(500))
    video_url: Mapped[str | None] = mapped_column(String(500))  # For movies (direct stream URL)
    average_rating: Mapped[float] = mapped_column(Float, default=0.0)
    total_views: Mapped[int] = mapped_column(Integer, default=0)
    is_featured: Mapped[bool] = mapped_column(Boolean, default=False)
    is_original: Mapped[bool] = mapped_column(Boolean, default=False)  # Netflix Original
    cast: Mapped[list[str] | None] = mapped_column(ARRAY(String))
    director: Mapped[str | None] = mapped_column(String(255))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc)
    )

    # Relationships
    genres: Mapped[list["Genre"]] = relationship("Genre", secondary=content_genres, back_populates="content")
    seasons: Mapped[list["Season"]] = relationship("Season", back_populates="content", cascade="all, delete-orphan")


class Season(Base):
    """TV series season."""

    __tablename__ = "seasons"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    content_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("content.id"), nullable=False)
    season_number: Mapped[int] = mapped_column(Integer, nullable=False)
    title: Mapped[str | None] = mapped_column(String(500))
    release_year: Mapped[int | None] = mapped_column(Integer)

    # Relationships
    content: Mapped["Content"] = relationship("Content", back_populates="seasons")
    episodes: Mapped[list["Episode"]] = relationship("Episode", back_populates="season", cascade="all, delete-orphan")


class Episode(Base):
    """Individual episode of a TV series."""

    __tablename__ = "episodes"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    season_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("seasons.id"), nullable=False)
    episode_number: Mapped[int] = mapped_column(Integer, nullable=False)
    title: Mapped[str] = mapped_column(String(500), nullable=False)
    description: Mapped[str | None] = mapped_column(Text)
    duration_minutes: Mapped[int] = mapped_column(Integer, nullable=False)
    thumbnail_url: Mapped[str | None] = mapped_column(String(500))
    video_url: Mapped[str] = mapped_column(String(500), nullable=False)
    air_date: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    # Relationships
    season: Mapped["Season"] = relationship("Season", back_populates="episodes")
