from fastapi import APIRouter

from app.api.health import router as health_router
from app.modules.auth.router import router as auth_router
from app.modules.conversations.router import router as conversations_router
from app.modules.friendships.router import router as friendships_router
from app.modules.locations.router import router as locations_router
from app.modules.messages.router import router as messages_router
from app.modules.moments.router import router as moments_router
from app.modules.notifications.router import router as notifications_router
from app.modules.profiles.router import router as profiles_router

api_router = APIRouter()
api_router.include_router(health_router)
api_router.include_router(auth_router)
api_router.include_router(profiles_router)
api_router.include_router(friendships_router)
api_router.include_router(moments_router)
api_router.include_router(conversations_router)
api_router.include_router(messages_router)
api_router.include_router(locations_router)
api_router.include_router(notifications_router)
