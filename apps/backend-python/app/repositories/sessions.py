import uuid

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.sessions import Session as AuthSession
from app.repositories.base import BaseRepository


class SessionRepository(BaseRepository[AuthSession]):
    def __init__(self) -> None:
        super().__init__(AuthSession)

    def get_by_refresh_token_hash(self, db: Session, refresh_token_hash: str) -> AuthSession | None:
        statement = select(AuthSession).where(AuthSession.refresh_token_hash == refresh_token_hash)
        return db.scalar(statement)

    def list_by_user_id(self, db: Session, user_id: uuid.UUID) -> list[AuthSession]:
        statement = select(AuthSession).where(AuthSession.user_id == user_id)
        return list(db.scalars(statement).all())

    def list_by_device_id(self, db: Session, device_id: uuid.UUID) -> list[AuthSession]:
        statement = select(AuthSession).where(AuthSession.device_id == device_id)
        return list(db.scalars(statement).all())


session_repository = SessionRepository()
