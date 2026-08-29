# Hey API — Frontend Integration Guide

This document describes every HTTP endpoint currently registered by the backend.

## Base URL

Local development:

```text
http://127.0.0.1:5000
```

All application endpoints begin with `/api` and use JSON unless otherwise stated.

```http
Content-Type: application/json
```

## Authentication and sessions

Login uses a signed Flask session stored in an HTTP-only cookie. The frontend
cannot and should not read this cookie directly. The browser must be allowed to
store it and send it on subsequent requests.

Use `credentials: "include"` for login and all authenticated requests:

```js
const response = await fetch(`${API_BASE_URL}/api/auth/post/login`, {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  credentials: "include",
  body: JSON.stringify({
    email: "blue@example.com",
    password: "strong-password"
  })
});

const body = await response.json();
if (!response.ok) throw new Error(body.error ?? "Request failed");
```

The session lasts seven days. Its cookie is HTTP-only and `SameSite=Lax`; it is
also `Secure` in production.

The following endpoints use the logged-in user's session:

- `POST /api/request/post/submit-request`
- `POST /api/users/post/edit-profile`
- `POST /api/rating/post/submit-rating`

During migration, these endpoints also accept `X-User-ID` when no session is
present. The frontend should use the session cookie, not this fallback header.

## Common response and error handling

Most completed endpoints return one of these shapes:

```json
{ "success": true, "data": {} }
```

```json
{ "success": false, "error": "Human-readable error" }
```

Relevant status codes:

| Status | Meaning |
| --- | --- |
| `200` | Request succeeded |
| `201` | Resource created |
| `400` | Missing or invalid input |
| `401` | Invalid login credentials |
| `403` | User is not eligible to perform the action |
| `404` | Requested database record was not found |
| `409` | Duplicate email or duplicate rating |
| `500` | Database operation failed |

Always check `response.ok` or the HTTP status before using `data`.

## ID format

The database and authentication APIs create UUID-style string IDs, for example:

```text
e8d66ac8-494f-4208-a96f-c75654504847
```

All primary and foreign IDs are strings backed by `VARCHAR(36)` database
columns. Send IDs as JSON strings or query-parameter strings. IDs cannot be
empty or longer than 36 characters.

---

## Image uploads

### Upload a picture

```http
POST /api/upload/post/picture
Content-Type: multipart/form-data
```

Uploads one validated image to DigitalOcean Spaces under `personal/hey/` and
returns its public URL. This endpoint can be used before signup, so it does not
require a login session.

Multipart form fields:

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `picture` | file | Yes | JPEG, PNG, WEBP, or GIF; maximum 10 MB |

Do not manually set the multipart `Content-Type` header in browser code; the
browser must add its boundary.

```js
const form = new FormData();
form.append("picture", selectedFile);

const response = await fetch(`${API_BASE_URL}/api/upload/post/picture`, {
  method: "POST",
  body: form
});
const result = await response.json();
const imageUrl = result.data.url;
```

Success — `201`:

```json
{
  "success": true,
  "data": {
    "url": "https://mg-kopi.syd1.digitaloceanspaces.com/personal/hey/IMAGE_UUID.png",
    "key": "personal/hey/IMAGE_UUID.png"
  }
}
```

Errors: `400` missing/invalid/oversized image, `502` Spaces upload failure,
`503` Spaces credentials not configured.

---

## Authentication

### Sign up

```http
POST /api/auth/post/signup
```

Creates a user. Photo fields are URL strings; this API does not upload files.
Signup does not log the user in automatically—call the login endpoint next.

Request body:

```json
{
  "first_name": "Blue",
  "last_name": "Panda",
  "email": "blue@example.com",
  "password": "strong-password",
  "phone_number": "0400000000",
  "id_photo": "https://cdn.example.com/id.jpg",
  "face_photo": "https://cdn.example.com/face.jpg"
}
```

Validation:

- All fields are required.
- `first_name` and `last_name`: 1–100 characters.
- `email`: maximum 255 characters and must contain a basic valid `@` structure.
- `password`: 8–128 characters.
- `phone_number`: 1–30 characters.
- Photos: valid `http://` or `https://` URLs, maximum 2048 characters.

Success — `201`:

```json
{
  "success": true,
  "data": {
    "id": "e8d66ac8-494f-4208-a96f-c75654504847",
    "first_name": "Blue",
    "last_name": "Panda",
    "email": "blue@example.com"
  }
}
```

Errors: `400` invalid input, `409` email already registered, `500` database error.

### Login

```http
POST /api/auth/post/login
```

Request body:

```json
{
  "email": "blue@example.com",
  "password": "strong-password"
}
```

Success — `200` plus a `Set-Cookie` session header:

```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "id": "e8d66ac8-494f-4208-a96f-c75654504847",
    "first_name": "Blue",
    "last_name": "Panda",
    "email": "blue@example.com"
  }
}
```

Errors: `400` missing/invalid body, `401` invalid email or password, `500`
database error. Login deliberately uses the same `401` message whether the email
or password is wrong.

### Logout

```http
POST /api/auth/post/logout
```

Send the session cookie with `credentials: "include"`.

Success — `200`:

```json
{
  "success": true,
  "message": "Logout successful"
}
```

---

## Requests

### Cancel a request

```http
POST /api/request/post/cancel-request
```

Authentication: session cookie required; `X-User-ID` is a temporary fallback.
Only the user who created the request can cancel it.

Request body:

```json
{
  "request_id": "06b1f081-00c6-4e41-a37d-b9ddd17682a7"
}
```

The backend performs these changes in one transaction:

- Sets the request status to `cancelled`.
- Cancels pending and accepted `request_participants` rows.
- If a meetup has already been created, sets its status to `cancelled`.
- Changes joined meetup participants to `cancelled`.

Expired or already cancelled requests cannot be cancelled again. A meetup that
has already been completed cannot be cancelled.

Success — `200`:

```json
{
  "success": true,
  "message": "Request cancelled successfully",
  "data": {
    "request_id": "06b1f081-00c6-4e41-a37d-b9ddd17682a7",
    "status": "cancelled"
  }
}
```

Errors: `400` invalid input/missing identity, `403` user is not the creator,
`404` request not found, `409` request or meetup cannot be cancelled, `500`
database error.

### Submit a request

```http
POST /api/request/post/submit-request
```

Authentication: session cookie required; `X-User-ID` is a temporary fallback.

Request body:

```json
{
  "title": "Lunch at Broadway",
  "min_people": 2,
  "max_people": 4,
  "time": "2026-08-29T13:00:00",
  "location": {
    "latitude": -33.8832,
    "longitude": 151.1943,
    "place_name": "Broadway"
  },
  "expired_time": "2026-08-29T13:30:00"
}
```

Validation:

- All fields are required.
- `min_people` must be at least 1.
- `max_people` must be greater than or equal to `min_people`.
- Latitude: `-90` to `90`; longitude: `-180` to `180`.
- `time` and `expired_time` use ISO 8601.
- `expired_time` must be later than `time`.

Success — `201`:

```json
{
  "success": true,
  "data": {
    "request_id": "06b1f081-00c6-4e41-a37d-b9ddd17682a7",
    "creator_id": "e8d66ac8-494f-4208-a96f-c75654504847",
    "title": "Lunch at Broadway",
    "min_people": 2,
    "max_people": 4,
    "location": {
      "latitude": -33.8832,
      "longitude": 151.1943,
      "place_name": "Broadway"
    },
    "status": "open",
    "time": "2026-08-29T13:00:00",
    "expired_time": "2026-08-29T13:30:00"
  }
}
```

Errors: `400` invalid input or missing identity, `404` session user not found,
`500` database error.

### Get nearby open requests

```http
GET /api/request/get/all-request?latitude=-33.8832&longitude=151.1943&radius=5
```

Parameters can also be sent in a JSON body, but query parameters are recommended
for browser compatibility. `radius` is measured in kilometres.

| Parameter | Type | Rules |
| --- | --- | --- |
| `latitude` | number | Required, `-90` to `90` |
| `longitude` | number | Required, `-180` to `180` |
| `radius` | number | Required, at least `0`, kilometres |

Success — `200`:

```json
{
  "success": true,
  "data": [
    {
      "request_id": "06b1f081-00c6-4e41-a37d-b9ddd17682a7",
      "creator_id": "e8d66ac8-494f-4208-a96f-c75654504847",
      "title": "Lunch at Broadway",
      "min_people": 2,
      "max_people": 4,
      "location": {
        "latitude": -33.8832,
        "longitude": 151.1943,
        "place_name": "Broadway"
      },
      "status": "open",
      "time": "2026-08-29T13:00:00",
      "expired_time": "2026-08-29T13:30:00"
    }
  ]
}
```

Errors: `400` invalid coordinates/radius, `500` database error.

### Request details

These two URLs are aliases for the same handler and response:

```http
GET /api/home/get/request-details?request_id=06b1f081-00c6-4e41-a37d-b9ddd17682a7
GET /api/home/get/own-request-details?request_id=06b1f081-00c6-4e41-a37d-b9ddd17682a7
```

`request_id` is a required `VARCHAR(36)` string. A JSON body is also accepted,
though query parameters are recommended.

Success — `200`:

```json
{
  "success": true,
  "data": {
    "anonymous_name": "Blue Panda",
    "reliability_score": 95.5,
    "location": "Broadway",
    "min_people": 2,
    "max_people": 4,
    "meet_time": "2026-08-29T13:00:00",
    "expires_at": "2026-08-29T13:30:00"
  }
}
```

Errors: `400` missing/invalid ID, `404` request not found, `500` database error.

### Get own request location

```http
GET /api/home/get/own-request?request_id=06b1f081-00c6-4e41-a37d-b9ddd17682a7
```

`request_id` is a required `VARCHAR(36)` string.

Success — `200`:

```json
{
  "success": true,
  "data": {
    "location": {
      "latitude": -33.8832,
      "longitude": 151.1943,
      "place_name": "Broadway"
    }
  }
}
```

Errors: `400` missing/invalid ID, `404` request not found, `500` database error.

---

## Meetup chat

### Send a message

```http
POST /api/meetup-chat/post/send-message
```

Authentication: session cookie required; `X-User-ID` is a temporary fallback.

Request body:

```json
{
  "meetup_id": "meetup-001",
  "message": "Hey! I'm already at the cafe"
}
```

Rules:

- `meetup_id` is required and cannot exceed 36 characters.
- `message` is required and cannot exceed 5000 characters.
- The meetup must exist and cannot be cancelled.
- The sender must be a meetup participant with `joined` or `attended` status.

Success — `201`:

```json
{
  "success": true,
  "message": "Message sent successfully",
  "data": {
    "meetup_id": "meetup-001",
    "message": {
      "id": "msg-001",
      "sender_id": "user-123",
      "sender": {
        "anonymous_name": "Blue Panda",
        "img_url": "https://example.com/avatar1.jpg"
      },
      "message": "Hey! I'm already at the cafe",
      "created_at": "2026-08-29T12:25:14+10:00"
    }
  }
}
```

Errors: `400` invalid input/missing identity, `403` sender cannot access the
chat, `404` meetup not found, `500` database error.

### Get all messages for a meetup

```http
GET /api/meetup-chat/get/all-messages?meetup_id=MEETUP_UUID
```

`meetup_id` can also be supplied in a JSON body. Query parameters are preferred.
Messages are ordered oldest first. Timestamps are returned in the configured
`Australia/Sydney` timezone.

Success — `200`:

```json
{
  "success": true,
  "data": {
    "meetup_id": "meetup-001",
    "messages": [
      {
        "id": "msg-001",
        "sender_id": "user-123",
        "sender": {
          "anonymous_name": "Blue Panda",
          "img_url": "https://example.com/avatar1.jpg"
        },
        "message": "Hey! I'm already at the cafe",
        "created_at": "2026-08-29T12:25:14+10:00"
      }
    ]
  }
}
```

`sender.img_url` can be `null`. Errors: `400` missing meetup ID, `404` meetup
not found, `500` database error.

---

## Users and meetup profiles

### Reveal own profile to meetup participants

```http
POST /api/meetup/post/reveal-profile
```

Authentication: session cookie required; `X-User-ID` is a temporary fallback.
New `meetup_participants` rows default to `is_reveal: false`. This endpoint
changes the logged-in participant's value to `true`.

Request body:

```json
{
  "meetup_id": "meetup-001"
}
```

Success — `200`:

```json
{
  "success": true,
  "message": "Profile reveal enabled",
  "data": {
    "meetup_id": "meetup-001",
    "user_id": "user-123",
    "is_reveal": true
  }
}
```

Participants with `left` or `cancelled` attendance cannot reveal their profile.
Errors: `400` invalid input/missing identity, `403` inactive participant, `404`
participant not found, `500` database error.

### Get all meetup participant rows

```http
GET /api/meetup/get/all-participants?meetup_id=meetup-001
```

Authentication: session cookie required; `X-User-ID` is a temporary fallback.
Only a user who exists in this meetup's `meetup_participants` table can read the
list. The response includes every column from `meetup_participants`.

Success — `200`:

```json
{
  "success": true,
  "data": {
    "meetup_id": "meetup-001",
    "participants": [
      {
        "meetup_id": "meetup-001",
        "user_id": "user-123",
        "attendance_status": "joined",
        "joined_at": "2026-08-30T09:00:00",
        "is_reveal": false
      },
      {
        "meetup_id": "meetup-001",
        "user_id": "user-456",
        "attendance_status": "attended",
        "joined_at": "2026-08-30T09:01:00",
        "is_reveal": true
      }
    ]
  }
}
```

Errors: `400` invalid meetup ID/missing identity, `403` caller is not a meetup
participant, `404` meetup not found, `500` database error.

### Check meetup and request participation

```http
GET /api/meetup/get/participant-status?meetup_id=meetup-001
```

Authentication: session cookie required; `X-User-ID` is a temporary fallback.
The backend checks the logged-in user in both `meetup_participants` and the
linked request's `request_participants` row.

Success — `200`:

```json
{
  "success": true,
  "data": {
    "meetup_id": "meetup-001",
    "request_id": "request-001",
    "user_id": "user-123",
    "meetup_participant": {
      "exists": true,
      "attendance_status": "joined",
      "joined_at": "2026-08-30T09:00:00"
    },
    "request_participant": {
      "exists": true,
      "status": "accepted",
      "joined_at": "2026-08-30T08:50:00",
      "updated_at": "2026-08-30T09:00:00"
    }
  }
}
```

If the meetup exists but either participant row does not, the endpoint still
returns `200`; that object's `exists` value is `false` and its status/timestamp
fields are `null`.

Possible `meetup_participant.attendance_status` values are `joined`, `attended`,
`no_show`, `left`, and `cancelled`. Possible `request_participant.status` values
are `pending`, `accepted`, `rejected`, and `cancelled`.

Errors: `400` missing/invalid meetup ID or missing identity, `404` meetup not
found, `500` database error.

### Accept a meetup invitation

```http
POST /api/meetup/post/accept-invitation
```

Authentication: session cookie required; `X-User-ID` is a temporary fallback.
The authenticated user is the user accepting the invitation.

Request body:

```json
{
  "meetup_id": "meetup-001"
}
```

The backend performs these changes in one transaction:

1. Finds the meetup and its related request.
2. Requires a `pending` row for the user in `request_participants`.
3. Changes the invitation status to `accepted`.
4. Inserts the user into `meetup_participants` with status `joined` (or updates
   an existing participant row to `joined`).

Completed or cancelled meetups cannot accept invitations.

Success — `200`:

```json
{
  "success": true,
  "message": "Invitation accepted successfully",
  "data": {
    "meetup_id": "meetup-001",
    "user_id": "user-123",
    "attendance_status": "joined",
    "is_reveal": false
  }
}
```

Errors: `400` invalid input/missing identity, `404` meetup or invitation not
found, `409` invitation already processed or meetup unavailable, `500` database
error.

### Get own profile

```http
GET /api/users/get/own-profile?id=e8d66ac8-494f-4208-a96f-c75654504847
```

Despite its name, this endpoint currently uses an explicit `VARCHAR(36)` `id`;
it does not read the login session. A JSON body is also accepted.

Success — `200`:

```json
{
  "success": true,
  "data": {
    "first_name": "Blue",
    "last_name": "Panda",
    "email": "blue@example.com",
    "phone": "0400000000",
    "radius": 5.5,
    "profile_image_url": "https://example.com/avatar.jpg"
  }
}
```

Any profile field may be `null`. Errors: `400` missing/invalid ID, `404`
user not found, `500` database error.

### Edit own profile

```http
POST /api/users/post/edit-profile
```

Authentication: session cookie required; `X-User-ID` is a temporary fallback.

Request body:

```json
{
  "first_name": "Blue",
  "last_name": "Panda",
  "email": "blue@example.com",
  "phone": "0400000000",
  "radius": 5.5,
  "profile_image_url": "https://example.com/avatar.jpg"
}
```

`first_name`, `last_name`, `email`, `phone`, and `radius` are required.
`profile_image_url` is optional and may be `null` or an empty string. Radius
cannot be negative.

Success — `200`:

```json
{
  "success": true,
  "data": {}
}
```

Errors: `400` invalid input or missing identity, `404` user not found, `409`
email already in use, `500` database error.

### Get a user's shared profile

```http
GET /api/meetup/get/all-users-profiles?id=e8d66ac8-494f-4208-a96f-c75654504847
```

The route name says “all,” but the current implementation returns one user
selected by a `VARCHAR(36)` string `id`.

Success — `200`:

```json
{
  "success": true,
  "data": {
    "first_name": "Blue",
    "last_name": "Panda",
    "profile_image_url": "https://example.com/avatar.jpg",
    "reliability_score": 95.5
  }
}
```

Errors: `400` missing/invalid ID, `404` profile not found, `500` database error.

### Get a user's anonymous profile

```http
GET /api/meetup/get/all-anonymous-profiles?id=e8d66ac8-494f-4208-a96f-c75654504847
```

The current implementation returns one user selected by a `VARCHAR(36)` string
`id`.

Success — `200`:

```json
{
  "success": true,
  "data": {
    "anonymous_name": "Blue Panda",
    "profile_image_url": "https://example.com/avatar.jpg",
    "reliability_score": 95.5
  }
}
```

Errors: `400` missing/invalid ID, `404` profile not found, `500` database error.

---

## Ratings

### Submit a rating

```http
POST /api/rating/post/submit-rating
```

Authentication: session cookie required; `X-User-ID` is a temporary fallback.

Request body:

```json
{
  "meetup_id": "meetup_123",
  "to_user_id": "user_456",
  "rating": 5
}
```

Rules:

- `rating` must be an integer from 1 to 5.
- Users cannot rate themselves.
- The meetup must have status `completed`.
- Both users must have attendance status `attended`.
- A user can rate the same recipient only once per meetup.

Success — `201`:

```json
{
  "success": true,
  "message": "Rating submitted successfully",
  "data": {
    "meetup_id": "meetup_123",
    "to_user_id": "user_456",
    "rating": 5
  }
}
```

Errors: `400` invalid input/missing identity, `403` not eligible, `409` rating
already submitted, `500` database error.

---

## System endpoints

### API welcome

```http
GET /api/home
```

Response — `200`:

```json
{ "message": "Flask server is running" }
```

### Health check

```http
GET /api/home/health
```

Response — `200`:

```json
{ "status": "ok" }
```

---

## Placeholder endpoints

These routes are registered but currently return empty arrays and do not query
the database. Frontend code should not treat them as completed features.

| Method | URL | Current response |
| --- | --- | --- |
| `GET` | `/api/request` | `{ "requests": [] }` |
| `GET` | `/api/meetup-chat` | `{ "meetup_chats": [] }` |
| `GET` | `/api/meetups` | `{ "meetups": [] }` |
| `GET` | `/api/rating` | `{ "ratings": [] }` |
| `GET` | `/api/users` | `{ "users": [] }` |

## Reusable frontend helper

```js
export async function apiRequest(path, options = {}) {
  const response = await fetch(`${API_BASE_URL}${path}`, {
    credentials: "include",
    ...options,
    headers: {
      "Content-Type": "application/json",
      ...options.headers
    }
  });

  const body = await response.json();
  if (!response.ok) {
    throw new Error(body.error ?? `API request failed (${response.status})`);
  }
  return body;
}
```

Usage:

```js
const result = await apiRequest("/api/request/get/all-request?latitude=-33.8832&longitude=151.1943&radius=5");
console.log(result.data);
```
