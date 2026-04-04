import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.db import get_db_session
from app.schemas.message_attachments import (
    MessageAttachmentCreateRequest,
    MessageAttachmentListResponse,
    MessageAttachmentResponse,
)
from app.schemas.messages import (
    MessageCreateRequest,
    MessageDeviceKeyCreateRequest,
    MessageDeviceKeyListResponse,
    MessageDeviceKeyResponse,
    MessageListResponse,
    MessageResponse,
)
from app.services.message_attachments import message_attachment_service
from app.services.messages import message_service

router = APIRouter(prefix="/messages", tags=["messages"])


def to_message_response(message) -> MessageResponse:
    return MessageResponse(
        id=message.id,
        conversation_id=message.conversation_id,
        sender_user_id=message.sender_user_id,
        payload_text=message.encrypted_payload_blob.decode("utf-8"),
    )


@router.post("", response_model=MessageResponse, status_code=201)
def create_message(payload: MessageCreateRequest, db: Session = Depends(get_db_session)) -> MessageResponse:
    try:
        message = message_service.create_message(db, payload.sender_user_id, payload.payload_text)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc))
    return to_message_response(message)


@router.get("/{message_id}", response_model=MessageResponse)
def get_message(message_id: uuid.UUID, db: Session = Depends(get_db_session)) -> MessageResponse:
    message = message_service.get_message(db, message_id)
    if message is None:
        raise HTTPException(status_code=404, detail="message_not_found")
    return to_message_response(message)


@router.get("", response_model=MessageListResponse)
def list_messages(conversation_id: uuid.UUID | None = None, db: Session = Depends(get_db_session)) -> MessageListResponse:
    try:
        messages = message_service.list_messages(db, conversation_id)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc))
    items = [to_message_response(message) for message in messages]
    return MessageListResponse(count=len(items), items=items)


def to_message_device_key_response(device_key) -> MessageDeviceKeyResponse:
    return MessageDeviceKeyResponse(
        id=device_key.id,
        message_id=device_key.message_id,
        recipient_user_id=device_key.recipient_user_id,
        recipient_device_id=device_key.recipient_device_id,
        wrapped_message_key_blob=device_key.wrapped_message_key_blob.decode("utf-8"),
    )


@router.post("/{message_id}/device-keys", response_model=MessageDeviceKeyResponse, status_code=201)
def create_message_device_key(
    message_id: uuid.UUID,
    payload: MessageDeviceKeyCreateRequest,
    db: Session = Depends(get_db_session),
) -> MessageDeviceKeyResponse:
    try:
        device_key = message_service.create_message_device_key(
            db,
            message_id=message_id,
            recipient_user_id=payload.recipient_user_id,
            recipient_device_id=payload.recipient_device_id,
            wrapped_message_key_blob=payload.wrapped_message_key_blob,
        )
    except ValueError as exc:
        code = str(exc)
        if code == "message_device_key_exists":
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=code)
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=code)
    return to_message_device_key_response(device_key)


@router.get("/{message_id}/device-keys", response_model=MessageDeviceKeyListResponse)
def list_message_device_keys(
    message_id: uuid.UUID,
    db: Session = Depends(get_db_session),
) -> MessageDeviceKeyListResponse:
    try:
        message_device_keys = message_service.list_message_device_keys(db, message_id)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc))
    items = [to_message_device_key_response(device_key) for device_key in message_device_keys]
    return MessageDeviceKeyListResponse(count=len(items), items=items)


def to_attachment_response(attachment) -> MessageAttachmentResponse:
    return MessageAttachmentResponse(
        id=attachment.id,
        message_id=attachment.message_id,
        attachment_type=attachment.attachment_type,
        encrypted_attachment_blob=attachment.encrypted_attachment_blob.decode("utf-8"),
        storage_key=attachment.storage_key,
    )


@router.post("/{message_id}/attachments", response_model=MessageAttachmentResponse, status_code=201)
def create_attachment(
    message_id: uuid.UUID,
    payload: MessageAttachmentCreateRequest,
    db: Session = Depends(get_db_session),
) -> MessageAttachmentResponse:
    try:
        attachment = message_attachment_service.create_attachment(
            db,
            message_id=message_id,
            attachment_type=payload.attachment_type,
            encrypted_attachment_blob=payload.encrypted_attachment_blob,
            storage_key=payload.storage_key,
        )
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc))
    return to_attachment_response(attachment)


@router.get("/{message_id}/attachments", response_model=MessageAttachmentListResponse)
def list_attachments(message_id: uuid.UUID, db: Session = Depends(get_db_session)) -> MessageAttachmentListResponse:
    try:
        attachments = message_attachment_service.list_attachments(db, message_id)
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc))
    items = [to_attachment_response(attachment) for attachment in attachments]
    return MessageAttachmentListResponse(count=len(items), items=items)
