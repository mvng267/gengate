from pydantic import BaseModel


class RegisterRequest(BaseModel):
    email: str
    username: str | None = None


class RegisterResponse(BaseModel):
    id: str
    email: str
    username: str | None
    status: str
