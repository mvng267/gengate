from __future__ import annotations

import uuid

from sqlalchemy import ForeignKey, String, Text, Uuid
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base
from app.models.mixins import CreatedAtMixin, SoftDeleteMixin, UUIDPrimaryKeyMixin, UpdatedAtMixin


class Moment(UUIDPrimaryKeyMixin, CreatedAtMixin, UpdatedAtMixin, SoftDeleteMixin, Base):
    __tablename__ = "moments"

    author_user_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    caption_text: Mapped[str | None] = mapped_column(Text, nullable=True)
    visibility_scope: Mapped[str] = mapped_column(String(32), nullable=False, default="friends")
    location_snapshot_id: Mapped[uuid.UUID | None] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("user_location_snapshots.id", ondelete="SET NULL"),
        nullable=True,
    )
