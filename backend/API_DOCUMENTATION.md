# API Documentation

## Base URL
```
http://localhost:8000/api
```

## Authentication

All authenticated endpoints require a JWT token in the Authorization header:
```
Authorization: Bearer <access_token>
```

### Register a new user
```http
POST /auth/register/
Content-Type: application/json

{
  "username": "johndoe",
  "email": "john@example.com",
  "password": "securepass123",
  "password2": "securepass123",
  "first_name": "John",
  "last_name": "Doe",
  "role": "citizen"
}
```

**Response (201 Created):**
```json
{
  "id": 1,
  "username": "johndoe",
  "email": "john@example.com",
  "first_name": "John",
  "last_name": "Doe",
  "role": "citizen"
}
```

### Login
```http
POST /auth/login/
Content-Type: application/json

{
  "username": "johndoe",
  "password": "securepass123"
}
```

**Response (200 OK):**
```json
{
  "access": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc..."
}
```

### Get User Profile
```http
GET /auth/profile/
Authorization: Bearer <access_token>
```

**Response (200 OK):**
```json
{
  "id": 1,
  "username": "johndoe",
  "email": "john@example.com",
  "first_name": "John",
  "last_name": "Doe",
  "role": "citizen",
  "phone_number": null,
  "address": null,
  "profile_image": null,
  "created_at": "2024-01-01T00:00:00Z",
  "updated_at": "2024-01-01T00:00:00Z"
}
```

## Garbage Reports

### Create a Report
```http
POST /reports/
Authorization: Bearer <access_token>
Content-Type: multipart/form-data

title: "Large pile of garbage"
description: "There's a large pile of household waste near the park"
garbage_type: "household"
latitude: 40.7128
longitude: -74.0060
address: "123 Main St, New York, NY"
image: <file>
```

**Response (201 Created):**
```json
{
  "id": 1,
  "reporter": {
    "id": 1,
    "username": "johndoe",
    "email": "john@example.com",
    "role": "citizen"
  },
  "title": "Large pile of garbage",
  "description": "There's a large pile of household waste near the park",
  "garbage_type": "household",
  "status": "pending",
  "latitude": "40.712800",
  "longitude": "-74.006000",
  "address": "123 Main St, New York, NY",
  "image": "/media/garbage_reports/image.jpg",
  "comments": [],
  "created_at": "2024-01-01T00:00:00Z",
  "updated_at": "2024-01-01T00:00:00Z"
}
```

### List All Reports
```http
GET /reports/
Authorization: Bearer <access_token>

Optional query parameters:
- status: pending, assigned, in_progress, completed, rejected
- garbage_type: household, recyclable, hazardous, electronic, construction, other
- search: search in title, description, address
```

**Response (200 OK):**
```json
{
  "count": 10,
  "next": "http://localhost:8000/api/reports/?page=2",
  "previous": null,
  "results": [
    {
      "id": 1,
      "reporter": {...},
      "title": "Large pile of garbage",
      "status": "pending",
      ...
    }
  ]
}
```

### Get Report Details
```http
GET /reports/{id}/
Authorization: Bearer <access_token>
```

### Get My Reports
```http
GET /reports/my-reports/
Authorization: Bearer <access_token>
```

## Collection Tasks

### Create a Task (Admin only)
```http
POST /tasks/
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "report": 1,
  "collector": 2,
  "priority": "high",
  "notes": "Please collect before 5 PM"
}
```

**Response (201 Created):**
```json
{
  "id": 1,
  "report": {...},
  "collector": {...},
  "assigned_by": {...},
  "status": "assigned",
  "priority": "high",
  "notes": "Please collect before 5 PM",
  "completion_notes": null,
  "assigned_at": "2024-01-01T00:00:00Z",
  "started_at": null,
  "completed_at": null,
  "updated_at": "2024-01-01T00:00:00Z"
}
```

### List All Tasks
```http
GET /tasks/
Authorization: Bearer <access_token>

Optional query parameters:
- status: assigned, in_progress, completed, cancelled
- priority: low, medium, high, urgent
- collector: <collector_id>
```

### Get My Tasks (Collector only)
```http
GET /tasks/my-tasks/
Authorization: Bearer <access_token>
```

### Update Task Status
```http
PATCH /tasks/{id}/
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "status": "in_progress",
  "completion_notes": "Started collection"
}
```

**Response (200 OK):**
```json
{
  "id": 1,
  "status": "in_progress",
  "started_at": "2024-01-01T10:00:00Z",
  ...
}
```

## Error Responses

### 400 Bad Request
```json
{
  "field_name": ["Error message"]
}
```

### 401 Unauthorized
```json
{
  "detail": "Authentication credentials were not provided."
}
```

### 403 Forbidden
```json
{
  "detail": "You do not have permission to perform this action."
}
```

### 404 Not Found
```json
{
  "detail": "Not found."
}
```

## Status Codes

- `200 OK` - Request successful
- `201 Created` - Resource created successfully
- `400 Bad Request` - Invalid request data
- `401 Unauthorized` - Authentication required
- `403 Forbidden` - Permission denied
- `404 Not Found` - Resource not found
- `500 Internal Server Error` - Server error

## Rate Limiting

Currently, no rate limiting is implemented. In production, implement rate limiting to prevent abuse.

## Pagination

List endpoints return paginated results with:
- `count`: Total number of items
- `next`: URL to next page
- `previous`: URL to previous page
- `results`: Array of items

Default page size: 20 items

## Interactive Documentation

Access interactive API documentation:
- Swagger UI: `http://localhost:8000/swagger/`
- ReDoc: `http://localhost:8000/redoc/`
