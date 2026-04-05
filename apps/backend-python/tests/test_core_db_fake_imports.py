from tests import _core_db_fakes


def test_core_db_fakes_exports_expected_classes() -> None:
    assert hasattr(_core_db_fakes, "SessionFake")
    assert hasattr(_core_db_fakes, "SessionCommitErrorFake")
    assert hasattr(_core_db_fakes, "SessionRollbackErrorFake")
    assert hasattr(_core_db_fakes, "SessionCommitAndRollbackErrorFake")
    assert hasattr(_core_db_fakes, "EngineFake")
    assert hasattr(_core_db_fakes, "EngineDisposeErrorFake")
