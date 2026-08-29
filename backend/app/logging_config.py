import logging
from pathlib import Path

from flask import Flask, current_app, request
from werkzeug.exceptions import HTTPException


def configure_logging(app: Flask) -> None:
    """Write application exceptions to one size-limited log file."""
    log_path = Path(app.config["LOG_FILE"])
    log_path.parent.mkdir(parents=True, exist_ok=True)

    resolved_path = str(log_path.resolve())
    existing_handler = next(
        (
            handler
            for handler in app.logger.handlers
            if getattr(handler, "baseFilename", None) == resolved_path
        ),
        None,
    )
    if existing_handler is None:
        handler = logging.FileHandler(resolved_path, encoding="utf-8")
        handler.setLevel(logging.INFO)
        handler.setFormatter(
            logging.Formatter(
                "%(asctime)s | %(levelname)s | %(module)s | %(message)s"
            )
        )
        app.logger.addHandler(handler)

    app.logger.setLevel(logging.INFO)

    @app.errorhandler(Exception)
    def log_unhandled_exception(exc: Exception):
        if isinstance(exc, HTTPException):
            app.logger.warning(
                "HTTP exception: %s %s -> %s",
                request.method,
                request.full_path.rstrip("?"),
                exc,
                exc_info=(type(exc), exc, exc.__traceback__),
            )
            return exc

        app.logger.error(
            "Unhandled application exception",
            exc_info=(type(exc), exc, exc.__traceback__),
        )
        return {"success": False, "error": "internal server error"}, 500


def log_handled_exception(message: str, exc: Exception) -> None:
    """Record an exception that an API route converts into a safe response."""
    current_app.logger.warning(
        message,
        exc_info=(type(exc), exc, exc.__traceback__),
    )
