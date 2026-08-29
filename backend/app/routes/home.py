import json

from flask import Blueprint, jsonify, request, session
from mysql.connector import Error as MySQLError

from app.repositories import (
    RequestNotFoundError,
    RequestPermissionError,
    RequestRepository,
    SystemRepository,
)
from app.logging_config import log_handled_exception
from ._helpers import read_varchar_id

home = Blueprint("home", __name__, url_prefix="/home")
system_repository = SystemRepository()
request_repository = RequestRepository()


@home.get("")
def index():
    message = system_repository.get_welcome_message()
    return jsonify(message.to_dict())


@home.get("/health")
def health():
    status = system_repository.get_health()
    return jsonify(status.to_dict()), 200


@home.get("/get/request-details")
@home.get("/get/own-request-details")
def get_request_details():
    try:
        request_id = read_varchar_id(request, "request_id")
    except ValueError as exc:
        log_handled_exception("Request details validation failed", exc)
        return jsonify(success=False, error=str(exc)), 400

    try:
        details = request_repository.get_details(request_id)
    except RequestNotFoundError as exc:
        log_handled_exception("Request details not found", exc)
        return jsonify(success=False, error="request not found"), 404
    except MySQLError as exc:
        log_handled_exception("Request details database error", exc)
        return jsonify(success=False, error="database operation failed"), 500

    return jsonify(success=True, data=details), 200


@home.get("/get/own-request")
def get_own_request():
    try:
        request_id = read_varchar_id(request, "request_id")
    except ValueError as exc:
        log_handled_exception("Own request validation failed", exc)
        return jsonify(success=False, error=str(exc)), 400

    try:
        own_request = request_repository.get_own_request(request_id)
    except RequestNotFoundError as exc:
        log_handled_exception("Own request not found", exc)
        return jsonify(success=False, error="request not found"), 404
    except (MySQLError, json.JSONDecodeError) as exc:
        log_handled_exception("Own request database error", exc)
        return jsonify(success=False, error="database operation failed"), 500

    return jsonify(success=True, data=own_request), 200


@home.get("/get/request-status")
def get_request_status():
    user_id = str(
        session.get("user_id") or request.headers.get("X-User-ID", "")
    ).strip()
    if not user_id:
        return jsonify(success=False, error="X-User-ID header is required"), 400

    try:
        request_id = read_varchar_id(request, "request_id")
        status = request_repository.get_status(request_id, user_id)
    except ValueError as exc:
        log_handled_exception("Request status validation failed", exc)
        return jsonify(success=False, error=str(exc)), 400
    except RequestNotFoundError as exc:
        log_handled_exception("Request status not found", exc)
        return jsonify(success=False, error="request not found"), 404
    except RequestPermissionError as exc:
        log_handled_exception("Request status permission denied", exc)
        return jsonify(success=False, error="only the creator can view request status"), 403
    except MySQLError as exc:
        log_handled_exception("Request status database error", exc)
        return jsonify(success=False, error="database operation failed"), 500

    return jsonify(success=True, data=status), 200


@home.get("/get/current-stage")
def get_current_stage():
    user_id = str(
        session.get("user_id") or request.headers.get("X-User-ID", "")
    ).strip()
    if not user_id:
        return jsonify(success=False, error="authentication is required"), 401
    try:
        current_stage = request_repository.get_current_stage(user_id)
    except MySQLError as exc:
        log_handled_exception("Current stage database error", exc)
        return jsonify(success=False, error="database operation failed"), 500
    return jsonify(success=True, data=current_stage), 200
