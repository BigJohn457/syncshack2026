import os
from datetime import timedelta
from pathlib import Path

from dotenv import load_dotenv


BASE_DIR = Path(__file__).resolve().parent.parent
load_dotenv(BASE_DIR / ".env")


def _resolve_path(value: str) -> str:
    path = Path(value)
    return str(path if path.is_absolute() else BASE_DIR / path)


class Config:
    SECRET_KEY = os.getenv("SECRET_KEY", "dev-only-change-me")
    JSON_SORT_KEYS = False
    DB_HOST = os.getenv("DB_HOST")
    DB_PORT = int(os.getenv("DB_PORT", "3306"))
    DB_USER = os.getenv("DB_USER")
    DB_PASSWORD = os.getenv("DB_PASSWORD", "")
    DB_NAME = os.getenv("DB_NAME")
    DB_SSL_CA = _resolve_path(
        os.getenv("DB_SSL_CA", "ca-certificate (10).crt")
    )
    API_TIMEZONE = os.getenv("API_TIMEZONE", "Australia/Sydney")
    SESSION_COOKIE_HTTPONLY = True
    SESSION_COOKIE_SAMESITE = "Lax"
    PERMANENT_SESSION_LIFETIME = timedelta(days=7)
    LOG_FILE = _resolve_path(os.getenv("LOG_FILE", "app.log"))
    SPACES_ACCESS_KEY_ID = os.getenv("SPACES_ACCESS_KEY_ID")
    SPACES_SECRET_ACCESS_KEY = os.getenv("SPACES_SECRET_ACCESS_KEY")
    SPACES_REGION = os.getenv("SPACES_REGION", "syd1")
    SPACES_BUCKET = os.getenv("SPACES_BUCKET", "mg-kopi")
    SPACES_FOLDER = os.getenv("SPACES_FOLDER", "personal/hey").strip("/")
    SPACES_ENDPOINT_URL = os.getenv(
        "SPACES_ENDPOINT_URL", "https://syd1.digitaloceanspaces.com"
    )
    SPACES_PUBLIC_BASE_URL = os.getenv(
        "SPACES_PUBLIC_BASE_URL", "https://mg-kopi.syd1.digitaloceanspaces.com"
    ).rstrip("/")
    MAX_IMAGE_UPLOAD_BYTES = int(
        os.getenv("MAX_IMAGE_UPLOAD_BYTES", str(10 * 1024 * 1024))
    )
    DEEPSEEK_API_KEY = os.getenv("DEEPSEEK_API_KEY", "")
    DEEPSEEK_MODEL = os.getenv("DEEPSEEK_MODEL", "deepseek-v4-flash")


class DevelopmentConfig(Config):
    DEBUG = True


class TestingConfig(Config):
    TESTING = True


class ProductionConfig(Config):
    DEBUG = False
    SESSION_COOKIE_SECURE = True


config_by_name = {
    "development": DevelopmentConfig,
    "testing": TestingConfig,
    "production": ProductionConfig,
}
