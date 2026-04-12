import secrets
from datetime import datetime, timedelta, timezone

from sqlalchemy.orm import Session

from app.models.devices import Device
from app.models.sessions import Session as AuthSession
from app.models.users import User
from app.repositories.security import device_repository
from app.repositories.sessions import session_repository
from app.repositories.users import user_repository


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
            expires_at=datetime.now(timezone.utc) + timedelta(days=30),
            revoked_at=None,
        )
        return user, device, auth_session, refresh_token, "password_stub"

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


auth_service = AuthService()
