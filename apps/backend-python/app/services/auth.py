import secrets
from datetime import datetime, timedelta, timezone

from sqlalchemy.orm import Session

from app.models.devices import Device
from app.models.sessions import Session as AuthSession
from app.models.users import User
from app.repositories.security import device_repository
from app.repositories.sessions import session_repository
from app.repositories.users import user_repository


SESSION_LIFETIME_DAYS = 30


class AuthService:
    def register_user(self, db: Session, email: str, username: str | None) -> tuple[User, bool]:
        existing_email = user_repository.get_by_email(db, email)
        if existing_email is not None:
            return existing_email, False

        normalized_username = username
        if normalized_username == "":
            normalized_username = None

        if normalized_username:
            existing_username = user_repository.get_by_username(db, normalized_username)
            if existing_username is not None:
                return existing_username, False

        user = user_repository.create(
            db,
            email=email,
            username=normalized_username,
            status="active",
            password_hash=None,
            email_verified_at=datetime.now(timezone.utc),
        )
        return user, True

    def login_or_create_session(
        self,
        db: Session,
        email: str,
        platform: str,
        device_name: str,
    ) -> tuple[User, Device, AuthSession, str, str]:
        user = user_repository.get_by_email(db, email)
        if user is None:
            raise ValueError("user_not_found")

        device = self._find_or_create_device(
            db,
            user=user,
            platform=platform,
            device_name=device_name,
        )

        refresh_token = secrets.token_urlsafe(24)
        auth_session = session_repository.create(
            db,
            user_id=user.id,
            device_id=device.id,
            refresh_token_hash=refresh_token,
            expires_at=self._build_session_expiry(),
            revoked_at=None,
        )
        return user, device, auth_session, refresh_token, "password_stub"

    def refresh_session(
        self,
        db: Session,
        refresh_token: str,
    ) -> tuple[User, Device, AuthSession, str]:
        existing_session = session_repository.get_by_refresh_token_hash(db, refresh_token)
        if existing_session is None:
            raise ValueError("session_not_found")
        if existing_session.revoked_at is not None:
            raise ValueError("session_revoked")
        if self._is_session_expired(existing_session.expires_at):
            raise ValueError("session_expired")

        user = user_repository.get(db, existing_session.user_id)
        if user is None:
            raise ValueError("user_not_found")

        device = device_repository.get(db, existing_session.device_id)
        if device is None:
            raise ValueError("device_not_found")

        next_refresh_token = secrets.token_urlsafe(24)
        next_session = session_repository.create(
            db,
            user_id=user.id,
            device_id=device.id,
            refresh_token_hash=next_refresh_token,
            expires_at=self._build_session_expiry(),
            revoked_at=None,
        )
        session_repository.update(db, existing_session, revoked_at=datetime.now(timezone.utc))
        return user, device, next_session, next_refresh_token

    def get_session_snapshot(self, db: Session, refresh_token: str) -> tuple[User, Device, AuthSession]:
        auth_session = self._get_active_session_by_refresh_token(db, refresh_token)

        user = user_repository.get(db, auth_session.user_id)
        if user is None:
            raise ValueError("user_not_found")

        device = device_repository.get(db, auth_session.device_id)
        if device is None:
            raise ValueError("device_not_found")

        return user, device, auth_session

    def logout_session(self, db: Session, refresh_token: str) -> AuthSession:
        auth_session = self._get_active_session_by_refresh_token(db, refresh_token)
        return session_repository.update(db, auth_session, revoked_at=datetime.now(timezone.utc))

    def _get_active_session_by_refresh_token(self, db: Session, refresh_token: str) -> AuthSession:
        auth_session = session_repository.get_by_refresh_token_hash(db, refresh_token)
        if auth_session is None:
            raise ValueError("session_not_found")
        if auth_session.revoked_at is not None:
            raise ValueError("session_revoked")
        if self._is_session_expired(auth_session.expires_at):
            raise ValueError("session_expired")
        return auth_session

    def _find_or_create_device(
        self,
        db: Session,
        user: User,
        platform: str,
        device_name: str,
    ) -> Device:
        devices = device_repository.list_by_user_id(db, user.id)
        for device in devices:
            if device.platform == platform and device.device_name == device_name:
                if device.device_trust_state == "revoked":
                    return device_repository.update(db, device, device_trust_state="trusted")
                return device

        return device_repository.create(
            db,
            user_id=user.id,
            platform=platform,
            device_name=device_name,
            device_trust_state="trusted",
            push_token=None,
        )

    def _build_session_expiry(self) -> datetime:
        return datetime.now(timezone.utc) + timedelta(days=SESSION_LIFETIME_DAYS)

    def _is_session_expired(self, expires_at: datetime) -> bool:
        normalized_expires_at = expires_at
        if normalized_expires_at.tzinfo is None:
            normalized_expires_at = normalized_expires_at.replace(tzinfo=timezone.utc)
        return normalized_expires_at <= datetime.now(timezone.utc)


auth_service = AuthService()
