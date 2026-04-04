from __future__ import annotations

from datetime import datetime
import uuid

from sqlalchemy import DateTime, ForeignKey, String, Uuid, func
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base
from app.models.mixins import CreatedAtMixin, UUIDPrimaryKeyMixin


class Device(UUIDPrimaryKeyMixin, CreatedAtMixin, Base):
    __tablename__ = "devices"

    user_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    platform: Mapped[str] = mapped_column(String(32), nullable=False)
    device_name: Mapped[str] = mapped_column(String(128), nullable=False)
    device_trust_state: Mapped[str] = mapped_column(String(32), nullable=False, default="trusted")
    push_token: Mapped[str | None] = mapped_column(String(512), nullable=True)
    last_active_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
        server_default=func.now(),
    )
