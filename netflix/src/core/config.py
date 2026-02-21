"""Application configuration using Pydantic Settings."""

from functools import lru_cache

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    # Application
    app_name: str = "Netflix Streaming Platform"
    app_env: str = "development"
    app_debug: bool = False
    app_host: str = "0.0.0.0"
    app_port: int = 8000
    app_secret_key: str = "change-me-in-production"
    app_allowed_origins: str = "http://localhost:3000,http://localhost:8000"

    # Database
    database_url: str = "postgresql+asyncpg://netflix_user:password@localhost:5432/netflix_db"

    # Redis
    redis_url: str = "redis://localhost:6379/0"

    # JWT
    jwt_secret_key: str = "change-me-in-production"
    jwt_algorithm: str = "HS256"
    jwt_access_token_expire_minutes: int = 30
    jwt_refresh_token_expire_days: int = 7

    # AWS S3
    aws_access_key_id: str = ""
    aws_secret_access_key: str = ""
    aws_region: str = "us-east-1"
    s3_bucket_videos: str = "netflix-videos"
    s3_bucket_thumbnails: str = "netflix-thumbnails"

    # CloudFront CDN
    cloudfront_domain: str = ""

    # Elasticsearch
    elasticsearch_host: str = "localhost"
    elasticsearch_port: int = 9200

    # Stripe
    stripe_secret_key: str = ""
    stripe_webhook_secret: str = ""

    # Logging
    log_level: str = "INFO"
    log_format: str = "json"

    @property
    def allowed_origins_list(self) -> list[str]:
        return [origin.strip() for origin in self.app_allowed_origins.split(",")]

    model_config = {"env_file": ".env", "env_file_encoding": "utf-8"}


@lru_cache
def get_settings() -> Settings:
    """Return cached application settings."""
    return Settings()
