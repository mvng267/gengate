from dataclasses import dataclass

from app.core.config import get_settings


@dataclass(frozen=True)
class StorageConfig:
    endpoint: str
    bucket: str
    access_key_id: str
    secret_access_key: str


def get_storage_config() -> StorageConfig:
    settings = get_settings()
    return StorageConfig(
        endpoint=settings.storage_endpoint,
        bucket=settings.storage_bucket,
        access_key_id=settings.storage_access_key_id,
        secret_access_key=settings.storage_secret_access_key,
    )
