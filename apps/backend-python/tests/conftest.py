import os


def pytest_configure() -> None:
    # Batch 26 parity: default to local unix-socket auth when no explicit Postgres
    # test DSNs are provided. This keeps local runs compatible with instances
    # where the `postgres` role is absent and only the OS user role exists.
    os.environ.setdefault("GENGATE_TEST_POSTGRES_ADMIN_URL", "postgresql:///postgres")
    os.environ.setdefault(
        "GENGATE_TEST_POSTGRES_DATABASE_URL_TEMPLATE",
        "postgresql+psycopg:///{database_name}",
    )
