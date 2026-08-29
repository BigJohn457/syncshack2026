from flask import Blueprint, jsonify

from app.repositories import SystemRepository

home = Blueprint("home", __name__, url_prefix="/home")
system_repository = SystemRepository()


@home.get("")
def index():
    message = system_repository.get_welcome_message()
    return jsonify(message.to_dict())


@home.get("/health")
def health():
    status = system_repository.get_health()
    return jsonify(status.to_dict()), 200