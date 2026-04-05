.PHONY: test test-smoke test-fast test-core-db test-policy test-url-gate test-db-lifecycle test-contracts test-schema test-ci

VENV_ACTIVATE = . .venv/bin/activate
PYTEST = $(VENV_ACTIVATE) && pytest -q

TEST_POLICY = \
	tests/test_pytest_marker_policy.py \
	tests/test_core_db_runtime_fixture.py

TEST_CORE_DB = \
	tests/test_core_db_runtime_fixture.py \
	tests/test_core_db_engine_factory.py \
	tests/test_core_db_session_lifecycle.py \
	tests/test_core_db_reset.py \
	tests/test_core_db_fake_imports.py

TEST_DB_LIFECYCLE = \
	tests/test_core_db_engine_factory.py \
	tests/test_core_db_session_lifecycle.py \
	tests/test_core_db_reset.py

TEST_URL_GATE = \
	tests/test_postgres_urls.py \
	tests/test_alembic_env.py

TEST_SCHEMA = \
	tests/test_schema_models.py \
	$(TEST_URL_GATE)

TEST_CONTRACTS = \
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

TEST_FAST = \
	$(TEST_POLICY) \
	tests/test_core_db_engine_factory.py \
	tests/test_core_db_session_lifecycle.py \
	tests/test_core_db_reset.py \
	$(TEST_URL_GATE)

TEST_CI = \
	$(TEST_FAST) \
	tests/test_schema_models.py \
	$(TEST_CONTRACTS)

# Run full backend-python test suite.
test:
	$(PYTEST)

# Run focused policy/fixture marker guard tests.
test-policy:
	$(PYTEST) $(TEST_POLICY)

# Run focused core DB runtime/fixture contract suite.
test-core-db:
	$(PYTEST) $(TEST_CORE_DB)

# Run focused DB runtime lifecycle coverage (engine/factory/session/reset).
test-db-lifecycle:
	$(PYTEST) $(TEST_DB_LIFECYCLE)

# Run focused schema/migration + URL gate coverage.
test-schema:
	$(PYTEST) $(TEST_SCHEMA)

# Run focused URL gate coverage (postgres URL parsing + alembic env gate).
test-url-gate:
	$(PYTEST) $(TEST_URL_GATE)

# Run API/contract-heavy backend coverage.
test-contracts:
	$(PYTEST) $(TEST_CONTRACTS)

# Canonical smoke gate (policy + DB lifecycle + URL gate).
test-fast:
	$(PYTEST) $(TEST_FAST)

# Backward-compatible alias for the canonical smoke gate.
test-smoke: test-fast

# CI-like gate without full long-tail local suite.
test-ci:
	$(PYTEST) $(TEST_CI)
