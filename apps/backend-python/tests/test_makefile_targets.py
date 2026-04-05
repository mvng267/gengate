from pathlib import Path


TARGETS = {"test-fast", "test-smoke", "test-ci"}


def _backend_makefile_text() -> str:
    return (Path(__file__).resolve().parents[1] / "Makefile").read_text(encoding="utf-8")


def _make_variable_block(makefile_text: str, variable_name: str) -> str:
    start = makefile_text.index(f"{variable_name} =")
    tail = makefile_text[start:]
    split_marker = "\n\n#"
    end_rel = tail.find(split_marker)
    if end_rel == -1:
        return tail
    return tail[:end_rel]


def test_backend_makefile_contains_required_test_targets() -> None:
    makefile_text = _backend_makefile_text()

    for target in TARGETS:
        assert f"{target}:" in makefile_text


def test_backend_makefile_keeps_test_smoke_alias_contract() -> None:
    makefile_text = _backend_makefile_text()

    assert "test-smoke: test-fast" in makefile_text


def test_backend_makefile_keeps_test_fast_composition_contract() -> None:
    makefile_text = _backend_makefile_text()
    test_fast_block = _make_variable_block(makefile_text, "TEST_FAST")

    assert "$(TEST_POLICY)" in test_fast_block
    assert "tests/test_core_db_engine_factory.py" in test_fast_block
    assert "tests/test_core_db_session_lifecycle.py" in test_fast_block
    assert "tests/test_core_db_reset.py" in test_fast_block
    assert "$(TEST_URL_GATE)" in test_fast_block


def test_backend_makefile_keeps_test_ci_composition_contract() -> None:
    makefile_text = _backend_makefile_text()
    test_ci_block = _make_variable_block(makefile_text, "TEST_CI")

    assert "$(TEST_FAST)" in test_ci_block
    assert "tests/test_schema_models.py" in test_ci_block
    assert "$(TEST_CONTRACTS)" in test_ci_block
