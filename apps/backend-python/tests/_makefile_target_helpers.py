from pathlib import Path


def backend_makefile_text() -> str:
    return (Path(__file__).resolve().parents[1] / "Makefile").read_text(encoding="utf-8")


def make_variable_block(makefile_text: str, variable_name: str) -> str:
    start = makefile_text.index(f"{variable_name} =")
    tail = makefile_text[start:]
    split_marker = "\n\n#"
    end_rel = tail.find(split_marker)
    if end_rel == -1:
        return tail
    return tail[:end_rel]


def extract_explicit_test_files(make_block: str) -> list[str]:
    files: list[str] = []
    for raw_line in make_block.splitlines():
        line = raw_line.strip().rstrip("\\").strip()
        if line.startswith("tests/"):
            files.append(line)
    return files


def expanded_explicit_test_files(makefile_text: str, variable_name: str) -> list[str]:
    variable_block = make_variable_block(makefile_text, variable_name)
    explicit_files = extract_explicit_test_files(variable_block)

    for raw_line in variable_block.splitlines():
        line = raw_line.strip().rstrip("\\").strip()
        if line.startswith("$(") and line.endswith(")"):
            nested_variable_name = line[2:-1]
            explicit_files.extend(expanded_explicit_test_files(makefile_text, nested_variable_name))

    return explicit_files
