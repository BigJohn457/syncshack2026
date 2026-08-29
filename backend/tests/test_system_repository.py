from app.models import SystemMessage, SystemStatus
from app.repositories import SystemRepository


def test_get_welcome_message():
    repository = SystemRepository()

    assert repository.get_welcome_message() == SystemMessage(
        message="Flask server is running"
    )


def test_get_health():
    repository = SystemRepository()

    assert repository.get_health() == SystemStatus(status="ok")
