"""Content browsing and management endpoints."""

import uuid

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from src.api.deps import get_current_user
from src.core.database import get_db
from src.models.content import Content, Genre, content_genres
from src.models.user import User
from src.schemas.content import ContentCreate, ContentDetail, ContentSummary

router = APIRouter(prefix="/content", tags=["Content"])


@router.get("/", response_model=list[ContentSummary])
async def list_content(
    content_type: str | None = None,
    genre: str | None = None,
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
) -> list[Content]:
    """List content with optional filters."""
    query = select(Content)

    if content_type:
        query = query.where(Content.content_type == content_type)
    if genre:
        query = query.join(content_genres).join(Genre).where(Genre.slug == genre)

    query = query.order_by(Content.created_at.desc())
    query = query.offset((page - 1) * page_size).limit(page_size)

    result = await db.execute(query)
    return list(result.scalars().all())


@router.get("/featured", response_model=list[ContentSummary])
async def get_featured_content(db: AsyncSession = Depends(get_db)) -> list[Content]:
    """Get featured/trending content for the homepage."""
    query = select(Content).where(Content.is_featured.is_(True)).order_by(Content.total_views.desc()).limit(10)
    result = await db.execute(query)
    return list(result.scalars().all())


@router.get("/originals", response_model=list[ContentSummary])
async def get_netflix_originals(
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
) -> list[Content]:
    """Get Netflix Original content."""
    query = (
        select(Content)
        .where(Content.is_original.is_(True))
        .order_by(Content.release_year.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
    )
    result = await db.execute(query)
    return list(result.scalars().all())


@router.get("/genres", response_model=list[dict])
async def list_genres(db: AsyncSession = Depends(get_db)) -> list[dict]:
    """List all available genres with content count."""
    query = (
        select(Genre.name, Genre.slug, func.count(content_genres.c.content_id).label("count"))
        .outerjoin(content_genres)
        .group_by(Genre.id)
        .order_by(Genre.name)
    )
    result = await db.execute(query)
    return [{"name": row.name, "slug": row.slug, "count": row.count} for row in result.all()]


@router.get("/{slug}", response_model=ContentDetail)
async def get_content_detail(slug: str, db: AsyncSession = Depends(get_db)) -> Content:
    """Get detailed content information by slug."""
    query = (
        select(Content)
        .options(selectinload(Content.genres), selectinload(Content.seasons))
        .where(Content.slug == slug)
    )
    result = await db.execute(query)
    content = result.scalar_one_or_none()

    if not content:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Content not found")

    return content


@router.post("/", response_model=ContentDetail, status_code=status.HTTP_201_CREATED)
async def create_content(
    data: ContentCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> Content:
    """Create new content (admin only)."""
    slug = data.title.lower().replace(" ", "-").replace("'", "")

    content = Content(
        title=data.title,
        slug=slug,
        description=data.description,
        content_type=data.content_type,
        release_year=data.release_year,
        maturity_rating=data.maturity_rating,
        duration_minutes=data.duration_minutes,
        cast=data.cast,
        director=data.director,
        is_original=data.is_original,
    )

    # Attach genres
    if data.genre_ids:
        result = await db.execute(select(Genre).where(Genre.id.in_(data.genre_ids)))
        content.genres = list(result.scalars().all())

    db.add(content)
    await db.flush()
    return content
