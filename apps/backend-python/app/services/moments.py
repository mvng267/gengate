import uuid
from datetime import datetime, timezone

from sqlalchemy.orm import Session

from app.models.moment_media import MomentMedia
from app.models.moment_reactions import MomentReaction
from app.models.moments import Moment
from app.repositories.moment_interactions import moment_media_repository, moment_reaction_repository
from app.repositories.moments import moment_repository
from app.repositories.users import user_repository


class MomentService:
    def create_moment(self, db: Session, author_user_id: uuid.UUID, caption_text: str | None) -> Moment:
        author = user_repository.get(db, author_user_id)
        if author is None:
            raise ValueError("user_not_found")

        return moment_repository.create(
            db,
            author_user_id=author_user_id,
            caption_text=caption_text,
            visibility_scope="friends",
            location_snapshot_id=None,
            deleted_at=None,
        )

    def get_moment(self, db: Session, moment_id: uuid.UUID) -> Moment | None:
        return moment_repository.get(db, moment_id)

    def update_moment(self, db: Session, moment_id: uuid.UUID, caption_text: str | None) -> Moment:
        moment = moment_repository.get(db, moment_id)
        if moment is None:
            raise ValueError("moment_not_found")
        return moment_repository.update(db, moment, caption_text=caption_text)

    def delete_moment(self, db: Session, moment_id: uuid.UUID) -> Moment:
        moment = moment_repository.get(db, moment_id)
        if moment is None:
            raise ValueError("moment_not_found")
        return moment_repository.update(db, moment, deleted_at=datetime.now(timezone.utc))

    def create_media(
        self,
        db: Session,
        moment_id: uuid.UUID,
        media_type: str,
        storage_key: str,
        mime_type: str,
        width: int | None,
        height: int | None,
    ) -> MomentMedia:
        moment = moment_repository.get(db, moment_id)
        if moment is None:
            raise ValueError("moment_not_found")

        return moment_media_repository.create(
            db,
            moment_id=moment_id,
            media_type=media_type,
            storage_key=storage_key,
            mime_type=mime_type,
            width=width,
            height=height,
        )

    def list_media(self, db: Session, moment_id: uuid.UUID) -> list[MomentMedia]:
        moment = moment_repository.get(db, moment_id)
        if moment is None:
            raise ValueError("moment_not_found")
        return moment_media_repository.list_by_moment(db, moment_id)

    def create_reaction(
        self,
        db: Session,
        moment_id: uuid.UUID,
        user_id: uuid.UUID,
        reaction_type: str,
    ) -> MomentReaction:
        moment = moment_repository.get(db, moment_id)
        if moment is None:
            raise ValueError("moment_not_found")

        user = user_repository.get(db, user_id)
        if user is None:
            raise ValueError("user_not_found")

        existing = moment_reaction_repository.get_by_moment_and_user(db, moment_id, user_id)
        if existing is not None:
            return moment_reaction_repository.update(db, existing, reaction_type=reaction_type)

        return moment_reaction_repository.create(
            db,
            moment_id=moment_id,
            user_id=user_id,
            reaction_type=reaction_type,
        )

    def list_reactions(self, db: Session, moment_id: uuid.UUID) -> list[MomentReaction]:
        moment = moment_repository.get(db, moment_id)
        if moment is None:
            raise ValueError("moment_not_found")
        return moment_reaction_repository.list_by_moment(db, moment_id)


moment_service = MomentService()
