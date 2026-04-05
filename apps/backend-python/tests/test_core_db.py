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

    assert db._engine is None


def test_get_database_engine_rejects_trailing_slash_database_url(monkeypatch: pytest.MonkeyPatch) -> None:
    db._engine = None
    db._session_factory = None

    monkeypatch.setattr(
        db,
        "get_settings",
        lambda: type(
            "Settings",
            (),
            {"database_url": "postgresql+psycopg://postgres@/gengate/"},
        )(),
    )

    with pytest.raises(ValueError, match="rendered Postgres database URL"):
        db.get_database_engine()

    assert db._engine is None


def test_get_database_engine_rejects_double_leading_slash_database_url(monkeypatch: pytest.MonkeyPatch) -> None:
    db._engine = None
    db._session_factory = None

    monkeypatch.setattr(
        db,
        "get_settings",
        lambda: type(
            "Settings",
            (),
            {"database_url": "postgresql+psycopg://postgres@//gengate"},
        )(),
    )

    with pytest.raises(ValueError, match="rendered Postgres database URL"):
        db.get_database_engine()

    assert db._engine is None


def test_get_database_engine_rejects_blank_database_segment_encoded_whitespace(monkeypatch: pytest.MonkeyPatch) -> None:
    db._engine = None
    db._session_factory = None

    monkeypatch.setattr(
        db,
        "get_settings",
        lambda: type(
            "Settings",
            (),
            {"database_url": "postgresql+psycopg://postgres@/%20"},
        )(),
    )

    with pytest.raises(ValueError, match="rendered Postgres database URL"):
        db.get_database_engine()

    assert db._engine is None


def test_get_database_engine_accepts_valid_postgres_database_url(monkeypatch: pytest.MonkeyPatch) -> None:
    db._engine = None
    db._session_factory = None

    monkeypatch.setattr(
        db,
        "get_settings",
        lambda: type(
            "Settings",
            (),
            {"database_url": "postgresql+psycopg://postgres@/gengate"},
        )(),
    )

    engine = db.get_database_engine()

    assert engine.url.drivername == "postgresql+psycopg"
    assert engine.url.database == "gengate"


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
