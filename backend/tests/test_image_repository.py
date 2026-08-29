from io import BytesIO

from flask import Flask
from PIL import Image
from werkzeug.datastructures import FileStorage

from app.repositories import ImageRepository


class FakeSpacesClient:
    def put_object(self, **kwargs):
        self.upload = kwargs


def png_bytes() -> bytes:
    stream = BytesIO()
    Image.new("RGB", (2, 2), "blue").save(stream, format="PNG")
    return stream.getvalue()


def test_image_repository_uploads_to_configured_spaces_folder(monkeypatch):
    app = Flask(__name__)
    app.config.update(
        SPACES_ACCESS_KEY_ID="test-key",
        SPACES_SECRET_ACCESS_KEY="test-secret",
        SPACES_REGION="syd1",
        SPACES_ENDPOINT_URL="https://syd1.digitaloceanspaces.com",
        SPACES_BUCKET="mg-kopi",
        SPACES_FOLDER="personal/hey",
        SPACES_PUBLIC_BASE_URL="https://mg-kopi.syd1.digitaloceanspaces.com",
        MAX_IMAGE_UPLOAD_BYTES=1024 * 1024,
    )
    client = FakeSpacesClient()
    monkeypatch.setattr("app.repositories.image_repository.boto3.client", lambda *a, **k: client)
    picture = FileStorage(stream=BytesIO(png_bytes()), filename="photo.png")

    with app.app_context():
        uploaded = ImageRepository().upload(picture)

    assert uploaded.key.startswith("personal/hey/")
    assert uploaded.key.endswith(".png")
    assert uploaded.url == (
        f"https://mg-kopi.syd1.digitaloceanspaces.com/{uploaded.key}"
    )
    assert client.upload["Bucket"] == "mg-kopi"
    assert client.upload["ContentType"] == "image/png"
    assert client.upload["ACL"] == "public-read"
