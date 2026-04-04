import uuid
from datetime import datetime, timezone

from sqlalchemy.orm import Session

from app.models.sessions import Session as AuthSession
from app.repositories.security import device_repository
from app.repositories.sessions import session_repository
from app.repositories.users import user_repository


class SessionService:
    def _revoke_sessions_idempotently(self, db: Session, sessions: list[AuthSession]) -> list[AuthSession]:
        now = datetime.now(timezone.utc)
        updated_sessions: list[AuthSession] = []
        for session in sessions:
            if session.revoked_at is None:
                updated_sessions.append(session_repository.update(db, session, revoked_at=now))
            else:
                updated_sessions.append(session)
        return updated_sessions

    def create_session(
        self,
        db: Session,
        user_id: uuid.UUID,
        device_id: uuid.UUID,
        refresh_token_hash: str,
        expires_at: datetime,
    ) -> AuthSession:
        user = user_repository.get(db, user_id)
        if user is None:
            raise ValueError("user_not_found")

        device = device_repository.get(db, device_id)
        if device is None:
            raise ValueError("device_not_found")

        if device.user_id != user_id:
            raise ValueError("device_user_mismatch")

        return session_repository.create(
            db,
            user_id=user_id,
            device_id=device_id,
            refresh_token_hash=refresh_token_hash,
            expires_at=expires_at,
            revoked_at=None,
        )

    def list_sessions(self, db: Session, user_id: uuid.UUID) -> list[AuthSession]:
        user = user_repository.get(db, user_id)
        if user is None:
            raise ValueError("user_not_found")
        return session_repository.list_by_user_id(db, user_id)

    def get_session(self, db: Session, session_id: uuid.UUID) -> AuthSession:
        session = session_repository.get(db, session_id)
        if session is None:
            raise ValueError("session_not_found")
        return session

    def revoke_session(self, db: Session, session_id: uuid.UUID) -> AuthSession:
        session = session_repository.get(db, session_id)
        if session is None:
            raise ValueError("session_not_found")
        if session.revoked_at is not None:
            return session
        return session_repository.update(db, session, revoked_at=datetime.now(timezone.utc))

    def revoke_all_sessions_for_user(self, db: Session, user_id: uuid.UUID) -> list[AuthSession]:
        user = user_repository.get(db, user_id)
        if user is None:
            raise ValueError("user_not_found")

        sessions = session_repository.list_by_user_id(db, user_id)
        return self._revoke_sessions_idempotently(db, sessions)

    def revoke_all_sessions_for_device(self, db: Session, device_id: uuid.UUID) -> list[AuthSession]:
        device = device_repository.get(db, device_id)
        if device is None:
            raise ValueError("device_not_found")

        sessions = session_repository.list_by_device_id(db, device_id)
        return self._revoke_sessions_idempotently(db, sessions)


session_service = SessionService()
