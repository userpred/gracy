import os
from pydantic import BaseSettings, Field
from fastapi import FastAPI
from dotenv import load_dotenv


__AUTHOR__ = "Gracy"
__VERSION__ = "0.0.1"

APP_NAME = "gracy-Staking-API"
BASE_DIR = os.path.abspath(os.path.dirname(__file__))
load_dotenv(os.path.join(BASE_DIR, "dev.env"))


class Settings(BaseSettings):
    # Description settings
    app_name: str = Field(APP_NAME, env='APP_NAME')
    description: str = "gracy Statking API"
    term_of_service: str = ""
    contact_name: str = __AUTHOR__
    contact_url: str = ""
    contact_email: str = ""

    # Documentation url
    docs_url: str = "/docs"

    # JWT settings
    secret_key: str = os.environ['GRACY_STAKING_SECRET_KEY']
    jwt_algorithm: str = "HS256"
    jwt_access_expires: int = 3600 * 24 * 7
    jwt_refresh_expires: int = 3600 * 24 * 30

    # Slow API settings
    slow_api_time: float = 0.5

    # Mongodb settings
    mongodb_uri: str = os.environ['GRACY_STAKING_MONGODB_URI']
    mongodb_db_name: str = os.environ['GRACY_STAKING_MONGODB_NAME']
    mongodb_api_log: bool = True

    # S3 settings
    s3_access_key_id: str = os.environ['GRACY_STAKING_S3_ACCESS_KEY_ID']
    s3_access_key_secret: str = os.environ['GRACY_STAKING_S3_ACCESS_KEY_SECRET']
    s3_bucket_name: str = os.environ['GRACY_STAKING_S3_BUCKET_NAME']
    s3_domain: str = os.environ['GRACY_STAKING_S3_DOMAIN']

    # Chain settings
    staking_domain: str = os.environ['GRACY_STAKING_DOMAIN']
    staking_contract: str = os.environ['GRACY_STAKING_CONTRACT']
    etherscan_domain: str = os.environ['GRACY_STAKING_ETHER_SCAN_DOMAIN']
    etherscan_api_key: str = os.environ['GRACY_STAKING_ETHER_SCAN_API_KEY']

    class Config:
        env_prefix = f"{APP_NAME.upper()}_"
        # default: development env
        env_file = BASE_DIR + '/dev.env'
        env_file_encoding = 'utf-8'

    def init_app(self, app: FastAPI):
        ...


class TestSettings(Settings):
    """Test settings"""
    slow_api_time: float = 1.0


settings = Settings()
