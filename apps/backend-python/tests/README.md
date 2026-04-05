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
