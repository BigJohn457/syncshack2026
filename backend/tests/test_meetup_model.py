import pytest

from app.models import InvitationAcceptance


def test_invitation_acceptance_reads_meetup_id():
    acceptance = InvitationAcceptance.from_dict({"meetup_id": "meetup-001"})

    assert acceptance.meetup_id == "meetup-001"


def test_invitation_acceptance_requires_meetup_id():
    with pytest.raises(ValueError, match="meetup_id is required"):
        InvitationAcceptance.from_dict({})
