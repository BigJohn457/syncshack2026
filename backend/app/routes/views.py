from flask import jsonify

from . import main


@main.get("/")
def index():
    return jsonify(message="Flask server is running")


@main.get("/health")
def health():
    return jsonify(status="ok"), 200
