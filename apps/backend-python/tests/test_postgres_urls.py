import pytest

from app.core.postgres_urls import (
    build_postgres_test_urls,
    is_postgres_url,
    postgres_admin_url_from_env,
    postgres_url_scheme,
    validate_postgres_database_url_if_needed,
    validate_postgres_url_path,
)


def test_postgres_admin_url_defaults_to_unix_socket() -> None:
    assert postgres_admin_url_from_env(environ={}) == "postgresql:///postgres"


def test_postgres_admin_url_strips_whitespace() -> None:
    assert (
        postgres_admin_url_from_env(environ={"GENGATE_POSTGRES_ADMIN_URL": "  postgresql:///postgres  "})
        == "postgresql:///postgres"
    )


def test_postgres_admin_url_falls_back_when_blank() -> None:
    assert postgres_admin_url_from_env(environ={"GENGATE_POSTGRES_ADMIN_URL": "   "}) == "postgresql:///postgres"


def test_validate_postgres_url_path_accepts_single_segment() -> None:
    validate_postgres_url_path("postgresql://postgres@/gengate", label="admin")
    validate_postgres_url_path("postgresql+psycopg://postgres@/gengate_test", label="database")


def test_validate_postgres_url_path_rejects_encoded_slash_segment() -> None:
    with pytest.raises(ValueError, match="rendered Postgres database URL"):
        validate_postgres_url_path("postgresql+psycopg://postgres@/gengate%2Farchive", label="database")


def test_validate_postgres_database_url_if_needed_rejects_invalid_postgres_url() -> None:
    with pytest.raises(ValueError, match="rendered Postgres database URL"):
        validate_postgres_database_url_if_needed("postgresql+psycopg://postgres@/gengate%2Farchive")


def test_validate_postgres_database_url_if_needed_skips_non_postgres_url() -> None:
    validate_postgres_database_url_if_needed("sqlite+pysqlite:///:memory:")


def test_postgres_url_scheme_extracts_scheme() -> None:
    assert postgres_url_scheme("postgresql+psycopg://postgres@/gengate") == "postgresql+psycopg"


def test_is_postgres_url_true_for_postgresql_variants() -> None:
    assert is_postgres_url("postgresql://postgres@/gengate")
    assert is_postgres_url("postgresql+psycopg://postgres@/gengate")


def test_is_postgres_url_false_for_non_postgres_scheme() -> None:
    assert not is_postgres_url("sqlite+pysqlite:///:memory:")


def test_build_postgres_test_urls_default_to_admin_role_and_db() -> None:
    admin_url, database_url = build_postgres_test_urls("gengate_batch28_default", environ={})

    assert admin_url == "postgresql://postgres@/postgres"
    assert database_url == "postgresql+psycopg://postgres@/gengate_batch28_default"


def test_build_postgres_test_urls_allow_role_and_db_override() -> None:
    admin_url, database_url = build_postgres_test_urls(
        "gengate_batch28_override",
        environ={
            "GENGATE_TEST_POSTGRES_ADMIN_ROLE": "gengate_admin",
            "GENGATE_TEST_POSTGRES_ADMIN_DATABASE": "gengate_maintenance",
        },
    )

    assert admin_url == "postgresql://gengate_admin@/gengate_maintenance"
    assert database_url == "postgresql+psycopg://gengate_admin@/gengate_batch28_override"


def test_build_postgres_test_urls_require_database_name_in_template() -> None:
    with pytest.raises(ValueError, match="database_name"):
        build_postgres_test_urls(
            "gengate_batch29_missing_name",
            environ={"GENGATE_TEST_POSTGRES_DATABASE_URL_TEMPLATE": "postgresql+psycopg://{admin_role}@/gengate_fixed"},
        )


def test_build_postgres_test_urls_reject_invalid_database_url_template() -> None:
    with pytest.raises(ValueError, match="GENGATE_TEST_POSTGRES_DATABASE_URL_TEMPLATE"):
        build_postgres_test_urls(
            "gengate_batch29_invalid",
            environ={"GENGATE_TEST_POSTGRES_DATABASE_URL_TEMPLATE": "postgresql+psycopg://{admin_role}@/{bad_name}"},
        )


def test_build_postgres_test_urls_reject_malformed_format_database_url_template() -> None:
    with pytest.raises(ValueError, match="GENGATE_TEST_POSTGRES_DATABASE_URL_TEMPLATE"):
        build_postgres_test_urls(
            "gengate_batch29_malformed_template",
            environ={
                "GENGATE_TEST_POSTGRES_DATABASE_URL_TEMPLATE": "postgresql+psycopg://{admin_role}@/{database_name}{"
            },
        )


def test_build_postgres_test_urls_reject_positional_database_url_template() -> None:
    with pytest.raises(ValueError, match="GENGATE_TEST_POSTGRES_DATABASE_URL_TEMPLATE"):
        build_postgres_test_urls(
            "gengate_batch29_positional_template",
            environ={"GENGATE_TEST_POSTGRES_DATABASE_URL_TEMPLATE": "postgresql+psycopg://{0}@/{database_name}"},
        )


def test_build_postgres_test_urls_require_database_path_segment() -> None:
    with pytest.raises(ValueError, match="rendered Postgres database URL"):
        build_postgres_test_urls(
            "gengate_batch30_missing_db_segment",
            environ={"GENGATE_TEST_POSTGRES_DATABASE_URL_TEMPLATE": "postgresql+psycopg://{database_name}@/"},
        )


def test_build_postgres_test_urls_reject_malformed_admin_url() -> None:
    with pytest.raises(ValueError, match="rendered Postgres admin URL"):
        build_postgres_test_urls(
            "gengate_batch31_invalid_admin_url",
            environ={
                "GENGATE_TEST_POSTGRES_ADMIN_URL": "postgresql://",
                "GENGATE_TEST_POSTGRES_DATABASE_URL_TEMPLATE": "postgresql+psycopg://{admin_role}@/{database_name}",
            },
        )


def test_build_postgres_test_urls_reject_admin_url_without_database_path() -> None:
    with pytest.raises(ValueError, match="rendered Postgres admin URL"):
        build_postgres_test_urls(
            "gengate_batch31_missing_admin_db_segment",
            environ={
                "GENGATE_TEST_POSTGRES_ADMIN_URL": "postgresql://postgres@/",
                "GENGATE_TEST_POSTGRES_DATABASE_URL_TEMPLATE": "postgresql+psycopg://{admin_role}@/{database_name}",
            },
        )


def test_build_postgres_test_urls_reject_admin_url_with_invalid_scheme() -> None:
    with pytest.raises(ValueError, match="rendered Postgres admin URL"):
        build_postgres_test_urls(
            "gengate_batch31_invalid_admin_scheme",
            environ={
                "GENGATE_TEST_POSTGRES_ADMIN_URL": "mysql://root@/postgres",
                "GENGATE_TEST_POSTGRES_DATABASE_URL_TEMPLATE": "postgresql+psycopg://{admin_role}@/{database_name}",
            },
        )


def test_build_postgres_test_urls_reject_admin_url_without_scheme() -> None:
    with pytest.raises(ValueError, match="rendered Postgres admin URL"):
        build_postgres_test_urls(
            "gengate_batch31_admin_missing_scheme",
            environ={
                "GENGATE_TEST_POSTGRES_ADMIN_URL": "postgres@/postgres",
                "GENGATE_TEST_POSTGRES_DATABASE_URL_TEMPLATE": "postgresql+psycopg://{admin_role}@/{database_name}",
            },
        )


def test_build_postgres_test_urls_reject_database_url_with_invalid_scheme() -> None:
    with pytest.raises(ValueError, match="rendered Postgres database URL"):
        build_postgres_test_urls(
            "gengate_batch31_database_invalid_scheme",
            environ={"GENGATE_TEST_POSTGRES_DATABASE_URL_TEMPLATE": "mysql://{admin_role}@/{database_name}"},
        )


def test_build_postgres_test_urls_reject_admin_url_with_multiple_path_segments() -> None:
    with pytest.raises(ValueError, match="rendered Postgres admin URL"):
        build_postgres_test_urls(
            "gengate_batch32_multi_admin_path",
            environ={
                "GENGATE_TEST_POSTGRES_ADMIN_URL": "postgresql://postgres@/postgres/archive",
                "GENGATE_TEST_POSTGRES_DATABASE_URL_TEMPLATE": "postgresql+psycopg://{admin_role}@/{database_name}",
            },
        )


def test_build_postgres_test_urls_reject_database_url_with_multiple_path_segments() -> None:
    with pytest.raises(ValueError, match="rendered Postgres database URL"):
        build_postgres_test_urls(
            "gengate_batch32_multi_database_path",
            environ={"GENGATE_TEST_POSTGRES_DATABASE_URL_TEMPLATE": "postgresql+psycopg://{admin_role}@/{database_name}/archive"},
        )


def test_build_postgres_test_urls_reject_encoded_slash_database_path() -> None:
    with pytest.raises(ValueError, match="rendered Postgres database URL"):
        build_postgres_test_urls(
            "gengate_batch33_encoded_database_path",
            environ={
                "GENGATE_TEST_POSTGRES_DATABASE_URL_TEMPLATE": "postgresql+psycopg://{admin_role}@/{database_name}%2Farchive"
            },
        )
