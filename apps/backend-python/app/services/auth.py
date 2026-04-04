from sqlalchemy.orm import Session

from app.models.users import User
from app.repositories.users import user_repository


class AuthService:
    def register_user(self, db: Session, email: str, username: str | None) -> tuple[User, bool]:
        existing_email = user_repository.get_by_email(db, email)
        if existing_email is not None:
            return existing_email, False

        if username:
            existing_username = user_repository.get_by_username(db, username)
            if existing_username is not None:
                return existing_username, False

        user = user_repository.create(
            db,
            email=email,
            username=username,
            status="active",
            password_hash=None,
            email_verified_at=None,
        )
        return user, True


auth_service = AuthService()
