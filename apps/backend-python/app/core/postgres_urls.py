from collections.abc import Mapping
from urllib.parse import unquote, urlsplit
import os


def postgres_admin_url_from_env(*, environ: Mapping[str, str] | None = None) -> str:
    source = os.environ if environ is None else environ
    admin_url = source.get("GENGATE_POSTGRES_ADMIN_URL", "postgresql:///postgres").strip()
    if not admin_url:
        return "postgresql:///postgres"
    return admin_url


def validate_postgres_url_path(url: str, *, label: str) -> None:
    parsed_url = urlsplit(url)
    raw_path = parsed_url.path.strip()
    decoded_path = unquote(raw_path).strip()
    path = decoded_path or raw_path
    segments = [segment for segment in path.split("/") if segment]

    if (
        not url
        or parsed_url.scheme not in {"postgresql", "postgresql+psycopg"}
        or len(segments) != 1
        or not segments[0].strip()
    ):
        raise ValueError(f"Invalid rendered Postgres {label} URL")


def validate_postgres_database_url_if_needed(url: str) -> None:
    if urlsplit(url).scheme in {"postgresql", "postgresql+psycopg"}:
        validate_postgres_url_path(url, label="database")


def build_postgres_test_urls(
    database_name: str,
    *,
    environ: Mapping[str, str] | None = None,
) -> tuple[str, str]:
    source = os.environ if environ is None else environ

    admin_role = source.get("GENGATE_TEST_POSTGRES_ADMIN_ROLE", "postgres").strip() or "postgres"
    admin_database = source.get("GENGATE_TEST_POSTGRES_ADMIN_DATABASE", "postgres").strip() or "postgres"

    admin_url = source.get("GENGATE_TEST_POSTGRES_ADMIN_URL", "").strip()
    if not admin_url:
        admin_url = f"postgresql://{admin_role}@/{admin_database}"

    database_url_template = source.get("GENGATE_TEST_POSTGRES_DATABASE_URL_TEMPLATE", "").strip()
    if database_url_template:
        if "{database_name}" not in database_url_template:
            raise ValueError(
                "Invalid GENGATE_TEST_POSTGRES_DATABASE_URL_TEMPLATE: expected placeholders "
                "{database_name}, {admin_role}, {admin_database}"
            )
        try:
            database_url = database_url_template.format(
                database_name=database_name,
                admin_role=admin_role,
                admin_database=admin_database,
            )
        except (IndexError, KeyError, ValueError) as exc:
            raise ValueError(
                "Invalid GENGATE_TEST_POSTGRES_DATABASE_URL_TEMPLATE: expected placeholders "
                "{database_name}, {admin_role}, {admin_database}"
            ) from exc
    else:
        database_url = f"postgresql+psycopg://{admin_role}@/{database_name}"

    validate_postgres_url_path(admin_url, label="admin")
    validate_postgres_url_path(database_url, label="database")

    return admin_url, database_url
