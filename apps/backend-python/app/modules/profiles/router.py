import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.db import get_db_session
from app.schemas.profiles import ProfileResponse, ProfileUpsertRequest
from app.services.profiles import profile_service

router = APIRouter(prefix="/profiles", tags=["profiles"])


@router.post("", response_model=ProfileResponse, status_code=status.HTTP_201_CREATED)
def upsert_profile(payload: ProfileUpsertRequest, db: Session = Depends(get_db_session)) -> ProfileResponse:
    try:
        profile = profile_service.upsert_profile(
            db,
            user_id=payload.user_id,
            display_name=payload.display_name,
            bio=payload.bio,
            avatar_url=payload.avatar_url,
        )
    except ValueError:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="user_not_found")

    return ProfileResponse.model_validate(profile)


@router.get("/{user_id}", response_model=ProfileResponse)
def get_profile(user_id: uuid.UUID, db: Session = Depends(get_db_session)) -> ProfileResponse:
    profile = profile_service.get_by_user_id(db, user_id)
    if profile is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="profile_not_found")
    return ProfileResponse.model_validate(profile)
