.PHONY: test test-smoke test-fast test-core-db test-policy test-url-gate test-db-lifecycle

# Run full backend-python test suite.
test:
	. .venv/bin/activate && pytest -q

# Run focused policy/fixture marker guard tests.
test-policy:
	. .venv/bin/activate && pytest -q \
		tests/test_pytest_marker_policy.py \
		tests/test_core_db_runtime_fixture.py

# Run focused core DB runtime/fixture contract suite.
test-core-db:
	. .venv/bin/activate && pytest -q \
		tests/test_core_db_runtime_fixture.py \
		tests/test_core_db_engine_factory.py \
		tests/test_core_db_session_lifecycle.py \
		tests/test_core_db_reset.py \
		tests/test_core_db_fake_imports.py

# Run focused DB runtime lifecycle coverage (engine/factory/session/reset).
test-db-lifecycle:
	. .venv/bin/activate && pytest -q \
		tests/test_core_db_engine_factory.py \
		tests/test_core_db_session_lifecycle.py \
		tests/test_core_db_reset.py

# Run focused URL gate coverage (postgres URL parsing + alembic env gate).
test-url-gate:
	. .venv/bin/activate && pytest -q \
		tests/test_postgres_urls.py \
		tests/test_alembic_env.py

# Run fast gate (policy + DB lifecycle + URL gate).
test-fast:
	. .venv/bin/activate && pytest -q \
		tests/test_pytest_marker_policy.py \
		tests/test_core_db_runtime_fixture.py \
		tests/test_core_db_engine_factory.py \
		tests/test_core_db_session_lifecycle.py \
		tests/test_core_db_reset.py \
		tests/test_postgres_urls.py \
		tests/test_alembic_env.py

# Run focused smoke suite for DB runtime state + marker policy + URL gate.
test-smoke:
	. .venv/bin/activate && pytest -q \
		tests/test_pytest_marker_policy.py \
		tests/test_core_db_runtime_fixture.py \
		tests/test_core_db_engine_factory.py \
		tests/test_core_db_session_lifecycle.py \
		tests/test_core_db_reset.py \
		tests/test_postgres_urls.py \
		tests/test_alembic_env.py
