from typing import Any

from fastapi import FastAPI, HTTPException, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse

from app.api.router import api_router
from app.core.config import get_settings

settings = get_settings()
app = FastAPI(title=settings.app_name, version=settings.app_version)
app.include_router(api_router)


def to_error_payload(code: str, message: str, **extra: Any) -> dict[str, dict[str, Any]]:
    payload: dict[str, Any] = {"code": code, "message": message}
    payload.update(extra)
    return {"error": payload}


@app.exception_handler(HTTPException)
async def http_exception_handler(_: Request, exc: HTTPException) -> JSONResponse:
    extra: dict[str, Any] = {}
    if isinstance(exc.detail, dict):
        code = str(exc.detail.get("code", "http_error"))
        message = str(exc.detail.get("message", code))
        extra = {
            key: value
            for key, value in exc.detail.items()
            if key not in {"code", "message"}
        }
    elif isinstance(exc.detail, str):
        code = exc.detail
        message = exc.detail
    else:
        code = "http_error"
        message = "http_error"
    return JSONResponse(status_code=exc.status_code, content=to_error_payload(code, message, **extra))


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(_: Request, exc: RequestValidationError) -> JSONResponse:
    return JSONResponse(
        status_code=422,
        content=to_error_payload("validation_error", str(exc.errors())),
    )
