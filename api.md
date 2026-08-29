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
