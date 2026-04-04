import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.db import get_db_session
from app.schemas.moments import (
    MomentCreateRequest,
    MomentMediaCreateRequest,
    MomentMediaListResponse,
    MomentMediaResponse,
    MomentReactionCreateRequest,
    MomentReactionListResponse,
    MomentReactionResponse,
    MomentResponse,
    MomentUpdateRequest,
)
from app.services.moments import moment_service

router = APIRouter(prefix="/moments", tags=["moments"])


@router.post("", response_model=MomentResponse, status_code=status.HTTP_201_CREATED)
def create_moment(payload: MomentCreateRequest, db: Session = Depends(get_db_session)) -> MomentResponse:
    try:
        moment = moment_service.create_moment(db, payload.author_user_id, payload.caption_text)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc))
    return MomentResponse.model_validate(moment)


@router.patch("/{moment_id}", response_model=MomentResponse)
def update_moment(
    moment_id: uuid.UUID,
    payload: MomentUpdateRequest,
    db: Session = Depends(get_db_session),
) -> MomentResponse:
    try:
        moment = moment_service.update_moment(db, moment_id, payload.caption_text)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc))
    return MomentResponse.model_validate(moment)


@router.get("/{moment_id}", response_model=MomentResponse)
def get_moment(moment_id: uuid.UUID, db: Session = Depends(get_db_session)) -> MomentResponse:
    moment = moment_service.get_moment(db, moment_id)
    if moment is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="moment_not_found")
    return MomentResponse.model_validate(moment)


@router.delete("/{moment_id}", response_model=MomentResponse)
def delete_moment(moment_id: uuid.UUID, db: Session = Depends(get_db_session)) -> MomentResponse:
    try:
        moment = moment_service.delete_moment(db, moment_id)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc))
    return MomentResponse.model_validate(moment)


@router.post("/{moment_id}/media", response_model=MomentMediaResponse, status_code=status.HTTP_201_CREATED)
def create_moment_media(
    moment_id: uuid.UUID,
    payload: MomentMediaCreateRequest,
    db: Session = Depends(get_db_session),
) -> MomentMediaResponse:
    try:
        media = moment_service.create_media(
            db,
            moment_id=moment_id,
            media_type=payload.media_type,
            storage_key=payload.storage_key,
            mime_type=payload.mime_type,
            width=payload.width,
            height=payload.height,
        )
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc))
    return MomentMediaResponse.model_validate(media)


@router.get("/{moment_id}/media", response_model=MomentMediaListResponse)
def list_moment_media(moment_id: uuid.UUID, db: Session = Depends(get_db_session)) -> MomentMediaListResponse:
    try:
        media_items = moment_service.list_media(db, moment_id)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc))
    items = [MomentMediaResponse.model_validate(media_item) for media_item in media_items]
    return MomentMediaListResponse(count=len(items), items=items)


@router.post("/{moment_id}/reactions", response_model=MomentReactionResponse, status_code=status.HTTP_201_CREATED)
def create_moment_reaction(
    moment_id: uuid.UUID,
    payload: MomentReactionCreateRequest,
    db: Session = Depends(get_db_session),
) -> MomentReactionResponse:
    try:
        reaction = moment_service.create_reaction(
            db,
            moment_id=moment_id,
            user_id=payload.user_id,
            reaction_type=payload.reaction_type,
        )
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc))
    return MomentReactionResponse.model_validate(reaction)


@router.get("/{moment_id}/reactions", response_model=MomentReactionListResponse)
def list_moment_reactions(moment_id: uuid.UUID, db: Session = Depends(get_db_session)) -> MomentReactionListResponse:
    try:
        reactions = moment_service.list_reactions(db, moment_id)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc))
    items = [MomentReactionResponse.model_validate(reaction) for reaction in reactions]
    return MomentReactionListResponse(count=len(items), items=items)
