from uuid import uuid4

from flask import Blueprint, jsonify, request as flask_request, session
from mysql.connector import Error as MySQLError

from app.models import MeetupRequest
from app.logging_config import log_handled_exception
from app.repositories import (
    RequestCancellationError,
    RequestNotFoundError,
    RequestPermissionError,
    RequestRepository,
    UserNotFoundError,
)
from ._helpers import read_varchar_id

request = Blueprint("request", __name__, url_prefix="/request")
request_repository = RequestRepository()


def _read_float(name: str, body: dict):
    value = flask_request.args.get(name)
    if value is None:
        value = body.get(name)
    if value is None or value == "":
        return None
    try:
        return float(value)
    except (TypeError, ValueError):
        raise ValueError(f"{name} must be a number") from None


@request.get("")
def list_requests():
    """Return requests. Connect this route to a request repository."""
    return jsonify(requests=[]), 200


@request.get("/get/all-request")
def get_all_nearby_requests():
    body = flask_request.get_json(silent=True) or {}
    try:
        longitude = _read_float("longitude", body)
        latitude = _read_float("latitude", body)
        radius = _read_float("radius", body)
    except ValueError as exc:
        log_handled_exception("Nearby request validation failed", exc)
        return jsonify(success=False, error=str(exc)), 400

    if longitude is None or latitude is None or radius is None:
        return jsonify(
            success=False, error="longitude, latitude, and radius are required"
        ), 400
    if not -90 <= latitude <= 90:
        return jsonify(success=False, error="latitude must be between -90 and 90"), 400
    if not -180 <= longitude <= 180:
        return jsonify(
            success=False, error="longitude must be between -180 and 180"
        ), 400
    if radius < 0:
        return jsonify(success=False, error="radius must be greater than or equal to 0"), 400

    try:
        nearby_requests = request_repository.find_nearby(latitude, longitude, radius)
    except MySQLError as exc:
        log_handled_exception("Nearby request database error", exc)
        return jsonify(success=False, error="database operation failed"), 500

    return jsonify(
        success=True,
        data=[meetup_request.to_dict() for meetup_request in nearby_requests],
    ), 200


@request.post("/post/submit-request")
def submit_request():
    creator_id = str(
        session.get("user_id") or flask_request.headers.get("X-User-ID", "")
    ).strip()
    if not creator_id:
        return jsonify(success=False, error="X-User-ID header is required"), 400

    try:
        meetup_request = MeetupRequest.from_submission(
            flask_request.get_json(silent=True), creator_id, str(uuid4())
        )
        created_request = request_repository.create(meetup_request)
    except ValueError as exc:
        log_handled_exception("Submit request validation failed", exc)
        return jsonify(success=False, error=str(exc)), 400
    except UserNotFoundError as exc:
        log_handled_exception("Submit request user not found", exc)
        return jsonify(success=False, error="user not found"), 404
    except MySQLError as exc:
        log_handled_exception("Submit request database error", exc)
        return jsonify(success=False, error="database operation failed"), 500

    return jsonify(success=True, data=created_request.to_dict()), 201


@request.post("/post/cancel-request")
def cancel_request():
    user_id = str(
        session.get("user_id") or flask_request.headers.get("X-User-ID", "")
    ).strip()
    if not user_id:
        return jsonify(success=False, error="X-User-ID header is required"), 400

    try:
        request_id = read_varchar_id(flask_request, "request_id")
        cancelled = request_repository.cancel(request_id, user_id)
    except ValueError as exc:
        log_handled_exception("Cancel request validation failed", exc)
        return jsonify(success=False, error=str(exc)), 400
    except RequestNotFoundError as exc:
        log_handled_exception("Cancel request not found", exc)
        return jsonify(success=False, error="request not found"), 404
    except RequestPermissionError as exc:
        log_handled_exception("Cancel request permission denied", exc)
        return jsonify(success=False, error="only the creator can cancel this request"), 403
    except RequestCancellationError as exc:
        log_handled_exception("Request cannot be cancelled", exc)
        return jsonify(success=False, error=str(exc)), 409
    except MySQLError as exc:
        log_handled_exception("Cancel request database error", exc)
        return jsonify(success=False, error="database operation failed"), 500

    return jsonify(
        success=True,
        message="Request cancelled successfully",
        data=cancelled,
    ), 200
