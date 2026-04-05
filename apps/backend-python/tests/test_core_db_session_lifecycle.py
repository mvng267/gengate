import pytest

import app.core.db as db


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
