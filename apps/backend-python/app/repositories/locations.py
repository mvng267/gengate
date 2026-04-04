import uuid

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.location_share_audience import LocationShareAudience
from app.models.location_shares import LocationShare
from app.models.user_location_snapshots import UserLocationSnapshot
from app.repositories.base import BaseRepository


class LocationShareRepository(BaseRepository[LocationShare]):
    def __init__(self) -> None:
        super().__init__(LocationShare)


class LocationShareAudienceRepository(BaseRepository[LocationShareAudience]):
    def __init__(self) -> None:
        super().__init__(LocationShareAudience)

    def list_by_share_id(self, db: Session, location_share_id: uuid.UUID) -> list[LocationShareAudience]:
        statement = select(LocationShareAudience).where(LocationShareAudience.location_share_id == location_share_id)
        return list(db.scalars(statement).all())


class UserLocationSnapshotRepository(BaseRepository[UserLocationSnapshot]):
    def __init__(self) -> None:
        super().__init__(UserLocationSnapshot)

    def list_by_owner(self, db: Session, owner_user_id: uuid.UUID) -> list[UserLocationSnapshot]:
        statement = select(UserLocationSnapshot).where(UserLocationSnapshot.owner_user_id == owner_user_id)
        return list(db.scalars(statement).all())


location_share_repository = LocationShareRepository()
location_share_audience_repository = LocationShareAudienceRepository()
user_location_snapshot_repository = UserLocationSnapshotRepository()
