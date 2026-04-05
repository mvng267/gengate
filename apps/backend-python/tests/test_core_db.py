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


def test_get_session_factory_rejects_invalid_postgres_url_without_caching_factory(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
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
        db.get_session_factory()

    assert db._engine is None
    assert db._session_factory is None


def test_get_session_factory_caches_factory_for_valid_postgres_url(monkeypatch: pytest.MonkeyPatch) -> None:
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

    first_factory = db.get_session_factory()
    second_factory = db.get_session_factory()

    assert first_factory is second_factory
    assert db._engine is not None


def test_get_db_session_raises_without_creating_cache_when_database_url_invalid(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
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
        next(db.get_db_session())

    assert db._engine is None
    assert db._session_factory is None


def test_get_db_session_yields_and_closes_for_valid_database_url(monkeypatch: pytest.MonkeyPatch) -> None:
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

    generator = db.get_db_session()
    session = next(generator)

    assert session.is_active

    with pytest.raises(StopIteration):
        next(generator)


class _FakeSession:
    def __init__(self) -> None:
        self.committed = False
        self.rolled_back = False
        self.closed = False

    @property
    def is_active(self) -> bool:
        return not self.closed

    def commit(self) -> None:
        self.committed = True

    def rollback(self) -> None:
        self.rolled_back = True

    def close(self) -> None:
        self.closed = True


def test_get_db_session_commits_and_closes_on_normal_exit(monkeypatch: pytest.MonkeyPatch) -> None:
    fake_session = _FakeSession()

    monkeypatch.setattr(db, "get_session_factory", lambda: lambda: fake_session)

    generator = db.get_db_session()
    yielded_session = next(generator)

    assert yielded_session is fake_session

    with pytest.raises(StopIteration):
        next(generator)

    assert fake_session.committed is True
    assert fake_session.rolled_back is False
    assert fake_session.closed is True


def test_get_db_session_rolls_back_and_closes_when_consumer_raises(monkeypatch: pytest.MonkeyPatch) -> None:
    fake_session = _FakeSession()

    monkeypatch.setattr(db, "get_session_factory", lambda: lambda: fake_session)

    generator = db.get_db_session()
    next(generator)

    with pytest.raises(RuntimeError, match="boom"):
        generator.throw(RuntimeError("boom"))

    assert fake_session.committed is False
    assert fake_session.rolled_back is True
    assert fake_session.closed is True
