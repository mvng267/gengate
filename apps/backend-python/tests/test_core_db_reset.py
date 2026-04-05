import pytest

import app.core.db as db
from tests._core_db_fakes import EngineFake, EngineDisposeErrorFake


def test_reset_database_runtime_state_is_idempotent() -> None:
    db.reset_database_runtime_state()
    db.reset_database_runtime_state()

    assert db._engine is None
    assert db._session_factory is None


def test_reset_database_runtime_state_rebuilds_engine_for_new_database_url(monkeypatch: pytest.MonkeyPatch) -> None:
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
    first_engine = db.get_database_engine()
    first_url = str(first_engine.url)

    db.reset_database_runtime_state()

    monkeypatch.setattr(
        db,
        "get_settings",
        lambda: type(
            "Settings",
            (),
            {"database_url": "sqlite+pysqlite:///./tmp-db-reset.sqlite3"},
        )(),
    )
    second_engine = db.get_database_engine()
    second_url = str(second_engine.url)

    assert first_engine is not second_engine
    assert first_url != second_url

    db.reset_database_runtime_state()


def test_reset_database_runtime_state_disposes_active_engine() -> None:
    fake_engine = EngineFake()
    db._engine = fake_engine  # type: ignore[assignment]
    db._session_factory = object()  # type: ignore[assignment]

    db.reset_database_runtime_state()

    assert fake_engine.disposed is True
    assert db._engine is None
    assert db._session_factory is None


def test_reset_database_runtime_state_rebuilds_session_factory_after_reset(monkeypatch: pytest.MonkeyPatch) -> None:
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
    first_factory = db.get_session_factory()
    first_bind = str(first_factory.kw["bind"].url)

    db.reset_database_runtime_state()

    monkeypatch.setattr(
        db,
        "get_settings",
        lambda: type(
            "Settings",
            (),
            {"database_url": "sqlite+pysqlite:///./tmp-session-reset.sqlite3"},
        )(),
    )
    second_factory = db.get_session_factory()
    second_bind = str(second_factory.kw["bind"].url)

    assert first_factory is not second_factory
    assert first_bind != second_bind

    db.reset_database_runtime_state()


def test_reset_database_runtime_state_clears_cache_even_when_dispose_raises() -> None:
    fake_engine = EngineDisposeErrorFake()
    db._engine = fake_engine  # type: ignore[assignment]
    db._session_factory = object()  # type: ignore[assignment]

    with pytest.raises(RuntimeError, match="dispose boom"):
        db.reset_database_runtime_state()

    assert fake_engine.dispose_called is True
    assert db._engine is None
    assert db._session_factory is None


def test_reset_database_runtime_state_can_rebuild_after_dispose_failure(monkeypatch: pytest.MonkeyPatch) -> None:
    fake_engine = EngineDisposeErrorFake()
    db._engine = fake_engine  # type: ignore[assignment]
    db._session_factory = object()  # type: ignore[assignment]

    with pytest.raises(RuntimeError, match="dispose boom"):
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

    rebuilt_engine = db.get_database_engine()

    assert rebuilt_engine.url.drivername == "sqlite+pysqlite"

    db.reset_database_runtime_state()
