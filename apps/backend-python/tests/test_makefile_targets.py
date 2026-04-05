from pathlib import Path


TARGETS = {"test-fast", "test-smoke", "test-ci"}


def _backend_makefile_text() -> str:
    return (Path(__file__).resolve().parents[1] / "Makefile").read_text(encoding="utf-8")


def test_backend_makefile_contains_required_test_targets() -> None:
    makefile_text = _backend_makefile_text()

    for target in TARGETS:
        assert f"{target}:" in makefile_text


def test_backend_makefile_keeps_test_smoke_alias_contract() -> None:
    makefile_text = _backend_makefile_text()

    assert "test-smoke: test-fast" in makefile_text
