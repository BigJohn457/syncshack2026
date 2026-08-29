import json

import requests


class MatchmakingServiceError(Exception):
    pass


class MatchmakingService:
    def __init__(self, api_key: str, model: str):
        self.api_key = api_key
        self.model = model

    def best_match(self, person_to_match: dict, possible_matches: list[dict]) -> dict:
        if not self.api_key:
            raise MatchmakingServiceError("matchmaking service is not configured")
        prompt = {
            "instruction": (
                "Score each possible match from 0 to 100 for friendship and meetup "
                "compatibility. Use interests, personality, preferred meetup, conversation "
                "topics and reliability. For every candidate, include exactly three short, "
                "specific reasons explaining the strongest compatibility signals. Return "
                "JSON only in this shape: {\"scores\": [{\"user_id\": \"...\", "
                "\"score\": 0, \"reasons\": [\"...\", \"...\", \"...\"]}]}. "
                "Never invent user IDs or profile facts."
            ),
            "person_to_match": person_to_match,
            "possible_matches": possible_matches,
        }
        url = (
            "https://api.deepseek.com/chat/completions"
        )
        try:
            response = requests.post(
                url,
                headers={
                    "Authorization": f"Bearer {self.api_key}",
                    "Content-Type": "application/json",
                },
                json={
                    "model": self.model,
                    "messages": [
                        {
                            "role": "user",
                            "content": json.dumps(prompt),
                        }
                    ],
                    "response_format": {"type": "json_object"},
                    "thinking": {"type": "disabled"},
                },
                timeout=20,
            )
            response.raise_for_status()
            text = response.json()["choices"][0]["message"]["content"]
            payload = json.loads(text)
        except (requests.RequestException, KeyError, IndexError, json.JSONDecodeError) as exc:
            raise MatchmakingServiceError("matchmaking service is unavailable") from exc
        allowed = {item["user_id"] for item in possible_matches}
        scores = []
        for item in payload.get("scores", []):
            user_id = str(item.get("user_id", ""))
            if user_id not in allowed:
                continue
            try:
                score = max(0, min(100, int(item["score"])))
            except (KeyError, TypeError, ValueError):
                continue
            raw_reasons = item.get("reasons")
            reasons = []
            if isinstance(raw_reasons, list):
                for reason in raw_reasons:
                    text = str(reason).strip()
                    if text and text not in reasons:
                        reasons.append(text[:160])
                    if len(reasons) == 3:
                        break
            scores.append({"user_id": user_id, "score": score, "reasons": reasons})
        if not scores:
            raise MatchmakingServiceError("matchmaking returned no valid scores")
        return max(scores, key=lambda item: item["score"])
