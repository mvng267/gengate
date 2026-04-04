from collections.abc import Sequence

from alembic import op
import sqlalchemy as sa

revision: str = "20260404_000002"
down_revision: str | None = "20260403_000001"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

CONSTRAINT_NAME = "uq_message_device_keys_message_recipient_device"
TABLE_NAME = "message_device_keys"
COLUMNS = ["message_id", "recipient_device_id"]


def _table_exists(bind: sa.Connection) -> bool:
    inspector = sa.inspect(bind)
    return TABLE_NAME in inspector.get_table_names()


def _constraint_exists(bind: sa.Connection) -> bool:
    inspector = sa.inspect(bind)
    for constraint in inspector.get_unique_constraints(TABLE_NAME):
        if constraint.get("name") == CONSTRAINT_NAME:
            return True
    return False


def upgrade() -> None:
    bind = op.get_bind()
    if not _table_exists(bind):
        return
    if _constraint_exists(bind):
        return
    op.create_unique_constraint(
        "uq_message_device_keys_message_recipient_device",
        "message_device_keys",
        ["message_id", "recipient_device_id"],
    )


def downgrade() -> None:
    bind = op.get_bind()
    if not _table_exists(bind):
        return
    if not _constraint_exists(bind):
        return
    op.drop_constraint(
        "uq_message_device_keys_message_recipient_device",
        "message_device_keys",
        type_="unique",
    )
