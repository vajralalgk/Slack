"""Watchlist and watch history endpoints."""

import uuid

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.api.deps import get_current_user
from src.core.database import get_db
from src.models.content import Content
from src.models.user import User, WatchHistory, Watchlist
from src.schemas.content import WatchHistoryCreate, WatchHistoryResponse

router = APIRouter(prefix="/profiles/{profile_id}", tags=["Watchlist & History"])


@router.get("/watchlist", response_model=list[dict])
async def get_watchlist(
    profile_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> list[dict]:
    """Get the user's 'My List'."""
    query = (
        select(Watchlist, Content)
        .join(Content, Watchlist.content_id == Content.id)
        .where(Watchlist.profile_id == profile_id)
        .order_by(Watchlist.added_at.desc())
    )
    result = await db.execute(query)
    rows = result.all()
    return [
        {
            "id": str(wl.id),
            "content_id": str(wl.content_id),
            "title": content.title,
            "thumbnail_url": content.thumbnail_url,
            "content_type": content.content_type,
            "added_at": wl.added_at.isoformat(),
        }
        for wl, content in rows
    ]


@router.post("/watchlist/{content_id}", status_code=status.HTTP_201_CREATED)
async def add_to_watchlist(
    profile_id: uuid.UUID,
    content_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> dict:
    """Add content to 'My List'."""
    # Verify content exists
    content = await db.get(Content, content_id)
    if not content:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Content not found")

    # Check if already in watchlist
    result = await db.execute(
        select(Watchlist).where(Watchlist.profile_id == profile_id, Watchlist.content_id == content_id)
    )
    if result.scalar_one_or_none():
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Already in watchlist")

    entry = Watchlist(profile_id=profile_id, content_id=content_id)
    db.add(entry)
    await db.flush()
    return {"message": "Added to watchlist"}


@router.delete("/watchlist/{content_id}", status_code=status.HTTP_204_NO_CONTENT)
async def remove_from_watchlist(
    profile_id: uuid.UUID,
    content_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> None:
    """Remove content from 'My List'."""
    result = await db.execute(
        select(Watchlist).where(Watchlist.profile_id == profile_id, Watchlist.content_id == content_id)
    )
    entry = result.scalar_one_or_none()
    if not entry:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Not in watchlist")

    await db.delete(entry)


@router.post("/history", response_model=WatchHistoryResponse)
async def record_watch_progress(
    profile_id: uuid.UUID,
    data: WatchHistoryCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> WatchHistory:
    """Record or update watch progress."""
    # Check for existing entry
    query = select(WatchHistory).where(
        WatchHistory.profile_id == profile_id,
        WatchHistory.content_id == data.content_id,
    )
    if data.episode_id:
        query = query.where(WatchHistory.episode_id == data.episode_id)

    result = await db.execute(query)
    entry = result.scalar_one_or_none()

    if entry:
        entry.progress_seconds = data.progress_seconds
        entry.completed = data.completed
    else:
        entry = WatchHistory(
            profile_id=profile_id,
            content_id=data.content_id,
            episode_id=data.episode_id,
            progress_seconds=data.progress_seconds,
            completed=data.completed,
        )
        db.add(entry)

    await db.flush()
    return entry


@router.get("/history", response_model=list[WatchHistoryResponse])
async def get_watch_history(
    profile_id: uuid.UUID,
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> list[WatchHistory]:
    """Get the profile's watch history."""
    query = (
        select(WatchHistory)
        .where(WatchHistory.profile_id == profile_id)
        .order_by(WatchHistory.watched_at.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
    )
    result = await db.execute(query)
    return list(result.scalars().all())
