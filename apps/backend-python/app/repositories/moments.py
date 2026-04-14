import uuid

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.moments import Moment
from app.repositories.base import BaseRepository


class MomentRepository(BaseRepository[Moment]):
    def __init__(self) -> None:
        super().__init__(Moment)

    def list_for_author(self, db: Session, author_user_id: uuid.UUID, limit: int = 50, offset: int = 0) -> list[Moment]:
        statement = (
            select(Moment)
            .where(Moment.author_user_id == author_user_id)
            .where(Moment.deleted_at.is_(None))
            .order_by(Moment.created_at.desc())
            .offset(offset)
            .limit(limit)
        )
        return list(db.scalars(statement).all())

    def list_for_authors(self, db: Session, author_user_ids: list[uuid.UUID], limit: int = 50) -> list[Moment]:
        if not author_user_ids:
            return []
        statement = (
            select(Moment)
            .where(Moment.author_user_id.in_(author_user_ids))
            .where(Moment.deleted_at.is_(None))
            .order_by(Moment.created_at.desc())
            .limit(limit)
        )
        return list(db.scalars(statement).all())


moment_repository = MomentRepository()
