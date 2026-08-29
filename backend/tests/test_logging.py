from flask import Flask

from app.logging_config import configure_logging, log_handled_exception


def make_logging_app(log_path):
    app = Flask(__name__)
    app.config.update(
        LOG_FILE=str(log_path),
    )
    configure_logging(app)
    return app


def test_handled_exception_is_written_to_log(tmp_path):
    log_path = tmp_path / "app.log"
    app = make_logging_app(log_path)

    with app.app_context():
        try:
            raise ValueError("test validation error")
        except ValueError as exc:
            log_handled_exception("Validation failed", exc)

    contents = log_path.read_text()
    assert "Validation failed" in contents
    assert "ValueError: test validation error" in contents


def test_unhandled_exception_returns_safe_response_and_logs_traceback(tmp_path):
    log_path = tmp_path / "app.log"
    app = make_logging_app(log_path)

    @app.get("/crash")
    def crash():
        raise RuntimeError("unexpected test crash")

    response = app.test_client().get("/crash")

    assert response.status_code == 500
    assert response.get_json() == {
        "success": False,
        "error": "internal server error",
    }
    assert "RuntimeError: unexpected test crash" in log_path.read_text()
