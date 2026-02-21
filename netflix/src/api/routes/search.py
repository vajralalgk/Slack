"""Content search endpoints."""

from fastapi import APIRouter, Depends, Query
from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from src.core.database import get_db
from src.models.content import Content, Genre, content_genres
from src.schemas.content import ContentSummary

router = APIRouter(prefix="/search", tags=["Search"])


@router.get("/", response_model=list[ContentSummary])
async def search_content(
    q: str = Query(min_length=1, max_length=200),
    content_type: str | None = None,
    genre: str | None = None,
    year_from: int | None = None,
    year_to: int | None = None,
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
) -> list[Content]:
    """Search for content by title, description, cast, or director."""
    search_term = f"%{q}%"

    query = select(Content).where(
        or_(
            Content.title.ilike(search_term),
            Content.description.ilike(search_term),
            Content.director.ilike(search_term),
        )
    )

    if content_type:
        query = query.where(Content.content_type == content_type)
    if genre:
        query = query.join(content_genres).join(Genre).where(Genre.slug == genre)
    if year_from:
        query = query.where(Content.release_year >= year_from)
    if year_to:
        query = query.where(Content.release_year <= year_to)

    query = query.order_by(Content.average_rating.desc())
    query = query.offset((page - 1) * page_size).limit(page_size)

    result = await db.execute(query)
    return list(result.scalars().all())
