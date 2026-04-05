.PHONY: test test-smoke test-core-db

# Run full backend-python test suite.
test:
	. .venv/bin/activate && pytest -q

# Run focused core DB runtime/fixture contract suite.
test-core-db:
	. .venv/bin/activate && pytest -q \
		tests/test_core_db_runtime_fixture.py \
		tests/test_core_db_engine_factory.py \
		tests/test_core_db_session_lifecycle.py \
		tests/test_core_db_reset.py \
		tests/test_core_db_fake_imports.py

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
