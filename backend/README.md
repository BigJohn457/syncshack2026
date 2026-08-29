# Flask Backend

## Setup

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## Run

```bash
flask --app run run --debug
```

The API is available at `http://127.0.0.1:5000`. Check server health at
`GET /health`.

## Test

```bash
pytest
```
