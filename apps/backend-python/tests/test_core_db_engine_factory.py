import pytest

import app.core.db as db


def test_get_database_engine_rejects_encoded_slash_database_url(monkeypatch: pytest.MonkeyPatch) -> None:
    db.reset_database_runtime_state()

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
    db.reset_database_runtime_state()

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
    db.reset_database_runtime_state()

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


def test_get_database_engine_rejects_blank_database_segment_encoded_whitespace(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    db.reset_database_runtime_state()

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
    db.reset_database_runtime_state()

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
    db.reset_database_runtime_state()

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


def test_get_session_factory_rejects_invalid_postgres_url_without_caching_factory(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    db.reset_database_runtime_state()

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
        db.get_session_factory()

    assert db._engine is None
    assert db._session_factory is None


def test_get_session_factory_caches_factory_for_valid_postgres_url(monkeypatch: pytest.MonkeyPatch) -> None:
    db.reset_database_runtime_state()

    monkeypatch.setattr(
        db,
        "get_settings",
        lambda: type(
            "Settings",
            (),
            {"database_url": "postgresql+psycopg://postgres@/gengate"},
        )(),
    )

    first_factory = db.get_session_factory()
    second_factory = db.get_session_factory()

    assert first_factory is second_factory
    assert db._engine is not None


def test_get_db_session_raises_without_creating_cache_when_database_url_invalid(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    db.reset_database_runtime_state()

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
        next(db.get_db_session())

    assert db._engine is None
    assert db._session_factory is None
