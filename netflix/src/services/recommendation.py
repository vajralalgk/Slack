"""Content recommendation engine."""

import uuid

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from src.core.logging import get_logger
from src.models.content import Content, Genre, content_genres
from src.models.user import WatchHistory

logger = get_logger(__name__)


class RecommendationService:
    """Generates personalized content recommendations."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def get_because_you_watched(self, profile_id: uuid.UUID, limit: int = 10) -> list[Content]:
        """Recommend content based on recently watched items (genre-based)."""
        # Get genres from recently watched content
        watched_genres_query = (
            select(Genre.id)
            .join(content_genres)
            .join(Content, Content.id == content_genres.c.content_id)
            .join(WatchHistory, WatchHistory.content_id == Content.id)
            .where(WatchHistory.profile_id == profile_id)
            .distinct()
        )
        result = await self.db.execute(watched_genres_query)
        genre_ids = [row[0] for row in result.all()]

        if not genre_ids:
            return await self.get_trending(limit)

        # Get watched content IDs to exclude
        watched_query = select(WatchHistory.content_id).where(WatchHistory.profile_id == profile_id)
        watched_result = await self.db.execute(watched_query)
        watched_ids = [row[0] for row in watched_result.all()]

        # Find similar content by genre, excluding already watched
        query = (
            select(Content)
            .join(content_genres)
            .where(content_genres.c.genre_id.in_(genre_ids))
            .where(Content.id.notin_(watched_ids))
            .order_by(Content.average_rating.desc())
            .limit(limit)
        )
        result = await self.db.execute(query)
        return list(result.scalars().all())

    async def get_trending(self, limit: int = 10) -> list[Content]:
        """Get trending content based on view count."""
        query = select(Content).order_by(Content.total_views.desc()).limit(limit)
        result = await self.db.execute(query)
        return list(result.scalars().all())

    async def get_top_rated(self, limit: int = 10) -> list[Content]:
        """Get top-rated content."""
        query = select(Content).where(Content.average_rating > 0).order_by(Content.average_rating.desc()).limit(limit)
        result = await self.db.execute(query)
        return list(result.scalars().all())

    async def get_new_releases(self, limit: int = 10) -> list[Content]:
        """Get recently added content."""
        query = select(Content).order_by(Content.created_at.desc()).limit(limit)
        result = await self.db.execute(query)
        return list(result.scalars().all())

    async def get_continue_watching(self, profile_id: uuid.UUID, limit: int = 10) -> list[dict]:
        """Get content the user started but hasn't finished."""
        query = (
            select(WatchHistory, Content)
            .join(Content, WatchHistory.content_id == Content.id)
            .where(WatchHistory.profile_id == profile_id, WatchHistory.completed.is_(False))
            .order_by(WatchHistory.watched_at.desc())
            .limit(limit)
        )
        result = await self.db.execute(query)
        rows = result.all()

        return [
            {
                "content": content,
                "progress_seconds": history.progress_seconds,
                "last_watched": history.watched_at,
            }
            for history, content in rows
        ]

    async def get_homepage_rows(self, profile_id: uuid.UUID) -> list[dict]:
        """Build the complete homepage content rows."""
        rows = []

        # Continue Watching
        continue_watching = await self.get_continue_watching(profile_id)
        if continue_watching:
            rows.append({"title": "Continue Watching", "items": continue_watching})

        # Trending Now
        trending = await self.get_trending()
        if trending:
            rows.append({"title": "Trending Now", "items": trending})

        # Because You Watched
        recommendations = await self.get_because_you_watched(profile_id)
        if recommendations:
            rows.append({"title": "Recommended For You", "items": recommendations})

        # Top Rated
        top_rated = await self.get_top_rated()
        if top_rated:
            rows.append({"title": "Top Rated", "items": top_rated})

        # New Releases
        new_releases = await self.get_new_releases()
        if new_releases:
            rows.append({"title": "New Releases", "items": new_releases})

        return rows
