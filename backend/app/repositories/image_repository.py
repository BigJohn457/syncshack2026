from dataclasses import dataclass
from io import BytesIO
from uuid import uuid4

import boto3
from botocore.client import BaseClient
from flask import current_app
from PIL import Image, UnidentifiedImageError
from werkzeug.datastructures import FileStorage


class InvalidImageError(Exception):
    pass


class ImageTooLargeError(Exception):
    pass


class StorageConfigurationError(Exception):
    pass


@dataclass(frozen=True)
class UploadedImage:
    url: str
    key: str

    def to_dict(self) -> dict[str, str]:
        return {"url": self.url, "key": self.key}


class ImageRepository:
    ALLOWED_FORMATS = {
        "JPEG": ("jpg", "image/jpeg"),
        "PNG": ("png", "image/png"),
        "WEBP": ("webp", "image/webp"),
        "GIF": ("gif", "image/gif"),
    }

    def _client(self) -> BaseClient:
        access_key = current_app.config["SPACES_ACCESS_KEY_ID"]
        secret_key = current_app.config["SPACES_SECRET_ACCESS_KEY"]
        if not access_key or not secret_key:
            raise StorageConfigurationError("Spaces credentials are not configured")

        return boto3.client(
            "s3",
            region_name=current_app.config["SPACES_REGION"],
            endpoint_url=current_app.config["SPACES_ENDPOINT_URL"],
            aws_access_key_id=access_key,
            aws_secret_access_key=secret_key,
        )

    def upload(self, picture: FileStorage) -> UploadedImage:
        raw = picture.read(current_app.config["MAX_IMAGE_UPLOAD_BYTES"] + 1)
        if len(raw) > current_app.config["MAX_IMAGE_UPLOAD_BYTES"]:
            raise ImageTooLargeError("picture exceeds the maximum upload size")
        if not raw:
            raise InvalidImageError("picture cannot be empty")

        try:
            with Image.open(BytesIO(raw)) as image:
                image.verify()
                image_format = image.format
        except (UnidentifiedImageError, OSError, SyntaxError) as exc:
            raise InvalidImageError("file must be a valid image") from exc

        if image_format not in self.ALLOWED_FORMATS:
            raise InvalidImageError("supported image types are JPEG, PNG, WEBP, and GIF")

        extension, content_type = self.ALLOWED_FORMATS[image_format]
        key = f"{current_app.config['SPACES_FOLDER']}/{uuid4()}.{extension}"
        self._client().put_object(
            Bucket=current_app.config["SPACES_BUCKET"],
            Key=key,
            Body=raw,
            ContentType=content_type,
            ACL="public-read",
            CacheControl="public, max-age=31536000, immutable",
        )
        return UploadedImage(
            url=f"{current_app.config['SPACES_PUBLIC_BASE_URL']}/{key}",
            key=key,
        )
