from pydantic import BaseModel, field_validator


class RegisterRequest(BaseModel):
    email: str
    username: str | None = None

    @field_validator("email")
    @classmethod
    def normalize_email(cls, value: str) -> str:
        normalized = value.strip().lower()
        if normalized == "":
            raise ValueError("email_required")
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
