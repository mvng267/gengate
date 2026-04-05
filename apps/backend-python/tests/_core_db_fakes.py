class FakeSession:
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


class FakeSessionCommitError(FakeSession):
    def commit(self) -> None:
        raise RuntimeError("commit boom")


class FakeSessionRollbackError(FakeSession):
    def rollback(self) -> None:
        self.rolled_back = True
        raise RuntimeError("rollback boom")


class FakeSessionCommitAndRollbackError(FakeSession):
    def commit(self) -> None:
        raise RuntimeError("commit boom")

    def rollback(self) -> None:
        self.rolled_back = True
        raise RuntimeError("rollback boom")


class FakeEngine:
    def __init__(self) -> None:
        self.disposed = False

    def dispose(self) -> None:
        self.disposed = True


class FakeEngineWithDisposeError:
    def __init__(self) -> None:
        self.dispose_called = False

    def dispose(self) -> None:
        self.dispose_called = True
        raise RuntimeError("dispose boom")
