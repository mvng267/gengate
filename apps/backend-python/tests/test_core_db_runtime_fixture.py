import pytest

import app.core.db as db

from tests._core_db_fakes import EngineFake
from tests._core_db_runtime_state import assert_runtime_cache_cleared, seed_runtime_cache_for_test


def test_runtime_reset_fixture_runs_by_default() -> None:
    assert_runtime_cache_cleared()


def test_runtime_reset_fixture_resets_between_tests_step_one() -> None:
    seed_runtime_cache_for_test(engine=EngineFake(), session_factory=object())


def test_runtime_reset_fixture_resets_between_tests_step_two() -> None:
    assert_runtime_cache_cleared()


@pytest.mark.preserve_db_runtime_state
def test_runtime_reset_fixture_opt_out_preserves_state_in_test_scope() -> None:
    marker_engine = EngineFake()
    seed_runtime_cache_for_test(engine=marker_engine, session_factory=object())

    assert db._engine is marker_engine

    db.reset_database_runtime_state()
