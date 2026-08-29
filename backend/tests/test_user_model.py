import pytest

from app.models import UserProfileUpdate


def test_profile_update_validates_and_normalizes_values():
    update = UserProfileUpdate.from_dict(
        {
            "first_name": " Blue ",
            "last_name": " Panda ",
            "email": "blue@example.com",
            "phone": "0400000000",
            "radius": "5.5",
            "profile_image_url": "",
        }
    )

    assert update.first_name == "Blue"
    assert update.radius == 5.5
    assert update.profile_image_url is None


def test_profile_update_rejects_negative_radius():
    with pytest.raises(ValueError, match="radius cannot be negative"):
        UserProfileUpdate.from_dict(
            {
                "first_name": "Blue",
                "last_name": "Panda",
                "email": "blue@example.com",
                "phone": "0400000000",
                "radius": -1,
            }
        )
