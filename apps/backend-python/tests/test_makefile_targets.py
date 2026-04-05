from pathlib import Path


TARGETS = {"test-fast", "test-smoke", "test-ci"}


def test_backend_makefile_contains_required_test_targets() -> None:
    makefile_text = (Path(__file__).resolve().parents[1] / "Makefile").read_text(encoding="utf-8")

    for target in TARGETS:
        assert f"{target}:" in makefile_text
