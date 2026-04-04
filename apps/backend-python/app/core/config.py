from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "GenGate Backend"
    app_version: str = "0.1.0"
    environment: str = "development"
    api_v1_prefix: str = "/v1"
    database_url: str = "postgresql+psycopg://gengate:gengate@localhost:5432/gengate"
    redis_url: str = "redis://localhost:6379/0"
    storage_endpoint: str = "https://example.r2.cloudflarestorage.com"
    storage_bucket: str = "gengate"
    storage_access_key_id: str = "replace-me"
    storage_secret_access_key: str = "replace-me"

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )


@lru_cache
def get_settings() -> Settings:
    return Settings()
