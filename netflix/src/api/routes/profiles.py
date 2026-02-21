"""User profile management endpoints."""

import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.api.deps import get_current_user
from src.core.database import get_db
from src.models.user import Profile, User
from src.schemas.user import ProfileCreate, ProfileResponse

router = APIRouter(prefix="/profiles", tags=["Profiles"])

MAX_PROFILES_PER_USER = 5


@router.get("/", response_model=list[ProfileResponse])
async def list_profiles(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> list[Profile]:
    """List all profiles for the current user."""
    result = await db.execute(select(Profile).where(Profile.user_id == current_user.id).order_by(Profile.created_at))
    return list(result.scalars().all())


@router.post("/", response_model=ProfileResponse, status_code=status.HTTP_201_CREATED)
async def create_profile(
    data: ProfileCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> Profile:
    """Create a new profile (max 5 per account)."""
    result = await db.execute(select(Profile).where(Profile.user_id == current_user.id))
    existing_profiles = result.scalars().all()

    if len(existing_profiles) >= MAX_PROFILES_PER_USER:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Maximum of {MAX_PROFILES_PER_USER} profiles per account",
        )

    profile = Profile(
        user_id=current_user.id,
        name=data.name,
        is_kids=data.is_kids,
        language=data.language,
        maturity_level=data.maturity_level,
    )
    db.add(profile)
    await db.flush()
    return profile


@router.delete("/{profile_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_profile(
    profile_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> None:
    """Delete a profile."""
    result = await db.execute(
        select(Profile).where(Profile.id == profile_id, Profile.user_id == current_user.id)
    )
    profile = result.scalar_one_or_none()

    if not profile:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Profile not found")

    await db.delete(profile)
