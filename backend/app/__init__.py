from flask import Flask

from .config import config_by_name
from .logging_config import configure_logging


def create_app(config_name: str = "development") -> Flask:
    """Create and configure the Flask application."""
    app = Flask(__name__)
    app.config.from_object(config_by_name.get(config_name, config_by_name["development"]))
    configure_logging(app)

    from .routes import blueprints

    for blueprint in blueprints:
        app.register_blueprint(blueprint, url_prefix=f"/api{blueprint.url_prefix or ''}")
    return app
