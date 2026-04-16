import uuid

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.core.db import get_db_session
from app.schemas.friendships import (
    BlockCreateRequest,
    BlockListResponse,
    BlockResponse,
    FriendRequestCreateRequest,
    FriendRequestItem,
    FriendRequestListResponse,
    FriendRequestResponse,
    FriendUserSummary,
    FriendshipItem,
    FriendshipListResponse,
    FriendshipResponse,
)
from app.repositories.users import user_repository
from app.services.blocks import block_service
from app.services.friendships import friendship_service

router = APIRouter(prefix="/friends", tags=["friendships"])


def _build_user_summary(db: Session, user_id: uuid.UUID) -> FriendUserSummary:
    user = user_repository.get(db, user_id)
    if user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="user_not_found")
    return FriendUserSummary(id=user.id, email=user.email, username=user.username)


@router.post("/requests", response_model=FriendRequestResponse, status_code=status.HTTP_201_CREATED)
def create_friend_request(
    payload: FriendRequestCreateRequest,
    db: Session = Depends(get_db_session),
) -> FriendRequestResponse:
    try:
        friend_request = friendship_service.create_request(
            db,
            requester_user_id=payload.requester_user_id,
            receiver_user_id=payload.receiver_user_id,
        )
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc))

    return FriendRequestResponse.model_validate(friend_request)


@router.get("/requests", response_model=FriendRequestListResponse)
def list_friend_requests(
    user_id: uuid.UUID = Query(...),
    status_filter: str | None = Query(default=None, alias="status"),
    db: Session = Depends(get_db_session),
) -> FriendRequestListResponse:
    try:
        requests = friendship_service.list_friend_requests(
            db,
            user_id=user_id,
            request_status=status_filter,
        )
    except ValueError as exc:
        code = str(exc)
        if code == "invalid_request_status":
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=code)
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=code)

    items = [
        FriendRequestItem(
            id=friend_request.id,
            status=friend_request.status,
            requester=_build_user_summary(db, friend_request.requester_user_id),
            receiver=_build_user_summary(db, friend_request.receiver_user_id),
        )
        for friend_request in requests
    ]
    return FriendRequestListResponse(count=len(items), items=items)


@router.post("/requests/{request_id}/accept", response_model=FriendshipResponse, status_code=status.HTTP_201_CREATED)
def accept_friend_request(request_id: uuid.UUID, db: Session = Depends(get_db_session)) -> FriendshipResponse:
    try:
        friendship = friendship_service.accept_request(db, request_id)
    except ValueError as exc:
        code = str(exc)
        status_code = status.HTTP_400_BAD_REQUEST if code == "request_not_pending" else status.HTTP_404_NOT_FOUND
        raise HTTPException(status_code=status_code, detail=code)
    return FriendshipResponse.model_validate(friendship)


@router.post("/requests/{request_id}/reject", response_model=FriendRequestResponse)
def reject_friend_request(request_id: uuid.UUID, db: Session = Depends(get_db_session)) -> FriendRequestResponse:
    try:
        friend_request = friendship_service.reject_request(db, request_id)
    except ValueError as exc:
        code = str(exc)
        status_code = status.HTTP_400_BAD_REQUEST if code == "request_not_pending" else status.HTTP_404_NOT_FOUND
        raise HTTPException(status_code=status_code, detail=code)
    return FriendRequestResponse.model_validate(friend_request)


@router.get("", response_model=FriendshipListResponse)
def list_friendships(user_id: uuid.UUID | None = Query(default=None), db: Session = Depends(get_db_session)) -> FriendshipListResponse:
    friendships = friendship_service.list_friendships(db, user_id=user_id)
    items = [
        FriendshipItem(
            id=friendship.id,
            state=friendship.state,
            user_a=_build_user_summary(db, friendship.user_a_id),
            user_b=_build_user_summary(db, friendship.user_b_id),
        )
        for friendship in friendships
    ]
    return FriendshipListResponse(count=len(items), items=items)


@router.post("/blocks", response_model=BlockResponse, status_code=status.HTTP_201_CREATED)
def create_block(payload: BlockCreateRequest, db: Session = Depends(get_db_session)) -> BlockResponse:
    try:
        block = block_service.create_block(db, payload.blocker_user_id, payload.blocked_user_id)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc))
    return BlockResponse.model_validate(block)


@router.get("/blocks/{blocker_user_id}", response_model=BlockListResponse)
def list_blocks(blocker_user_id: uuid.UUID, db: Session = Depends(get_db_session)) -> BlockListResponse:
    blocks = block_service.list_blocks(db, blocker_user_id)
    items = [BlockResponse.model_validate(block) for block in blocks]
    return BlockListResponse(count=len(items), items=items)
