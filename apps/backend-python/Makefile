.PHONY: test test-smoke test-fast test-core-db test-policy test-url-gate test-db-lifecycle test-contracts test-schema test-ci

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

# Run focused schema/migration + URL gate coverage.
test-schema:
	. .venv/bin/activate && pytest -q \
		tests/test_schema_models.py \
		tests/test_postgres_urls.py \
		tests/test_alembic_env.py

# Run focused URL gate coverage (postgres URL parsing + alembic env gate).
test-url-gate:
	. .venv/bin/activate && pytest -q \
		tests/test_postgres_urls.py \
		tests/test_alembic_env.py

# Run API/contract-heavy backend coverage.
test-contracts:
	. .venv/bin/activate && pytest -q \
		tests/test_batch6_contracts.py \
		tests/test_batch7_conversations_api.py \
		tests/test_batch9_blocks_moment_media_reactions_api.py \
		tests/test_batch10_sessions_api.py \
		tests/test_friendships_api.py \
		tests/test_locations_api.py \
		tests/test_location_audience_api.py \
		tests/test_messages_api.py \
		tests/test_moments_api.py \
		tests/test_notifications_security_api.py \
		tests/test_profiles_api.py

# Canonical smoke gate (policy + DB lifecycle + URL gate).
test-fast:
	. .venv/bin/activate && pytest -q \
		tests/test_pytest_marker_policy.py \
		tests/test_core_db_runtime_fixture.py \
		tests/test_core_db_engine_factory.py \
		tests/test_core_db_session_lifecycle.py \
		tests/test_core_db_reset.py \
		tests/test_postgres_urls.py \
		tests/test_alembic_env.py

# Backward-compatible alias for the canonical smoke gate.
test-smoke: test-fast

# CI-like gate without full long-tail local suite.
test-ci:
	. .venv/bin/activate && pytest -q \
		tests/test_pytest_marker_policy.py \
		tests/test_core_db_runtime_fixture.py \
		tests/test_core_db_engine_factory.py \
		tests/test_core_db_session_lifecycle.py \
		tests/test_core_db_reset.py \
		tests/test_schema_models.py \
		tests/test_postgres_urls.py \
		tests/test_alembic_env.py \
		tests/test_batch6_contracts.py \
		tests/test_batch7_conversations_api.py \
		tests/test_batch9_blocks_moment_media_reactions_api.py \
		tests/test_batch10_sessions_api.py \
		tests/test_friendships_api.py \
		tests/test_locations_api.py \
		tests/test_location_audience_api.py \
		tests/test_messages_api.py \
		tests/test_moments_api.py \
		tests/test_notifications_security_api.py \
		tests/test_profiles_api.py
