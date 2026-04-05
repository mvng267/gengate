import pytest

import app.core.db as db
from tests._core_db_fakes import EngineFake, EngineDisposeErrorFake
from tests._core_db_runtime_state import assert_runtime_cache_cleared, seed_runtime_cache_for_test

def test_reset_database_runtime_state_is_idempotent() -> None:

    assert_runtime_cache_cleared()

def test_reset_database_runtime_state_rebuilds_engine_for_new_database_url(monkeypatch: pytest.MonkeyPatch) -> None:

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

def test_reset_database_runtime_state_disposes_active_engine() -> None:
    fake_engine = EngineFake()
    seed_runtime_cache_for_test(engine=fake_engine, session_factory=object())

    db.reset_database_runtime_state()

    assert fake_engine.disposed is True
    assert_runtime_cache_cleared()

def test_reset_database_runtime_state_rebuilds_session_factory_after_reset(monkeypatch: pytest.MonkeyPatch) -> None:

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

def test_reset_database_runtime_state_clears_cache_even_when_dispose_raises() -> None:
    fake_engine = EngineDisposeErrorFake()
    seed_runtime_cache_for_test(engine=fake_engine, session_factory=object())

    with pytest.raises(RuntimeError, match="dispose boom"):
        db.reset_database_runtime_state()

    assert fake_engine.dispose_called is True
    assert_runtime_cache_cleared()

def test_reset_database_runtime_state_can_rebuild_after_dispose_failure(monkeypatch: pytest.MonkeyPatch) -> None:
    fake_engine = EngineDisposeErrorFake()
    seed_runtime_cache_for_test(engine=fake_engine, session_factory=object())

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
