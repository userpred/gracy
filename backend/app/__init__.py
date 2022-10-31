from fastapi import FastAPI, Depends
from fastapi.responses import ORJSONResponse
from motor.motor_asyncio import AsyncIOMotorClient
from settings import Settings, __VERSION__
from app.depends.context import parse_request_body, setup_db_context
from app import middleware, error_handler
from controller.s3 import S3Controller
import model

# Router
from app.router import template
from app.router import v1_community, v1_activity, v1_leaderboard


def create_app(
    settings: Settings,
    mongo_client: AsyncIOMotorClient
) -> FastAPI:
    """Application Factory"""
    app = FastAPI(
        title=settings.app_name,
        description=settings.description,
        version=__VERSION__,
        terms_of_service=settings.term_of_service,
        contact={
            "name": settings.contact_name,
            "url": settings.contact_url,
            "email": settings.contact_email
        },
        docs_url=settings.docs_url,
        default_response_class=ORJSONResponse,
        dependencies=[
            Depends(parse_request_body),
            Depends(setup_db_context),
        ],
    )

    # Built-in init
    settings.init_app(app)
    middleware.init_middleware(app, settings)
    app.mongo_client = mongo_client
    app.mongo_db = mongo_client[settings.mongodb_db_name]

    @app.on_event("startup")
    async def startup():
        """run before the application starts"""
        await model.init_app(app, settings, mongo_client)
        error_handler.init_app(app)

    @app.on_event("shutdown")
    async def shutdown():
        """run when the application is shutting down"""
        ...

    # S3 Controller init
    app.s3 = S3Controller(
        aws_access_key_id=settings.s3_access_key_id,
        aws_secret_access_key=settings.s3_access_key_secret,
        bucket_name=settings.s3_bucket_name,
        bucket_domain=settings.s3_domain,
    )

    # Register Routers
    app.include_router(template)
    app.include_router(v1_community, prefix='/api/v1')
    app.include_router(v1_activity, prefix='/api/v1')
    app.include_router(v1_leaderboard, prefix='/api/v1')

    return app
