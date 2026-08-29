import json

from flask import Blueprint, jsonify, request
from mysql.connector import Error as MySQLError

from app.repositories import RequestNotFoundError, RequestRepository, SystemRepository
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
        return jsonify(success=False, error=str(exc)), 400

    try:
        details = request_repository.get_details(request_id)
    except RequestNotFoundError:
        return jsonify(success=False, error="request not found"), 404
    except MySQLError:
        return jsonify(success=False, error="database operation failed"), 500

    return jsonify(success=True, data=details), 200


@home.get("/get/own-request")
def get_own_request():
    try:
        request_id = read_varchar_id(request, "request_id")
    except ValueError as exc:
        return jsonify(success=False, error=str(exc)), 400

    try:
        own_request = request_repository.get_own_request(request_id)
    except RequestNotFoundError:
        return jsonify(success=False, error="request not found"), 404
    except (MySQLError, json.JSONDecodeError):
        return jsonify(success=False, error="database operation failed"), 500

    return jsonify(success=True, data=own_request), 200
