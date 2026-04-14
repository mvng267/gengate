import uuid

from sqlalchemy import Select, select
from sqlalchemy.orm import Session

from app.models.notifications import Notification
from app.repositories.base import BaseRepository


class NotificationRepository(BaseRepository[Notification]):
    def __init__(self) -> None:
        super().__init__(Notification)

    def get_active(self, db: Session, notification_id: uuid.UUID) -> Notification | None:
        statement = select(Notification).where(
            Notification.id == notification_id,
            Notification.deleted_at.is_(None),
        )
        return db.scalar(statement)

    def list_by_user_id(
        self,
        db: Session,
        user_id: uuid.UUID,
        *,
        unread_only: bool = False,
        limit: int = 100,
        offset: int = 0,
    ) -> list[Notification]:
        statement: Select[tuple[Notification]] = select(Notification).where(
            Notification.user_id == user_id,
            Notification.deleted_at.is_(None),
        )
        if unread_only:
            statement = statement.where(Notification.read_at.is_(None))
        statement = statement.order_by(Notification.created_at.desc(), Notification.id.desc()).offset(offset).limit(limit)
        return list(db.scalars(statement).all())


notification_repository = NotificationRepository()
