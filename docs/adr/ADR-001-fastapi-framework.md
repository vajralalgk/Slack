# ADR-001: FastAPI as API Framework

**Author:** Gopi Krishna Vajrala
**Date:** 2026-02-16
**Status:** Accepted

## Context
ECTP needs a Python web framework for its REST API layer that supports async operations, automatic API documentation, and high performance.

## Decision
Use **FastAPI** as the API framework.

## Rationale
| Criteria | FastAPI | Flask | Django REST |
|----------|---------|-------|-------------|
| Async Support | Native | Extension | Limited |
| Performance | ~15k req/s | ~5k req/s | ~3k req/s |
| Auto OpenAPI | Built-in | Manual | Extension |
| Type Safety | Pydantic | Manual | Serializers |
| Learning Curve | Low | Low | Medium |

## Consequences
- Positive: Superior performance, auto-documentation, native async
- Negative: Smaller ecosystem than Flask/Django (mitigated by growing community)

## Author
Gopi Krishna Vajrala
