import uuid
from datetime import datetime, timezone

from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.models.location_share_audience import LocationShareAudience
from app.models.location_shares import LocationShare
from app.models.user_location_snapshots import UserLocationSnapshot
from app.repositories.locations import (
    location_share_audience_repository,
    location_share_repository,
    user_location_snapshot_repository,
)
from app.repositories.users import user_repository


class LocationService:
    def create_share(
        self,
        db: Session,
        owner_user_id: uuid.UUID,
        is_active: bool,
        sharing_mode: str,
    ) -> LocationShare:
        owner = user_repository.get(db, owner_user_id)
        if owner is None:
            raise ValueError("user_not_found")

        return location_share_repository.create(
            db,
            owner_user_id=owner_user_id,
            is_active=is_active,
            sharing_mode=sharing_mode,
        )

    def update_share(self, db: Session, share_id: uuid.UUID, is_active: bool | None) -> LocationShare:
        share = location_share_repository.get(db, share_id)
        if share is None:
            raise ValueError("share_not_found")

        if is_active is None:
            return share
        return location_share_repository.update(db, share, is_active=is_active)

    def list_shares(self, db: Session) -> list[LocationShare]:
        return location_share_repository.list(db, limit=1000, offset=0)

    def create_share_audience(
        self,
        db: Session,
        location_share_id: uuid.UUID,
        allowed_user_id: uuid.UUID,
    ) -> LocationShareAudience:
        share = location_share_repository.get(db, location_share_id)
        if share is None:
            raise ValueError("share_not_found")

        allowed_user = user_repository.get(db, allowed_user_id)
        if allowed_user is None:
            raise ValueError("user_not_found")

        existing_audience = location_share_audience_repository.get_by_share_and_user(
            db,
            location_share_id=location_share_id,
            allowed_user_id=allowed_user_id,
        )
        if existing_audience is not None:
            raise ValueError("audience_exists")

        try:
            return location_share_audience_repository.create(
                db,
                location_share_id=location_share_id,
                allowed_user_id=allowed_user_id,
            )
        except IntegrityError as exc:
            db.rollback()
            if self._is_duplicate_audience_constraint(exc):
                raise ValueError("audience_exists") from exc
            raise

    def list_share_audience(self, db: Session, location_share_id: uuid.UUID) -> list[LocationShareAudience]:
        share = location_share_repository.get(db, location_share_id)
        if share is None:
            raise ValueError("share_not_found")
        return location_share_audience_repository.list_by_share_id(db, location_share_id)

    def remove_share_audience(
        self,
        db: Session,
        location_share_id: uuid.UUID,
        audience_id: uuid.UUID,
    ) -> LocationShareAudience:
        audience = location_share_audience_repository.get(db, audience_id)
        if audience is None:
            raise ValueError("audience_not_found")
        if audience.location_share_id != location_share_id:
            raise ValueError("audience_not_found")

        location_share_audience_repository.delete(db, audience)
        return audience

    def create_snapshot(
        self,
        db: Session,
        owner_user_id: uuid.UUID,
        lat: float,
        lng: float,
        accuracy_meters: float | None,
    ) -> UserLocationSnapshot:
        owner = user_repository.get(db, owner_user_id)
        if owner is None:
            raise ValueError("user_not_found")

        return user_location_snapshot_repository.create(
            db,
            owner_user_id=owner_user_id,
            lat=lat,
            lng=lng,
            accuracy_meters=accuracy_meters,
            captured_at=datetime.now(timezone.utc),
            expires_at=None,
        )

    def list_snapshots(self, db: Session, owner_user_id: uuid.UUID) -> list[UserLocationSnapshot]:
        return user_location_snapshot_repository.list_by_owner(db, owner_user_id)

    @staticmethod
    def _is_duplicate_audience_constraint(exc: IntegrityError) -> bool:
        orig = getattr(exc, "orig", None)
        diag = getattr(orig, "diag", None)
        constraint_name = getattr(diag, "constraint_name", None)
        if constraint_name == "uq_location_share_audience_share_user":
            return True

        message_detail = str(getattr(diag, "message_detail", "") or "")
        if "uq_location_share_audience_share_user" in message_detail:
            return True

        message = str(orig or exc)
        lowered = message.lower()
        return "location_share_audience" in lowered and "location_share_id" in lowered and "allowed_user_id" in lowered


location_service = LocationService()
