from pathlib import Path
import uuid

import psycopg
import pytest
from alembic import command
from alembic.config import Config
from sqlalchemy import create_engine, inspect

from app.core.postgres_urls import build_postgres_test_urls
from app.models.base import Base
from app.models import all_models


def test_schema_registers_expected_tables() -> None:
    expected_tables = {
        "users",
        "profiles",
        "devices",
        "sessions",
        "friend_requests",
        "friendships",
        "blocks",
        "moments",
        "moment_media",
        "moment_reactions",
        "conversations",
        "conversation_members",
        "messages",
        "message_device_keys",
        "message_attachments",
        "device_keys",
        "user_recovery_material",
        "location_shares",
        "location_share_audience",
        "user_location_snapshots",
        "notifications",
    }
    assert expected_tables.issubset(Base.metadata.tables.keys())


def test_alembic_foundation_files_exist() -> None:
    project_root = Path(__file__).resolve().parents[1]
    assert (project_root / "alembic.ini").exists()
    assert (project_root / "alembic" / "env.py").exists()


def test_batch25_message_device_keys_unique_constraint_migration_exists() -> None:
    project_root = Path(__file__).resolve().parents[1]
    migration_path = project_root / "alembic" / "versions" / "20260404_000002_message_device_keys_unique.py"
    assert migration_path.exists()

    migration_source = migration_path.read_text(encoding="utf-8")
    assert "op.create_unique_constraint(" in migration_source
    assert '"uq_message_device_keys_message_recipient_device"' in migration_source
    assert '"message_device_keys"' in migration_source
    assert '["message_id", "recipient_device_id"]' in migration_source
    assert "op.drop_constraint(" in migration_source


def test_batch27_alembic_ini_sets_os_path_separator() -> None:
    project_root = Path(__file__).resolve().parents[1]
    alembic_source = (project_root / "alembic.ini").read_text(encoding="utf-8")

    assert "path_separator = os" in alembic_source




def test_batch26_postgres_alembic_unique_constraint_round_trip() -> None:
    project_root = Path(__file__).resolve().parents[1]
    database_name = f"gengate_batch26_{uuid.uuid4().hex[:10]}"
    admin_url, database_url = build_postgres_test_urls(database_name)

    try:
        with psycopg.connect(admin_url, autocommit=True) as admin_conn:
            with admin_conn.cursor() as cursor:
                cursor.execute(f'CREATE DATABASE "{database_name}"')
    except Exception as exc:
        pytest.skip(f"postgres create database unavailable: {exc}")

    engine = create_engine(database_url)
    try:
        Base.metadata.create_all(bind=engine)

        alembic_cfg = Config(str(project_root / "alembic.ini"))
        alembic_cfg.set_main_option("sqlalchemy.url", database_url)

        command.upgrade(alembic_cfg, "20260404_000002")

        upgrade_constraints = {
            constraint["name"]
            for constraint in inspect(engine).get_unique_constraints("message_device_keys")
        }
        assert "uq_message_device_keys_message_recipient_device" in upgrade_constraints

        command.downgrade(alembic_cfg, "20260403_000001")

        downgrade_constraints = {
            constraint["name"]
            for constraint in inspect(engine).get_unique_constraints("message_device_keys")
        }
        assert "uq_message_device_keys_message_recipient_device" not in downgrade_constraints
    finally:
        engine.dispose()
        with psycopg.connect(admin_url, autocommit=True) as admin_conn:
            with admin_conn.cursor() as cursor:
                cursor.execute(
                    "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = %s",
                    (database_name,),
                )
                cursor.execute(f'DROP DATABASE IF EXISTS "{database_name}"')
