import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.db import get_db_session
from app.schemas.friendships import (
    BlockCreateRequest,
    BlockListResponse,
    BlockResponse,
    FriendRequestCreateRequest,
    FriendRequestResponse,
    FriendshipResponse,
)
from app.services.blocks import block_service
from app.services.friendships import friendship_service

router = APIRouter(prefix="/friends", tags=["friendships"])


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


@router.post("/requests/{request_id}/accept", response_model=FriendshipResponse, status_code=status.HTTP_201_CREATED)
def accept_friend_request(request_id: uuid.UUID, db: Session = Depends(get_db_session)) -> FriendshipResponse:
    try:
        friendship = friendship_service.accept_request(db, request_id)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc))
    return FriendshipResponse.model_validate(friendship)


@router.get("", response_model=dict)
def list_friendships(db: Session = Depends(get_db_session)) -> dict[str, int]:
    friendships = friendship_service.list_friendships(db)
    return {"count": len(friendships)}


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
