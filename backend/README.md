# Flask Backend

## Setup

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

Copy `.env.example` to `.env`, enter the database credentials, and set
`DB_SSL_CA` to the path of the DigitalOcean CA certificate. Database code can
then call `get_db_connection()` from `app.database`; callers are responsible
for closing the returned connection.

## Run

```bash
flask --app run run --debug
```

The API is available at `http://127.0.0.1:5000`. Check server health at
`GET /api/home/health`.

## Architecture

The application uses a lightweight MVC-style structure:

```text
app/
├── models/          # Domain objects and data shapes
├── repositories/    # Business and data-access logic
└── routes/          # HTTP controllers, split by feature
```

Keep route handlers thin. A route should read the request, call a repository,
and format the HTTP response. Put database queries and reusable application
logic in `app/repositories`, and define the returned domain objects in
`app/models`.

The route modules and their base endpoints are:

| Module | Endpoint |
| --- | --- |
| `home.py` | `/api/home` and `/api/home/health` |
| `request.py` | `/api/request` |
| `meetup_chat.py` | `/api/meetup-chat` |
| `meetup.py` | `/api/meetups` |
| `rating.py` | `/api/rating` |
| `users.py` | `/api/users` |
| `auth.py` | `/api/auth` |

Authentication uses an HTTP-only signed session cookie. Frontend requests must
include credentials so the browser stores and sends the cookie. Passwords are
stored as salted one-way hashes, never as plaintext.

## Test

```bash
pytest
```
