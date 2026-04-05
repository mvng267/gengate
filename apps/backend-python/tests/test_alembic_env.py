import pytest

from tests._alembic_env_loader import load_alembic_env_module


@pytest.fixture(scope="module")
def alembic_env_module():
    return load_alembic_env_module()


def test_alembic_env_validate_database_url_rejects_encoded_slash(alembic_env_module) -> None:
    with pytest.raises(ValueError, match="rendered Postgres database URL"):
        alembic_env_module._validate_alembic_database_url("postgresql+psycopg://postgres@/gengate%2Farchive")


def test_alembic_env_validate_database_url_allows_sqlite(alembic_env_module) -> None:
    alembic_env_module._validate_alembic_database_url("sqlite+pysqlite:///:memory:")
