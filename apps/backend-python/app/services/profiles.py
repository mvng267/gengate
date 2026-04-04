import uuid

from sqlalchemy.orm import Session

from app.models.profiles import Profile
from app.repositories.profiles import profile_repository
from app.repositories.users import user_repository


class ProfileService:
    def upsert_profile(
        self,
        db: Session,
        user_id: uuid.UUID,
        display_name: str | None,
        bio: str | None,
        avatar_url: str | None,
    ) -> Profile:
        user = user_repository.get(db, user_id)
        if user is None:
            raise ValueError("user_not_found")

        profile = profile_repository.get_by_user_id(db, user_id)
        if profile is None:
            profile = profile_repository.create(
                db,
                user_id=user_id,
                display_name=display_name,
                bio=bio,
                avatar_url=avatar_url,
            )
            return profile

        profile.display_name = display_name
        profile.bio = bio
        profile.avatar_url = avatar_url
        db.flush()
        db.refresh(profile)
        return profile

    def get_by_user_id(self, db: Session, user_id: uuid.UUID) -> Profile | None:
        return profile_repository.get_by_user_id(db, user_id)


profile_service = ProfileService()
