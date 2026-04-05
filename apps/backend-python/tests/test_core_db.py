import pytest
import app.core.db as db


def test_get_database_engine_rejects_encoded_slash_database_url(monkeypatch: pytest.MonkeyPatch) -> None:
    db._engine = None
    db._session_factory = None

    monkeypatch.setattr(
        db,
        "get_settings",
        lambda: type(
            "Settings",
            (),
            {"database_url": "postgresql+psycopg://postgres@/gengate%2Farchive"},
        )(),
    )

    with pytest.raises(ValueError, match="rendered Postgres database URL"):
        db.get_database_engine()


def test_get_database_engine_allows_non_postgres_url(monkeypatch: pytest.MonkeyPatch) -> None:
    db._engine = None
    db._session_factory = None

    monkeypatch.setattr(
        db,
        "get_settings",
        lambda: type(
            "Settings",
            (),
            {"database_url": "sqlite+pysqlite:///:memory:"},
        )(),
    )

    engine = db.get_database_engine()

    assert engine.url.drivername == "sqlite+pysqlite"
