from logging.config import fileConfig
from urllib.parse import urlsplit

from alembic import context
from sqlalchemy import engine_from_config, pool

from app.core.config import get_settings
from app.core.postgres_urls import validate_postgres_url_path
from app.models import all_models
from app.models.base import Base

config = context.config

if config.config_file_name is not None:
    fileConfig(config.config_file_name)

if not config.get_main_option("sqlalchemy.url"):
    settings = get_settings()
    config.set_main_option("sqlalchemy.url", settings.database_url)

target_metadata = Base.metadata


def _validate_alembic_database_url(url: str) -> None:
    if urlsplit(url).scheme in {"postgresql", "postgresql+psycopg"}:
        validate_postgres_url_path(url, label="database")


def run_migrations_offline() -> None:
    url = config.get_main_option("sqlalchemy.url")
    _validate_alembic_database_url(url)
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        compare_type=True,
    )

    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    url = config.get_main_option("sqlalchemy.url")
    _validate_alembic_database_url(url)

    connectable = engine_from_config(
        config.get_section(config.config_ini_section, {}),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    with connectable.connect() as connection:
        context.configure(
            connection=connection,
            target_metadata=target_metadata,
            compare_type=True,
        )

        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
