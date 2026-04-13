import uuid

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.core.db import get_db_session
from app.repositories.users import user_repository
from app.schemas.moments import (
    MomentAuthorSummary,
    MomentCreateRequest,
    MomentListItem,
    MomentListResponse,
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


def _build_author_summary(db: Session, user_id: uuid.UUID) -> MomentAuthorSummary:
    user = user_repository.get(db, user_id)
    if user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="user_not_found")
    return MomentAuthorSummary(id=user.id, email=user.email, username=user.username)


@router.post("", response_model=MomentResponse, status_code=status.HTTP_201_CREATED)
def create_moment(payload: MomentCreateRequest, db: Session = Depends(get_db_session)) -> MomentResponse:
    try:
        moment = moment_service.create_moment(db, payload.author_user_id, payload.caption_text)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc))
    return MomentResponse.model_validate(moment)


def _build_moment_list_response(db: Session, moments: list) -> MomentListResponse:
    items = [
        MomentListItem(
            id=moment.id,
            caption_text=moment.caption_text,
            visibility_scope=moment.visibility_scope,
            deleted_at=moment.deleted_at,
            author=_build_author_summary(db, moment.author_user_id),
            media_items=[MomentMediaResponse.model_validate(media_item) for media_item in moment_service.list_media(db, moment.id)],
        )
        for moment in moments
    ]
    return MomentListResponse(count=len(items), items=items)


@router.get("", response_model=MomentListResponse)
def list_moments(author_user_id: uuid.UUID = Query(...), db: Session = Depends(get_db_session)) -> MomentListResponse:
    try:
        moments = moment_service.list_moments(db, author_user_id=author_user_id)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc))

    return _build_moment_list_response(db, moments)


@router.get("/feed", response_model=MomentListResponse)
def list_private_feed(viewer_user_id: uuid.UUID = Query(...), db: Session = Depends(get_db_session)) -> MomentListResponse:
    try:
        moments = moment_service.list_private_feed(db, viewer_user_id=viewer_user_id)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc))

    return _build_moment_list_response(db, moments)


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
