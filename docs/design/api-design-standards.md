# ECTP API Design Standards

**Author:** Gopi Krishna Vajrala
**Version:** 1.0.0

## URL Structure
```
/api/v{version}/{resource}
/api/v1/migration/plans
/api/v1/servicenow/incidents
/api/v1/ellucian/students
/api/v1/cost/summary
```

## HTTP Methods
| Method | Usage | Idempotent |
|--------|-------|-----------|
| GET | Read resource(s) | Yes |
| POST | Create resource | No |
| PUT | Full update | Yes |
| PATCH | Partial update | Yes |
| DELETE | Remove resource | Yes |

## Response Format
```json
{
    "data": {},
    "meta": {
        "timestamp": "2026-02-16T12:00:00Z",
        "correlation_id": "abc123"
    }
}
```

## Error Format
```json
{
    "error_code": "NOT_FOUND",
    "message": "Resource not found",
    "details": {}
}
```

## Status Codes
| Code | Usage |
|------|-------|
| 200 | Success |
| 201 | Created |
| 204 | No Content (delete) |
| 400 | Bad Request |
| 401 | Unauthorized |
| 403 | Forbidden |
| 404 | Not Found |
| 422 | Validation Error |
| 429 | Rate Limited |
| 500 | Internal Error |
| 502 | External Service Error |

## Pagination
```
GET /api/v1/migration/plans?limit=50&offset=100
```

## Versioning
- URL-based versioning (/api/v1/, /api/v2/)
- Major versions only (breaking changes)
- Old versions supported for 12 months after deprecation

## Authentication
- Bearer token (JWT) in Authorization header
- API keys for service-to-service calls
- SAML 2.0 for SSO federation

## Rate Limiting
- 1000 requests per minute per client
- 429 response with Retry-After header
- Rate limit headers in every response
