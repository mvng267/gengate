# Backend Python Test Notes

## Runtime DB cache reset marker

`tests/conftest.py` defines an autouse fixture that resets
`app.core.db` runtime cache (`_engine`, `_session_factory`) before and after
most tests.

Use marker `@pytest.mark.preserve_db_runtime_state` only when a test
*intentionally* needs to keep runtime cache state across its own steps.

- Default (no marker): auto reset enabled.
- With marker: test opts out of auto reset for that test only.

Current guard coverage for this behavior:
- `tests/test_core_db_runtime_fixture.py`

## Pytest marker policy

Backend tests run with `--strict-markers` (configured in `pyproject.toml`).

When adding a new custom marker:
1. Register it in `tests/conftest.py` via `config.addinivalue_line("markers", ...)`.
2. Add/adjust a guard test if marker behavior changes.

This ensures marker typos fail fast in CI/local runs.

## Quick smoke commands

Run fast gate (policy + DB lifecycle + URL gate):

```bash
source .venv/bin/activate
pytest -q \
  tests/test_pytest_marker_policy.py \
  tests/test_core_db_runtime_fixture.py \
  tests/test_core_db_engine_factory.py \
  tests/test_core_db_session_lifecycle.py \
  tests/test_core_db_reset.py \
  tests/test_postgres_urls.py \
  tests/test_alembic_env.py
```

Run full backend-python test suite:

```bash
source .venv/bin/activate
pytest -q
```


## Make targets

From `apps/backend-python/`:

```bash
make test-policy
make test-core-db
make test-db-lifecycle
make test-url-gate
make test-schema
make test-contracts
make test-fast
make test-smoke
make test
```
