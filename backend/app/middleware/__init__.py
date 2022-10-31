import time
from typing import Callable
from loguru import logger
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from starlette_context.middleware import RawContextMiddleware
from starlette_context import context
from settings import Settings
from model.mongodb.collection import Log


def init_middleware(
    app: FastAPI,
    app_settings: Settings
) -> None:
    @app.middleware("http")
    async def slow_api_tracker(
        request: Request,
        call_next: Callable
    ):

        # slow router tracker middleware
        process_time = time.time()
        response = await call_next(request)
        process_time = time.time() - process_time
        response.headers["X-Process-Time"] = str(process_time)
        if process_time >= app_settings.slow_api_time:
            # Get body in the ContextMiddleware
            request_body = context.get('body')
            log_str: str = (
                f"\n!!! SLOW API DETECTED !!!\n"
                f"time: {process_time}\n"
                f"url: {request.url.path}\n"
                f"ip: {request.client.host}\n"
                f"body: {str(request_body)}\n"
            )
            logger.error(log_str)
        return response

    if app_settings.mongodb_api_log:
        @app.middleware('http')
        async def mongodb_api_logger(
            request: Request,
            call_next: Callable
        ):
            """
            Mongodb API Logger Middleware
            """
            response = await call_next(request)
            db = request.app.mongo_db
            await Log(db).insert_one_raw_dict({
                "ipv4": request.client.host,
                "url": request.url.path,
                'method': request.method,
                'body': (context.get('body') or b'').decode(),
                'status_code': response.status_code,
            })
            return response

    # Extension/Middleware init
    app.add_middleware(
        CORSMiddleware,
        allow_credentials=True,
        allow_origins=["*"],
        allow_methods=["*"],
        allow_headers=["*"])
    app.add_middleware(
        TrustedHostMiddleware,
        allowed_hosts=["*"])
    app.add_middleware(
        GZipMiddleware,
        minimum_size=1024)
    app.add_middleware(RawContextMiddleware)
