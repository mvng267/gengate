from __future__ import annotations

import uuid

from sqlalchemy import ForeignKey, UniqueConstraint, Uuid
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base
from app.models.mixins import CreatedAtMixin, UUIDPrimaryKeyMixin


class LocationShareAudience(UUIDPrimaryKeyMixin, CreatedAtMixin, Base):
    __tablename__ = "location_share_audience"
    __table_args__ = (
        UniqueConstraint("location_share_id", "allowed_user_id", name="uq_location_share_audience_share_user"),
    )

    location_share_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("location_shares.id", ondelete="CASCADE"),
        nullable=False,
    )
    allowed_user_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
