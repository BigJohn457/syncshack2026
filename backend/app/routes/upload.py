from flask import Blueprint, jsonify, request
from botocore.exceptions import BotoCoreError, ClientError

from app.logging_config import log_handled_exception
from app.repositories import (
    ImageRepository,
    ImageTooLargeError,
    InvalidImageError,
    StorageConfigurationError,
)

upload = Blueprint("upload", __name__, url_prefix="/upload")
image_repository = ImageRepository()


@upload.post("/post/picture")
def upload_picture():
    picture = request.files.get("picture")
    if picture is None:
        return jsonify(success=False, error="picture file is required"), 400

    try:
        uploaded = image_repository.upload(picture)
    except (InvalidImageError, ImageTooLargeError) as exc:
        log_handled_exception("Image upload validation failed", exc)
        return jsonify(success=False, error=str(exc)), 400
    except StorageConfigurationError as exc:
        log_handled_exception("Image storage is not configured", exc)
        return jsonify(success=False, error="image storage is not configured"), 503
    except (BotoCoreError, ClientError) as exc:
        log_handled_exception("DigitalOcean Spaces upload failed", exc)
        return jsonify(success=False, error="image upload failed"), 502

    return jsonify(success=True, data=uploaded.to_dict()), 201
