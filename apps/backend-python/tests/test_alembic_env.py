import pytest

from app.core.postgres_urls import validate_postgres_database_url_if_needed


def test_alembic_style_postgres_url_gate_rejects_encoded_slash() -> None:
    with pytest.raises(ValueError, match="rendered Postgres database URL"):
        validate_postgres_database_url_if_needed("postgresql+psycopg://postgres@/gengate%2Farchive")


def test_alembic_style_postgres_url_gate_allows_sqlite() -> None:
    validate_postgres_database_url_if_needed("sqlite+pysqlite:///:memory:")
