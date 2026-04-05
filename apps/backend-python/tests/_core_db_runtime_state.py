"""Test-only helpers for core DB runtime cache assertions.

Centralizes direct access to app.core.db private globals (_engine,
_session_factory) so behavior tests stay focused on contract, not internals.
"""

from typing import Any

import app.core.db as db


def assert_runtime_cache_cleared() -> None:
    assert db._engine is None
    assert db._session_factory is None


def assert_runtime_engine_cached() -> None:
    assert db._engine is not None


def seed_runtime_cache_for_test(*, engine: Any, session_factory: Any) -> None:
    db._engine = engine  # type: ignore[assignment]
    db._session_factory = session_factory  # type: ignore[assignment]
