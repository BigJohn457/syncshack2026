import json

from app.services.matchmaking import MatchmakingService


class FakeResponse:
    def raise_for_status(self):
        pass

    def json(self):
        return {
            "choices": [
                {
                    "message": {
                        "content": json.dumps(
                            {
                                "scores": [
                                    {
                                        "user_id": "user-2",
                                        "score": 74,
                                        "reasons": ["Both enjoy coffee meetups"],
                                    },
                                    {
                                        "user_id": "user-3",
                                        "score": 91,
                                        "reasons": [
                                            "Shared interest in hiking",
                                            "Similar social energy",
                                            "Both prefer weekend meetups",
                                        ],
                                    },
                                ]
                            }
                        )
                    }
                }
            ]
        }


def test_returns_only_highest_valid_deepseek_score(monkeypatch):
    monkeypatch.setattr(
        "app.services.matchmaking.requests.post", lambda *args, **kwargs: FakeResponse()
    )
    service = MatchmakingService("test-key", "deepseek-v4-flash")

    result = service.best_match(
        {"user_id": "user-1"},
        [{"user_id": "user-2"}, {"user_id": "user-3"}],
    )

    assert result == {
        "user_id": "user-3",
        "score": 91,
        "reasons": [
            "Shared interest in hiking",
            "Similar social energy",
            "Both prefer weekend meetups",
        ],
    }
