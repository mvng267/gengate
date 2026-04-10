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
        display_name_provided: bool = True,
        bio_provided: bool = True,
        avatar_url_provided: bool = True,
    ) -> Profile:
        user = user_repository.get(db, user_id)
        if user is None:
            raise ValueError("user_not_found")

        profile = profile_repository.get_by_user_id(db, user_id)
        if profile is None:
            profile = profile_repository.create(
                db,
                user_id=user_id,
                display_name=display_name if display_name_provided else None,
                bio=bio if bio_provided else None,
                avatar_url=avatar_url if avatar_url_provided else None,
            )
            return profile

        if display_name_provided:
            profile.display_name = display_name
        if bio_provided:
            profile.bio = bio
        if avatar_url_provided:
            profile.avatar_url = avatar_url
        db.flush()
        db.refresh(profile)
        return profile

    def get_by_user_id(self, db: Session, user_id: uuid.UUID) -> Profile | None:
        return profile_repository.get_by_user_id(db, user_id)


profile_service = ProfileService()
