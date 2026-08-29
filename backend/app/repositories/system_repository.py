from app.models import SystemMessage, SystemStatus


class SystemRepository:
    """Provides the data used by the API system endpoints.

    Database queries and other persistence logic should live in repository
    classes like this one, keeping route handlers focused on HTTP concerns.
    """

    def get_welcome_message(self) -> SystemMessage:
        return SystemMessage(message="Flask server is running")

    def get_health(self) -> SystemStatus:
        return SystemStatus(status="ok")
