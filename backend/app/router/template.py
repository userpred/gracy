from fastapi import APIRouter, Request
from fastapi.templating import Jinja2Templates
from settings import settings, BASE_DIR


api = APIRouter()
template_engine = Jinja2Templates(
    directory=f"{BASE_DIR}/app/asset"
)
templating = template_engine.TemplateResponse


@api.get(
    '/',
    summary="Welcome to Gracy Staking API",
    tags=['template'],
)
async def index(request: Request):
    """
    Welcome to Gracy Staking API
    """
    return templating(
        'index.html',
        context={
            'request': request,
            'description': settings.description
        }
    )
