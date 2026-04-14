import uuid

from sqlalchemy import Select, func, select
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

    def _base_list_statement(self, db: Session, user_id: uuid.UUID, *, unread_only: bool = False) -> Select[tuple[Notification]]:
        statement: Select[tuple[Notification]] = select(Notification).where(
            Notification.user_id == user_id,
            Notification.deleted_at.is_(None),
        )
        if unread_only:
            statement = statement.where(Notification.read_at.is_(None))
        return statement

    def list_by_user_id(
        self,
        db: Session,
        user_id: uuid.UUID,
        *,
        unread_only: bool = False,
        limit: int = 100,
        offset: int = 0,
    ) -> list[Notification]:
        statement = (
            self._base_list_statement(db, user_id, unread_only=unread_only)
            .order_by(Notification.created_at.desc(), Notification.id.desc())
            .offset(offset)
            .limit(limit)
        )
        return list(db.scalars(statement).all())

    def count_by_user_id(self, db: Session, user_id: uuid.UUID, *, unread_only: bool = False) -> int:
        base_statement = self._base_list_statement(db, user_id, unread_only=unread_only)
        count_statement = select(func.count()).select_from(base_statement.subquery())
        value = db.scalar(count_statement)
        return int(value or 0)


notification_repository = NotificationRepository()
