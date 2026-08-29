from flask import Blueprint, jsonify, request, session
from mysql.connector import Error as MySQLError

from app.models import InvitationAcceptance
from app.repositories import (
    InvitationAlreadyProcessedError,
    InvitationNotFoundError,
    MeetupRepository,
    MeetupUnavailableError,
    ParticipantAccessDeniedError,
    ParticipantNotFoundError,
    UserRepository,
)
from app.logging_config import log_handled_exception
from ._helpers import read_varchar_id

meetup = Blueprint("meetup", __name__, url_prefix="/meetups")
meetup_api = Blueprint("meetup_api", __name__, url_prefix="/meetup")
user_repository = UserRepository()
meetup_repository = MeetupRepository()


@meetup.get("")
def list_meetups():
    """Return meetups. Connect this route to a meetup repository."""
    return jsonify(meetups=[]), 200


@meetup_api.get("/get/all-users-profiles")
def get_all_users_profiles():
    try:
        user_id = read_varchar_id(request, "id")
    except ValueError as exc:
        log_handled_exception("Shared profile validation failed", exc)
        return jsonify(success=False, error=str(exc)), 400

    try:
        profile = user_repository.get_shared_profile(user_id)
    except MySQLError as exc:
        log_handled_exception("Shared profile database error", exc)
        return jsonify(success=False, error="database operation failed"), 500

    if profile is None:
        return jsonify(success=False, error="user profile not found"), 404

    return jsonify(success=True, data=profile), 200


@meetup_api.get("/get/all-anonymous-profiles")
def get_all_anonymous_profiles():
    try:
        user_id = read_varchar_id(request, "id")
    except ValueError as exc:
        log_handled_exception("Anonymous profile validation failed", exc)
        return jsonify(success=False, error=str(exc)), 400

    try:
        profile = user_repository.get_anonymous_profile(user_id)
    except MySQLError as exc:
        log_handled_exception("Anonymous profile database error", exc)
        return jsonify(success=False, error="database operation failed"), 500

    if profile is None:
        return jsonify(success=False, error="user profile not found"), 404

    return jsonify(success=True, data=profile), 200


@meetup_api.post("/post/accept-invitation")
def accept_invitation():
    user_id = str(
        session.get("user_id") or request.headers.get("X-User-ID", "")
    ).strip()
    if not user_id:
        return jsonify(success=False, error="X-User-ID header is required"), 400

    try:
        acceptance = InvitationAcceptance.from_dict(request.get_json(silent=True))
        participant = meetup_repository.accept_invitation(user_id, acceptance)
    except ValueError as exc:
        log_handled_exception("Accept invitation validation failed", exc)
        return jsonify(success=False, error=str(exc)), 400
    except InvitationNotFoundError as exc:
        log_handled_exception("Invitation not found", exc)
        return jsonify(success=False, error=str(exc)), 404
    except InvitationAlreadyProcessedError as exc:
        log_handled_exception("Invitation already processed", exc)
        return jsonify(success=False, error="invitation already processed"), 409
    except MeetupUnavailableError as exc:
        log_handled_exception("Meetup unavailable for invitation", exc)
        return jsonify(success=False, error=str(exc)), 409
    except MySQLError as exc:
        log_handled_exception("Accept invitation database error", exc)
        return jsonify(success=False, error="database operation failed"), 500

    return jsonify(
        success=True,
        message="Invitation accepted successfully",
        data=participant.to_dict(),
    ), 200


@meetup_api.get("/get/participant-status")
def get_participant_status():
    user_id = str(
        session.get("user_id") or request.headers.get("X-User-ID", "")
    ).strip()
    if not user_id:
        return jsonify(success=False, error="X-User-ID header is required"), 400

    try:
        meetup_id = read_varchar_id(request, "meetup_id")
        status = meetup_repository.get_participant_status(meetup_id, user_id)
    except ValueError as exc:
        log_handled_exception("Participant status validation failed", exc)
        return jsonify(success=False, error=str(exc)), 400
    except InvitationNotFoundError as exc:
        log_handled_exception("Participant status meetup not found", exc)
        return jsonify(success=False, error="meetup not found"), 404
    except MySQLError as exc:
        log_handled_exception("Participant status database error", exc)
        return jsonify(success=False, error="database operation failed"), 500

    return jsonify(success=True, data=status), 200


@meetup_api.post("/post/reveal-profile")
def reveal_profile():
    user_id = str(
        session.get("user_id") or request.headers.get("X-User-ID", "")
    ).strip()
    if not user_id:
        return jsonify(success=False, error="X-User-ID header is required"), 400

    try:
        meetup_id = read_varchar_id(request, "meetup_id")
        revealed = meetup_repository.reveal_profile(meetup_id, user_id)
    except ValueError as exc:
        log_handled_exception("Reveal profile validation failed", exc)
        return jsonify(success=False, error=str(exc)), 400
    except ParticipantNotFoundError as exc:
        log_handled_exception("Reveal profile participant not found", exc)
        return jsonify(success=False, error="participant not found"), 404
    except ParticipantAccessDeniedError as exc:
        log_handled_exception("Reveal profile access denied", exc)
        return jsonify(success=False, error=str(exc)), 403
    except MySQLError as exc:
        log_handled_exception("Reveal profile database error", exc)
        return jsonify(success=False, error="database operation failed"), 500

    return jsonify(
        success=True,
        message="Profile reveal enabled",
        data=revealed,
    ), 200


@meetup_api.get("/get/all-participants")
def get_all_participants():
    user_id = str(
        session.get("user_id") or request.headers.get("X-User-ID", "")
    ).strip()
    if not user_id:
        return jsonify(success=False, error="X-User-ID header is required"), 400

    try:
        meetup_id = read_varchar_id(request, "meetup_id")
        participants = meetup_repository.get_all_participants(meetup_id, user_id)
    except ValueError as exc:
        log_handled_exception("Participant list validation failed", exc)
        return jsonify(success=False, error=str(exc)), 400
    except InvitationNotFoundError as exc:
        log_handled_exception("Participant list meetup not found", exc)
        return jsonify(success=False, error="meetup not found"), 404
    except ParticipantAccessDeniedError as exc:
        log_handled_exception("Participant list access denied", exc)
        return jsonify(success=False, error=str(exc)), 403
    except MySQLError as exc:
        log_handled_exception("Participant list database error", exc)
        return jsonify(success=False, error="database operation failed"), 500

    return jsonify(
        success=True,
        data={"meetup_id": meetup_id, "participants": participants},
    ), 200
