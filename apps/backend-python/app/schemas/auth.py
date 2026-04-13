import uuid
from datetime import datetime

from pydantic import BaseModel, field_validator


EMAIL_INTERNAL_WHITESPACE_CHARS = (" ", "\t", "\n", "\r", "\v", "\f")


class RegisterRequest(BaseModel):
    email: str
    username: str | None = None

    @field_validator("email")
    @classmethod
    def normalize_email(cls, value: str) -> str:
        normalized = value.strip().lower()
        if normalized == "":
            raise ValueError("email_required")
        if any(char in normalized for char in EMAIL_INTERNAL_WHITESPACE_CHARS):
            raise ValueError("email_invalid_format")
        if len(normalized) > 320:
            raise ValueError("email_too_long")
        return normalized

    @field_validator("username")
    @classmethod
    def normalize_and_validate_username(cls, value: str | None) -> str | None:
        if value is None:
            return None

        normalized = value.strip()
        if normalized == "":
            return None
        if len(normalized) > 50:
            raise ValueError("username_too_long")
        return normalized


class RegisterResponse(BaseModel):
    id: str
    email: str
    username: str | None
    status: str


class LoginRequest(BaseModel):
    email: str
    platform: str
    device_name: str

    @field_validator("email")
    @classmethod
    def normalize_login_email(cls, value: str) -> str:
        return RegisterRequest.normalize_email(value)

    @field_validator("platform")
    @classmethod
    def validate_platform(cls, value: str) -> str:
        normalized = value.strip().lower()
        if normalized == "":
            raise ValueError("platform_required")
        if len(normalized) > 32:
            raise ValueError("platform_too_long")
        return normalized

    @field_validator("device_name")
    @classmethod
    def validate_device_name(cls, value: str) -> str:
        normalized = value.strip()
        if normalized == "":
            raise ValueError("device_name_required")
        if len(normalized) > 128:
            raise ValueError("device_name_too_long")
        return normalized


class LoginResponse(BaseModel):
    user_id: uuid.UUID
    email: str
    device_id: uuid.UUID
    session_id: uuid.UUID
    refresh_token: str
    expires_at: datetime
    expires_in_seconds: int
    token_type: str
    bootstrap_mode: str
    session_status: str


class RefreshSessionRequest(BaseModel):
    refresh_token: str

    @field_validator("refresh_token")
    @classmethod
    def validate_refresh_token(cls, value: str) -> str:
        normalized = value.strip()
        if normalized == "":
            raise ValueError("refresh_token_required")
        if len(normalized) > 255:
            raise ValueError("refresh_token_too_long")
        return normalized


class SessionSnapshotResponse(BaseModel):
    user_id: uuid.UUID
    email: str
    device_id: uuid.UUID
    session_id: uuid.UUID
    expires_at: datetime
    expires_in_seconds: int
    token_type: str
    session_status: str
    local_clear_recommended: bool = False
    backend_detail: str | None = None
