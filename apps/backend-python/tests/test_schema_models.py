from pathlib import Path
from urllib.parse import urlsplit
import os
import uuid

import psycopg
import pytest
from alembic import command
from alembic.config import Config
from sqlalchemy import create_engine, inspect

from app.models.base import Base
from app.models import all_models


def _postgres_admin_url() -> str:
    admin_url = os.getenv("GENGATE_POSTGRES_ADMIN_URL", "postgresql:///postgres").strip()
    if not admin_url:
        return "postgresql:///postgres"
    return admin_url


def _batch28_postgres_urls(database_name: str) -> tuple[str, str]:
    admin_role = os.getenv("GENGATE_TEST_POSTGRES_ADMIN_ROLE", "postgres").strip() or "postgres"
    admin_database = os.getenv("GENGATE_TEST_POSTGRES_ADMIN_DATABASE", "postgres").strip() or "postgres"

    admin_url = os.getenv("GENGATE_TEST_POSTGRES_ADMIN_URL", "").strip()
    if not admin_url:
        admin_url = f"postgresql://{admin_role}@/{admin_database}"

    database_url_template = os.getenv("GENGATE_TEST_POSTGRES_DATABASE_URL_TEMPLATE", "").strip()
    if database_url_template:
        if "{database_name}" not in database_url_template:
            raise ValueError(
                "Invalid GENGATE_TEST_POSTGRES_DATABASE_URL_TEMPLATE: expected placeholders "
                "{database_name}, {admin_role}, {admin_database}"
            )
        try:
            database_url = database_url_template.format(
                database_name=database_name,
                admin_role=admin_role,
                admin_database=admin_database,
            )
        except (IndexError, KeyError, ValueError) as exc:
            raise ValueError(
                "Invalid GENGATE_TEST_POSTGRES_DATABASE_URL_TEMPLATE: expected placeholders "
                "{database_name}, {admin_role}, {admin_database}"
            ) from exc
    else:
        database_url = f"postgresql+psycopg://{admin_role}@/{database_name}"

    parsed_admin_url = urlsplit(admin_url)
    admin_path = parsed_admin_url.path.strip()
    if (
        not admin_url
        or parsed_admin_url.scheme not in {"postgresql", "postgresql+psycopg"}
        or admin_path in {"", "/"}
    ):
        raise ValueError("Invalid rendered Postgres admin URL")

    parsed_database_url = urlsplit(database_url)
    database_path = parsed_database_url.path.strip()
    if (
        not database_url
        or parsed_database_url.scheme not in {"postgresql", "postgresql+psycopg"}
        or database_path in {"", "/"}
    ):
        raise ValueError("Invalid rendered Postgres database URL")

    return admin_url, database_url


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


def test_batch27_postgres_admin_url_defaults_to_unix_socket() -> None:
    assert _postgres_admin_url() == "postgresql:///postgres"


def test_batch27_postgres_admin_url_strips_whitespace(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("GENGATE_POSTGRES_ADMIN_URL", "  postgresql:///postgres  ")

    assert _postgres_admin_url() == "postgresql:///postgres"


def test_batch27_postgres_admin_url_falls_back_when_blank(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("GENGATE_POSTGRES_ADMIN_URL", "   ")

    assert _postgres_admin_url() == "postgresql:///postgres"


def test_batch28_postgres_test_urls_default_to_admin_role_and_db(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.delenv("GENGATE_TEST_POSTGRES_ADMIN_ROLE", raising=False)
    monkeypatch.delenv("GENGATE_TEST_POSTGRES_ADMIN_DATABASE", raising=False)
    monkeypatch.delenv("GENGATE_TEST_POSTGRES_ADMIN_URL", raising=False)
    monkeypatch.delenv("GENGATE_TEST_POSTGRES_DATABASE_URL_TEMPLATE", raising=False)

    admin_url, database_url = _batch28_postgres_urls("gengate_batch28_default")

    assert admin_url == "postgresql://postgres@/postgres"
    assert database_url == "postgresql+psycopg://postgres@/gengate_batch28_default"


def test_batch28_postgres_test_urls_allow_role_and_db_override(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("GENGATE_TEST_POSTGRES_ADMIN_ROLE", "gengate_admin")
    monkeypatch.setenv("GENGATE_TEST_POSTGRES_ADMIN_DATABASE", "gengate_maintenance")
    monkeypatch.delenv("GENGATE_TEST_POSTGRES_ADMIN_URL", raising=False)
    monkeypatch.delenv("GENGATE_TEST_POSTGRES_DATABASE_URL_TEMPLATE", raising=False)

    admin_url, database_url = _batch28_postgres_urls("gengate_batch28_override")

    assert admin_url == "postgresql://gengate_admin@/gengate_maintenance"
    assert database_url == "postgresql+psycopg://gengate_admin@/gengate_batch28_override"


def test_batch29_postgres_test_urls_require_database_name_in_template(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("GENGATE_TEST_POSTGRES_DATABASE_URL_TEMPLATE", "postgresql+psycopg://{admin_role}@/gengate_fixed")

    with pytest.raises(ValueError, match="database_name"):
        _batch28_postgres_urls("gengate_batch29_missing_name")


def test_batch29_postgres_test_urls_reject_invalid_database_url_template(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("GENGATE_TEST_POSTGRES_DATABASE_URL_TEMPLATE", "postgresql+psycopg://{admin_role}@/{bad_name}")

    with pytest.raises(ValueError, match="GENGATE_TEST_POSTGRES_DATABASE_URL_TEMPLATE"):
        _batch28_postgres_urls("gengate_batch29_invalid")


def test_batch30_postgres_test_urls_require_database_path_segment(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("GENGATE_TEST_POSTGRES_DATABASE_URL_TEMPLATE", "postgresql+psycopg://{database_name}@/")

    with pytest.raises(ValueError, match="rendered Postgres database URL"):
        _batch28_postgres_urls("gengate_batch30_missing_db_segment")


def test_batch31_postgres_test_urls_reject_malformed_admin_url(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("GENGATE_TEST_POSTGRES_ADMIN_URL", "postgresql://")
    monkeypatch.setenv(
        "GENGATE_TEST_POSTGRES_DATABASE_URL_TEMPLATE",
        "postgresql+psycopg://{admin_role}@/{database_name}",
    )

    with pytest.raises(ValueError, match="rendered Postgres admin URL"):
        _batch28_postgres_urls("gengate_batch31_invalid_admin_url")


def test_batch31_postgres_test_urls_reject_admin_url_without_database_path(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("GENGATE_TEST_POSTGRES_ADMIN_URL", "postgresql://postgres@/")
    monkeypatch.setenv(
        "GENGATE_TEST_POSTGRES_DATABASE_URL_TEMPLATE",
        "postgresql+psycopg://{admin_role}@/{database_name}",
    )

    with pytest.raises(ValueError, match="rendered Postgres admin URL"):
        _batch28_postgres_urls("gengate_batch31_missing_admin_db_segment")


def test_batch31_postgres_test_urls_reject_admin_url_with_invalid_scheme(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("GENGATE_TEST_POSTGRES_ADMIN_URL", "mysql://root@/postgres")
    monkeypatch.setenv(
        "GENGATE_TEST_POSTGRES_DATABASE_URL_TEMPLATE",
        "postgresql+psycopg://{admin_role}@/{database_name}",
    )

    with pytest.raises(ValueError, match="rendered Postgres admin URL"):
        _batch28_postgres_urls("gengate_batch31_invalid_admin_scheme")


def test_batch26_postgres_alembic_unique_constraint_round_trip() -> None:
    project_root = Path(__file__).resolve().parents[1]
    database_name = f"gengate_batch26_{uuid.uuid4().hex[:10]}"
    admin_url, database_url = _batch28_postgres_urls(database_name)

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
