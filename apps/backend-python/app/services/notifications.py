import uuid
from datetime import datetime, timezone

from sqlalchemy.orm import Session

from app.models.notifications import Notification
from app.repositories.notifications import notification_repository
from app.repositories.users import user_repository


class NotificationService:
    def create_notification(
        self,
        db: Session,
        user_id: uuid.UUID,
        notification_type: str,
        payload_json: dict,
    ) -> Notification:
        user = user_repository.get(db, user_id)
        if user is None:
            raise ValueError("user_not_found")

        return notification_repository.create(
            db,
            user_id=user_id,
            notification_type=notification_type,
            payload_json=payload_json,
            read_at=None,
            created_at=datetime.now(timezone.utc),
        )

    def list_notifications(
        self,
        db: Session,
        user_id: uuid.UUID,
        *,
        unread_only: bool = False,
        limit: int = 100,
        offset: int = 0,
    ) -> list[Notification]:
        user = user_repository.get(db, user_id)
        if user is None:
            raise ValueError("user_not_found")
        return notification_repository.list_by_user_id(
            db,
            user_id,
            unread_only=unread_only,
            limit=limit,
            offset=offset,
        )

    def get_notification(self, db: Session, notification_id: uuid.UUID) -> Notification | None:
        return notification_repository.get_active(db, notification_id)

    def mark_read(self, db: Session, notification_id: uuid.UUID) -> Notification:
        notification = notification_repository.get_active(db, notification_id)
        if notification is None:
            raise ValueError("notification_not_found")
        if notification.read_at is not None:
            return notification

        return notification_repository.update(db, notification, read_at=datetime.now(timezone.utc))

    def mark_unread(self, db: Session, notification_id: uuid.UUID) -> Notification:
        notification = notification_repository.get_active(db, notification_id)
        if notification is None:
            raise ValueError("notification_not_found")
        if notification.read_at is None:
            return notification

        return notification_repository.update(db, notification, read_at=None)

    def delete_notification(self, db: Session, notification_id: uuid.UUID) -> Notification:
        notification = notification_repository.get(db, notification_id)
        if notification is None:
            raise ValueError("notification_not_found")
        if notification.deleted_at is not None:
            return notification

        return notification_repository.update(db, notification, deleted_at=datetime.now(timezone.utc))


notification_service = NotificationService()
