import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.db import get_db_session
from app.schemas.conversations import (
    ConversationCreateRequest,
    ConversationListResponse,
    ConversationMemberCreateRequest,
    ConversationMemberListResponse,
    ConversationMemberResponse,
    ConversationResponse,
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
