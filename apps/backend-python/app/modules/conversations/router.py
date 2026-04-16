import uuid

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.core.db import get_db_session
from app.schemas.conversations import (
    ConversationCreateRequest,
    ConversationListResponse,
    ConversationMemberCreateRequest,
    ConversationMemberListResponse,
    ConversationMemberReadCursorUpdateRequest,
    ConversationMemberResponse,
    ConversationResponse,
    DirectConversationGetOrCreateRequest,
    DirectConversationListResponse,
    DirectConversationResponse,
)
from app.services.conversations import conversation_service

router = APIRouter(prefix="/conversations", tags=["conversations"])


def to_conversation_response(conversation) -> ConversationResponse:
    return ConversationResponse(
        id=conversation.id,
        conversation_type=conversation.conversation_type,
    )


def to_member_response(member) -> ConversationMemberResponse:
    return ConversationMemberResponse(
        id=member.id,
        conversation_id=member.conversation_id,
        user_id=member.user_id,
        last_read_message_id=member.last_read_message_id,
    )


def to_direct_conversation_response(conversation, members, latest_message=None) -> DirectConversationResponse:
    return DirectConversationResponse(
        id=conversation.id,
        conversation_type=conversation.conversation_type,
        member_user_ids=[member.user_id for member in members],
        latest_message_id=latest_message.id if latest_message is not None else None,
        latest_message_sender_user_id=latest_message.sender_user_id if latest_message is not None else None,
        latest_message_preview=(
            latest_message.encrypted_payload_blob.decode("utf-8") if latest_message is not None else None
        ),
        latest_message_created_at=latest_message.created_at if latest_message is not None else None,
    )


@router.post("", response_model=ConversationResponse, status_code=status.HTTP_201_CREATED)
def create_conversation(
    payload: ConversationCreateRequest,
    db: Session = Depends(get_db_session),
) -> ConversationResponse:
    conversation = conversation_service.create_conversation(db, payload.conversation_type)
    return to_conversation_response(conversation)


@router.get("", response_model=ConversationListResponse)
def list_conversations(db: Session = Depends(get_db_session)) -> ConversationListResponse:
    conversations = conversation_service.list_conversations(db)
    items = [to_conversation_response(conversation) for conversation in conversations]
    return ConversationListResponse(count=len(items), items=items)


@router.post("/direct", response_model=DirectConversationResponse, status_code=status.HTTP_201_CREATED)
def get_or_create_direct_conversation(
    payload: DirectConversationGetOrCreateRequest,
    db: Session = Depends(get_db_session),
) -> DirectConversationResponse:
    try:
        conversation, members = conversation_service.get_or_create_direct_conversation(
            db,
            user_a_id=payload.user_a_id,
            user_b_id=payload.user_b_id,
        )
    except ValueError as exc:
        code = str(exc)
        status_code = status.HTTP_400_BAD_REQUEST if code == "invalid_direct_members" else status.HTTP_404_NOT_FOUND
        raise HTTPException(status_code=status_code, detail=code)
    return to_direct_conversation_response(conversation, members)


@router.get("/direct", response_model=DirectConversationListResponse)
def list_direct_conversations_for_user(
    user_id: uuid.UUID = Query(...),
    db: Session = Depends(get_db_session),
) -> DirectConversationListResponse:
    try:
        rows = conversation_service.list_direct_conversations_for_user(db, user_id=user_id)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc))

    items = [
        to_direct_conversation_response(conversation, members, latest_message)
        for conversation, members, latest_message in rows
    ]
    return DirectConversationListResponse(count=len(items), items=items)


@router.post("/{conversation_id}/members", response_model=ConversationMemberResponse, status_code=status.HTTP_201_CREATED)
def create_member(
    conversation_id: uuid.UUID,
    payload: ConversationMemberCreateRequest,
    db: Session = Depends(get_db_session),
) -> ConversationMemberResponse:
    try:
        member = conversation_service.create_member(db, conversation_id, payload.user_id)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc))
    return to_member_response(member)


@router.get("/{conversation_id}/members", response_model=ConversationMemberListResponse)
def list_members(
    conversation_id: uuid.UUID,
    db: Session = Depends(get_db_session),
) -> ConversationMemberListResponse:
    try:
        members = conversation_service.list_members(db, conversation_id)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc))
    items = [to_member_response(member) for member in members]
    return ConversationMemberListResponse(count=len(items), items=items)


@router.patch("/{conversation_id}/members/{user_id}/read-cursor", response_model=ConversationMemberResponse)
def update_member_read_cursor(
    conversation_id: uuid.UUID,
    user_id: uuid.UUID,
    payload: ConversationMemberReadCursorUpdateRequest,
    db: Session = Depends(get_db_session),
) -> ConversationMemberResponse:
    try:
        member = conversation_service.update_direct_member_read_cursor(
            db,
            conversation_id=conversation_id,
            user_id=user_id,
            last_read_message_id=payload.last_read_message_id,
        )
    except ValueError as exc:
        code = str(exc)
        if code in {"conversation_not_direct", "message_conversation_mismatch"}:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=code)
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=code)
    return to_member_response(member)
