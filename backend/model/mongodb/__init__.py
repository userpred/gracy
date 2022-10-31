from bson import ObjectId
from motor.motor_asyncio import AsyncIOMotorClient
from settings import settings


def get_client(
        uri: str = settings.mongodb_uri
) -> AsyncIOMotorClient:
    return AsyncIOMotorClient(
        uri,
        connect=False,
        minPoolSize=1,
        maxPoolSize=100,
    )
