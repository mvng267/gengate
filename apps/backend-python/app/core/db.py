from collections.abc import Generator
from sqlalchemy import create_engine
from sqlalchemy.engine import Engine
from sqlalchemy.orm import Session, sessionmaker

from app.core.config import get_settings
from app.core.postgres_urls import validate_postgres_database_url_if_needed

_engine: Engine | None = None
_session_factory: sessionmaker[Session] | None = None


def reset_database_runtime_state() -> None:
    """Reset cached SQLAlchemy engine/session factory state.

    The current engine is disposed first when present. If dispose raises, the
    error is propagated, but cached globals are still cleared via finally.
    """

    global _engine, _session_factory

    try:
        if _engine is not None:
            _engine.dispose()
    finally:
        _engine = None
        _session_factory = None


def get_database_engine() -> Engine:
    global _engine
    if _engine is None:
        settings = get_settings()
        validate_postgres_database_url_if_needed(settings.database_url)
        _engine = create_engine(settings.database_url, pool_pre_ping=True, future=True)
    return _engine


def get_session_factory() -> sessionmaker[Session]:
    global _session_factory
    if _session_factory is None:
        _session_factory = sessionmaker(
            bind=get_database_engine(),
            autocommit=False,
            autoflush=False,
            class_=Session,
        )
    return _session_factory


def get_db_session() -> Generator[Session, None, None]:
    session = get_session_factory()()
    try:
        yield session
        session.commit()
    except Exception:
        session.rollback()
        raise
    finally:
        session.close()
