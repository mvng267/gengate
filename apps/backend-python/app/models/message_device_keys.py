from __future__ import annotations

import uuid

from sqlalchemy import ForeignKey, LargeBinary, UniqueConstraint, Uuid
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base
from app.models.mixins import CreatedAtMixin, UUIDPrimaryKeyMixin


class MessageDeviceKey(UUIDPrimaryKeyMixin, CreatedAtMixin, Base):
    __tablename__ = "message_device_keys"
    __table_args__ = (
        UniqueConstraint("message_id", "recipient_device_id", name="uq_message_device_keys_message_recipient_device"),
    )

    message_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("messages.id", ondelete="CASCADE"),
        nullable=False,
    )
    recipient_user_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    recipient_device_id: Mapped[uuid.UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("devices.id", ondelete="CASCADE"),
        nullable=False,
    )
    wrapped_message_key_blob: Mapped[bytes] = mapped_column(LargeBinary, nullable=False)
