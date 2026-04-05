"""Shared fake objects for core DB lifecycle tests.

These fakes are intentionally tiny and deterministic:
- Session fakes drive commit/rollback/close precedence behavior.
- Engine fakes drive reset/dispose cache behavior.
"""

class SessionFake:
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

class SessionCommitErrorFake(SessionFake):
    def commit(self) -> None:
        raise RuntimeError("commit boom")

class SessionRollbackErrorFake(SessionFake):
    def rollback(self) -> None:
        self.rolled_back = True
        raise RuntimeError("rollback boom")

class SessionCommitAndRollbackErrorFake(SessionFake):
    def commit(self) -> None:
        raise RuntimeError("commit boom")

    def rollback(self) -> None:
        self.rolled_back = True
        raise RuntimeError("rollback boom")

class EngineFake:
    def __init__(self) -> None:
        self.disposed = False

    def dispose(self) -> None:
        self.disposed = True

class EngineDisposeErrorFake:
    def __init__(self) -> None:
        self.dispose_called = False

    def dispose(self) -> None:
        self.dispose_called = True
        raise RuntimeError("dispose boom")
