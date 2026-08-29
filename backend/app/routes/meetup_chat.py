from flask import Blueprint, current_app, jsonify, request, session
from mysql.connector import Error as MySQLError

from app.models import MessageSubmission
from app.logging_config import log_handled_exception
from app.repositories import (
    ChatAccessDeniedError,
    MeetupChatRepository,
    MeetupNotFoundError,
)

meetup_chat = Blueprint("meetup_chat", __name__, url_prefix="/meetup-chat")
meetup_chat_repository = MeetupChatRepository()


@meetup_chat.get("")
def list_meetup_chats():
    """Return meetup chats. Connect this route to a chat repository."""
    return jsonify(meetup_chats=[]), 200


@meetup_chat.get("/get/all-messages")
def get_all_messages():
    body = request.get_json(silent=True) or {}
    meetup_id = request.args.get("meetup_id") or body.get("meetup_id")
    if not isinstance(meetup_id, str) or not meetup_id.strip():
        return jsonify(success=False, error="meetup_id is required"), 400

    meetup_id = meetup_id.strip()
    try:
        messages = meetup_chat_repository.get_all_messages(meetup_id)
    except MeetupNotFoundError as exc:
        log_handled_exception("Meetup chat not found", exc)
        return jsonify(success=False, error="meetup not found"), 404
    except MySQLError as exc:
        log_handled_exception("Meetup chat database error", exc)
        return jsonify(success=False, error="database operation failed"), 500

    timezone_name = current_app.config["API_TIMEZONE"]
    return jsonify(
        success=True,
        data={
            "meetup_id": meetup_id,
            "messages": [message.to_dict(timezone_name) for message in messages],
        },
    ), 200


@meetup_chat.post("/post/send-message")
def send_message():
    sender_id = str(
        session.get("user_id") or request.headers.get("X-User-ID", "")
    ).strip()
    if not sender_id:
        return jsonify(success=False, error="X-User-ID header is required"), 400

    try:
        submission = MessageSubmission.from_dict(request.get_json(silent=True))
        message = meetup_chat_repository.create_message(sender_id, submission)
    except ValueError as exc:
        log_handled_exception("Send message validation failed", exc)
        return jsonify(success=False, error=str(exc)), 400
    except MeetupNotFoundError as exc:
        log_handled_exception("Send message meetup not found", exc)
        return jsonify(success=False, error="meetup not found"), 404
    except ChatAccessDeniedError as exc:
        log_handled_exception("Send message access denied", exc)
        return jsonify(success=False, error=str(exc)), 403
    except MySQLError as exc:
        log_handled_exception("Send message database error", exc)
        return jsonify(success=False, error="database operation failed"), 500

    timezone_name = current_app.config["API_TIMEZONE"]
    return jsonify(
        success=True,
        message="Message sent successfully",
        data={
            "meetup_id": submission.meetup_id,
            "message": message.to_dict(timezone_name),
        },
    ), 201
