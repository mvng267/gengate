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


def test_get_database_engine_rejects_blank_database_segment_encoded_whitespace(monkeypatch: pytest.MonkeyPatch) -> None:
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


def test_get_db_session_yields_and_closes_for_valid_database_url(monkeypatch: pytest.MonkeyPatch) -> None:
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


class _FakeEngine:
    def __init__(self) -> None:
        self.disposed = False

    def dispose(self) -> None:
        self.disposed = True


def test_reset_database_runtime_state_disposes_active_engine() -> None:
    fake_engine = _FakeEngine()
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


class _FakeEngineWithDisposeError:
    def __init__(self) -> None:
        self.dispose_called = False

    def dispose(self) -> None:
        self.dispose_called = True
        raise RuntimeError("dispose boom")


def test_reset_database_runtime_state_clears_cache_even_when_dispose_raises() -> None:
    fake_engine = _FakeEngineWithDisposeError()
    db._engine = fake_engine  # type: ignore[assignment]
    db._session_factory = object()  # type: ignore[assignment]

    with pytest.raises(RuntimeError, match="dispose boom"):
        db.reset_database_runtime_state()

    assert fake_engine.dispose_called is True
    assert db._engine is None
    assert db._session_factory is None



def test_reset_database_runtime_state_can_rebuild_after_dispose_failure(monkeypatch: pytest.MonkeyPatch) -> None:
    fake_engine = _FakeEngineWithDisposeError()
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


class _FakeSessionCommitError(_FakeSession):
    def commit(self) -> None:
        raise RuntimeError("commit boom")


def test_get_db_session_rolls_back_and_closes_when_commit_raises(monkeypatch: pytest.MonkeyPatch) -> None:
    fake_session = _FakeSessionCommitError()

    monkeypatch.setattr(db, "get_session_factory", lambda: lambda: fake_session)

    generator = db.get_db_session()
    yielded = next(generator)

    assert yielded is fake_session

    with pytest.raises(RuntimeError, match="commit boom"):
        next(generator)

    assert fake_session.committed is False
    assert fake_session.rolled_back is True
    assert fake_session.closed is True


class _FakeSessionRollbackError(_FakeSession):
    def rollback(self) -> None:
        self.rolled_back = True
        raise RuntimeError("rollback boom")


def test_get_db_session_propagates_rollback_error_with_original_exception_chained(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    fake_session = _FakeSessionRollbackError()

    monkeypatch.setattr(db, "get_session_factory", lambda: lambda: fake_session)

    generator = db.get_db_session()
    next(generator)

    with pytest.raises(RuntimeError, match="rollback boom") as exc_info:
        generator.throw(RuntimeError("consumer boom"))

    assert exc_info.value.__cause__ is not None
    assert str(exc_info.value.__cause__) == "consumer boom"
    assert fake_session.committed is False
    assert fake_session.rolled_back is True
    assert fake_session.closed is True


class _FakeSessionCommitAndRollbackError(_FakeSession):
    def commit(self) -> None:
        raise RuntimeError("commit boom")

    def rollback(self) -> None:
        self.rolled_back = True
        raise RuntimeError("rollback boom")


def test_get_db_session_chains_commit_error_when_rollback_also_fails(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    fake_session = _FakeSessionCommitAndRollbackError()

    monkeypatch.setattr(db, "get_session_factory", lambda: lambda: fake_session)

    generator = db.get_db_session()
    next(generator)

    with pytest.raises(RuntimeError, match="rollback boom") as exc_info:
        next(generator)

    assert exc_info.value.__cause__ is not None
    assert str(exc_info.value.__cause__) == "commit boom"
    assert fake_session.committed is False
    assert fake_session.rolled_back is True
    assert fake_session.closed is True


@pytest.mark.parametrize(
    ("mode", "expected_cause"),
    [
        ("consumer", "consumer boom"),
        ("commit", "commit boom"),
    ],
)
def test_get_db_session_exception_precedence_contract_guard(
    mode: str,
    expected_cause: str,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    if mode == "commit":
        fake_session: _FakeSession = _FakeSessionCommitAndRollbackError()
    else:
        fake_session = _FakeSessionRollbackError()

    monkeypatch.setattr(db, "get_session_factory", lambda: lambda: fake_session)

    generator = db.get_db_session()
    next(generator)

    if mode == "commit":
        with pytest.raises(RuntimeError, match="rollback boom") as exc_info:
            next(generator)
    else:
        with pytest.raises(RuntimeError, match="rollback boom") as exc_info:
            generator.throw(RuntimeError("consumer boom"))

    assert exc_info.value.__cause__ is not None
    assert str(exc_info.value.__cause__) == expected_cause
    assert fake_session.committed is False
    assert fake_session.rolled_back is True
    assert fake_session.closed is True
