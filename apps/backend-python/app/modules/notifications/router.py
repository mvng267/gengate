import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.db import get_db_session
from app.schemas.notifications import NotificationCreateRequest, NotificationListResponse, NotificationResponse
from app.services.notifications import notification_service

router = APIRouter(prefix="/notifications", tags=["notifications"])


def to_notification_response(notification) -> NotificationResponse:
    return NotificationResponse(
        id=notification.id,
        user_id=notification.user_id,
        notification_type=notification.notification_type,
        payload_json=notification.payload_json,
        read_at=notification.read_at,
    )


@router.post("", response_model=NotificationResponse, status_code=status.HTTP_201_CREATED)
def create_notification(
    payload: NotificationCreateRequest,
    db: Session = Depends(get_db_session),
) -> NotificationResponse:
    try:
        notification = notification_service.create_notification(
            db,
            user_id=payload.user_id,
            notification_type=payload.notification_type,
            payload_json=payload.payload_json,
        )
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc))
    return to_notification_response(notification)


@router.get("/{user_id}", response_model=NotificationListResponse)
def list_notifications(user_id: uuid.UUID, db: Session = Depends(get_db_session)) -> NotificationListResponse:
    try:
        notifications = notification_service.list_notifications(db, user_id)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc))
    items = [to_notification_response(notification) for notification in notifications]
    return NotificationListResponse(count=len(items), items=items)


@router.get("/item/{notification_id}", response_model=NotificationResponse)
def get_notification(notification_id: uuid.UUID, db: Session = Depends(get_db_session)) -> NotificationResponse:
    notification = notification_service.get_notification(db, notification_id)
    if notification is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="notification_not_found")
    return to_notification_response(notification)


@router.patch("/{notification_id}/read", response_model=NotificationResponse)
def mark_notification_read(notification_id: uuid.UUID, db: Session = Depends(get_db_session)) -> NotificationResponse:
    try:
        notification = notification_service.mark_read(db, notification_id)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc))
    return to_notification_response(notification)


@router.patch("/{notification_id}/unread", response_model=NotificationResponse)
def mark_notification_unread(notification_id: uuid.UUID, db: Session = Depends(get_db_session)) -> NotificationResponse:
    try:
        notification = notification_service.mark_unread(db, notification_id)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc))
    return to_notification_response(notification)


@router.delete("/{notification_id}", response_model=NotificationResponse)
def delete_notification(notification_id: uuid.UUID, db: Session = Depends(get_db_session)) -> NotificationResponse:
    try:
        notification = notification_service.delete_notification(db, notification_id)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc))
    return to_notification_response(notification)
