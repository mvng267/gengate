from pathlib import Path


def test_pytest_config_enforces_strict_markers() -> None:
    pyproject_path = Path(__file__).resolve().parents[1] / "pyproject.toml"
    pyproject_text = pyproject_path.read_text(encoding="utf-8")

    assert 'addopts = "--strict-markers"' in pyproject_text
