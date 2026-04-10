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
    def validate_username_length(cls, value: str | None) -> str | None:
        if value is None:
            return None
        if len(value) > 50:
            raise ValueError("username_too_long")
        return value


class RegisterResponse(BaseModel):
    id: str
    email: str
    username: str | None
    status: str
