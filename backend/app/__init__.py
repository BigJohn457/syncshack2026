from flask import Flask

from .config import config_by_name


def create_app(config_name: str = "development") -> Flask:
    """Create and configure the Flask application."""
    app = Flask(__name__)
    app.config.from_object(config_by_name.get(config_name, config_by_name["development"]))

    from .routes import main

    app.register_blueprint(main)
    return app
