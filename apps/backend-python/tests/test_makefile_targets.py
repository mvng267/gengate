from tests._makefile_target_helpers import (
    backend_makefile_text,
    expanded_explicit_test_files,
    extract_explicit_test_files,
    make_variable_block,
)


TARGETS = {"test-fast", "test-smoke", "test-ci"}


def test_backend_makefile_contains_required_test_targets() -> None:
    makefile_text = backend_makefile_text()

    for target in TARGETS:
        assert f"{target}:" in makefile_text


def test_backend_makefile_keeps_test_smoke_alias_contract() -> None:
    makefile_text = backend_makefile_text()

    assert "test-smoke: test-fast" in makefile_text


def test_backend_makefile_keeps_test_policy_group_contract() -> None:
    makefile_text = backend_makefile_text()
    test_policy_block = make_variable_block(makefile_text, "TEST_POLICY")

    assert "tests/test_pytest_marker_policy.py" in test_policy_block
    assert "tests/test_core_db_runtime_fixture.py" in test_policy_block


def test_backend_makefile_keeps_test_core_db_group_contract() -> None:
    makefile_text = backend_makefile_text()
    test_core_db_block = make_variable_block(makefile_text, "TEST_CORE_DB")

    assert "tests/test_core_db_runtime_fixture.py" in test_core_db_block
    assert "tests/test_core_db_engine_factory.py" in test_core_db_block
    assert "tests/test_core_db_session_lifecycle.py" in test_core_db_block
    assert "tests/test_core_db_reset.py" in test_core_db_block
    assert "tests/test_core_db_fake_imports.py" in test_core_db_block


def test_backend_makefile_keeps_test_db_lifecycle_group_contract() -> None:
    makefile_text = backend_makefile_text()
    test_db_lifecycle_block = make_variable_block(makefile_text, "TEST_DB_LIFECYCLE")

    assert "tests/test_core_db_engine_factory.py" in test_db_lifecycle_block
    assert "tests/test_core_db_session_lifecycle.py" in test_db_lifecycle_block
    assert "tests/test_core_db_reset.py" in test_db_lifecycle_block


def test_backend_makefile_keeps_test_url_gate_group_contract() -> None:
    makefile_text = backend_makefile_text()
    test_url_gate_block = make_variable_block(makefile_text, "TEST_URL_GATE")

    assert "tests/test_postgres_urls.py" in test_url_gate_block
    assert "tests/test_alembic_env.py" in test_url_gate_block


def test_backend_makefile_keeps_test_schema_group_contract() -> None:
    makefile_text = backend_makefile_text()
    test_schema_block = make_variable_block(makefile_text, "TEST_SCHEMA")

    assert "tests/test_schema_models.py" in test_schema_block
    assert "$(TEST_URL_GATE)" in test_schema_block


def test_backend_makefile_keeps_test_contracts_group_contract() -> None:
    makefile_text = backend_makefile_text()
    test_contracts_block = make_variable_block(makefile_text, "TEST_CONTRACTS")

    assert "tests/test_batch6_contracts.py" in test_contracts_block
    assert "tests/test_batch7_conversations_api.py" in test_contracts_block
    assert "tests/test_batch10_sessions_api.py" in test_contracts_block
    assert "tests/test_messages_api.py" in test_contracts_block
    assert "tests/test_profiles_api.py" in test_contracts_block


def test_backend_makefile_keeps_critical_groups_non_empty() -> None:
    makefile_text = backend_makefile_text()

    for group_name in ["TEST_POLICY", "TEST_URL_GATE", "TEST_CORE_DB", "TEST_CONTRACTS"]:
        group_block = make_variable_block(makefile_text, group_name)
        assert extract_explicit_test_files(group_block), f"{group_name} must stay non-empty"


def test_backend_makefile_avoids_duplicate_explicit_tests_in_schema_group() -> None:
    makefile_text = backend_makefile_text()
    test_schema_block = make_variable_block(makefile_text, "TEST_SCHEMA")
    schema_files = extract_explicit_test_files(test_schema_block)

    assert len(schema_files) == len(set(schema_files))


def test_backend_makefile_avoids_duplicate_explicit_tests_in_contracts_group() -> None:
    makefile_text = backend_makefile_text()
    test_contracts_block = make_variable_block(makefile_text, "TEST_CONTRACTS")
    contract_files = extract_explicit_test_files(test_contracts_block)

    assert len(contract_files) == len(set(contract_files))


def test_backend_makefile_avoids_duplicate_explicit_tests_in_core_db_group() -> None:
    makefile_text = backend_makefile_text()
    test_core_db_block = make_variable_block(makefile_text, "TEST_CORE_DB")
    core_db_files = extract_explicit_test_files(test_core_db_block)

    assert len(core_db_files) == len(set(core_db_files))


def test_backend_makefile_keeps_test_fast_composition_contract() -> None:
    makefile_text = backend_makefile_text()
    test_fast_block = make_variable_block(makefile_text, "TEST_FAST")

    assert "$(TEST_POLICY)" in test_fast_block
    assert "tests/test_core_db_engine_factory.py" in test_fast_block
    assert "tests/test_core_db_session_lifecycle.py" in test_fast_block
    assert "tests/test_core_db_reset.py" in test_fast_block
    assert "$(TEST_URL_GATE)" in test_fast_block


def test_backend_makefile_keeps_test_ci_composition_contract() -> None:
    makefile_text = backend_makefile_text()
    test_ci_block = make_variable_block(makefile_text, "TEST_CI")

    assert "$(TEST_FAST)" in test_ci_block
    assert "tests/test_schema_models.py" in test_ci_block
    assert "$(TEST_CONTRACTS)" in test_ci_block


def test_backend_makefile_avoids_duplicate_explicit_tests_after_expanding_fast_and_ci() -> None:
    makefile_text = backend_makefile_text()

    for variable_name in ["TEST_FAST", "TEST_CI"]:
        expanded_files = expanded_explicit_test_files(makefile_text, variable_name)
        assert len(expanded_files) == len(set(expanded_files))
