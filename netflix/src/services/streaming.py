"""Video streaming service - handles CDN URL generation and adaptive bitrate."""

from datetime import datetime, timedelta, timezone

import boto3
from botocore.signers import CloudFrontSigner

from src.core.config import get_settings
from src.core.logging import get_logger

settings = get_settings()
logger = get_logger(__name__)

# Video quality profiles
QUALITY_PROFILES = {
    "240p": {"width": 426, "height": 240, "bitrate": "400k"},
    "480p": {"width": 854, "height": 480, "bitrate": "1000k"},
    "720p": {"width": 1280, "height": 720, "bitrate": "2500k"},
    "1080p": {"width": 1920, "height": 1080, "bitrate": "5000k"},
    "4k": {"width": 3840, "height": 2160, "bitrate": "15000k"},
}

# Subscription plan to max quality mapping
PLAN_MAX_QUALITY = {
    "basic": "480p",
    "standard": "1080p",
    "premium": "4k",
}


class StreamingService:
    """Handles video streaming URL generation and quality management."""

    def __init__(self) -> None:
        self.s3_client = boto3.client(
            "s3",
            aws_access_key_id=settings.aws_access_key_id,
            aws_secret_access_key=settings.aws_secret_access_key,
            region_name=settings.aws_region,
        )

    def get_available_qualities(self, subscription_plan: str) -> list[str]:
        """Get available quality options based on subscription plan."""
        max_quality = PLAN_MAX_QUALITY.get(subscription_plan, "480p")
        qualities = list(QUALITY_PROFILES.keys())
        max_index = qualities.index(max_quality)
        return qualities[: max_index + 1]

    def generate_presigned_url(self, video_key: str, expires_in: int = 3600) -> str:
        """Generate a pre-signed S3 URL for video streaming."""
        url = self.s3_client.generate_presigned_url(
            "get_object",
            Params={"Bucket": settings.s3_bucket_videos, "Key": video_key},
            ExpiresIn=expires_in,
        )
        logger.info("generated_presigned_url", video_key=video_key, expires_in=expires_in)
        return url

    def get_stream_manifest(self, content_id: str, subscription_plan: str) -> dict:
        """Generate an adaptive bitrate streaming manifest."""
        qualities = self.get_available_qualities(subscription_plan)

        streams = []
        for quality in qualities:
            profile = QUALITY_PROFILES[quality]
            video_key = f"content/{content_id}/{quality}/stream.m3u8"
            streams.append(
                {
                    "quality": quality,
                    "resolution": f"{profile['width']}x{profile['height']}",
                    "bitrate": profile["bitrate"],
                    "url": self.generate_presigned_url(video_key),
                }
            )

        return {
            "content_id": content_id,
            "streams": streams,
            "default_quality": qualities[-1],  # Highest available
        }
