# Netflix Streaming Platform

A full-featured Netflix-style video streaming platform built with FastAPI, PostgreSQL, Redis, and AWS S3.

## Architecture Overview

```
                    ┌──────────────┐
                    │   CloudFront │
                    │     CDN      │
                    └──────┬───────┘
                           │
                    ┌──────▼───────┐
                    │   FastAPI    │
                    │   Backend    │
                    └──┬───┬───┬──┘
                       │   │   │
              ┌────────┘   │   └────────┐
              │            │            │
        ┌─────▼────┐ ┌────▼─────┐ ┌────▼─────┐
        │PostgreSQL│ │  Redis   │ │ AWS S3   │
        │  (Data)  │ │ (Cache)  │ │ (Videos) │
        └──────────┘ └──────────┘ └──────────┘
```

## Features

- **User Authentication** - Registration, login, JWT-based auth
- **Multi-Profile Support** - Up to 5 profiles per account (including kids profiles)
- **Content Management** - Movies and TV series with seasons/episodes
- **Genre-Based Browsing** - Filter and browse by genre
- **Search** - Full-text search across titles, descriptions, cast, and directors
- **Watchlist ("My List")** - Save content for later viewing
- **Watch History** - Track viewing progress and resume playback
- **Recommendation Engine** - Personalized recommendations based on watch history
- **Adaptive Streaming** - Multiple quality profiles (240p to 4K) based on subscription
- **Subscription Plans** - Basic, Standard, and Premium tiers with Stripe integration
- **Netflix Originals** - Dedicated section for original content

## Tech Stack

| Component        | Technology                        |
|-----------------|-----------------------------------|
| **Backend**     | Python 3.11+, FastAPI, Uvicorn    |
| **Database**    | PostgreSQL 16, SQLAlchemy 2.0     |
| **Migrations**  | Alembic                           |
| **Cache**       | Redis 7                           |
| **Auth**        | JWT (python-jose), bcrypt         |
| **Storage**     | AWS S3, CloudFront CDN            |
| **Search**      | Elasticsearch 8                   |
| **Payments**    | Stripe                            |
| **Video**       | FFmpeg, HLS adaptive streaming    |
| **Containers**  | Docker, Docker Compose            |
| **CI/CD**       | GitHub Actions                    |
| **Logging**     | structlog (JSON structured logs)  |

## Quick Start

### Prerequisites

- Python 3.11+
- PostgreSQL 16
- Redis 7
- Docker & Docker Compose (optional)

### Option 1: Docker Compose (Recommended)

```bash
# Clone and navigate to the project
cd netflix

# Copy environment file
cp .env.example .env

# Start all services
docker compose up -d

# API available at http://localhost:8000
# API docs at http://localhost:8000/docs
```

### Option 2: Local Development

```bash
# Create virtual environment
python -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Copy and configure environment
cp .env.example .env

# Run database migrations
alembic upgrade head

# Start the server
uvicorn src.main:app --reload --host 0.0.0.0 --port 8000
```

## API Endpoints

### Authentication
| Method | Endpoint              | Description         |
|--------|-----------------------|---------------------|
| POST   | `/api/v1/auth/register` | Register new user   |
| POST   | `/api/v1/auth/login`    | Login & get tokens  |

### Content
| Method | Endpoint                    | Description              |
|--------|-----------------------------|--------------------------|
| GET    | `/api/v1/content/`          | List all content         |
| GET    | `/api/v1/content/featured`  | Get featured content     |
| GET    | `/api/v1/content/originals` | Get Netflix Originals    |
| GET    | `/api/v1/content/genres`    | List all genres          |
| GET    | `/api/v1/content/{slug}`    | Get content details      |
| POST   | `/api/v1/content/`          | Create content (admin)   |

### Profiles
| Method | Endpoint                    | Description           |
|--------|-----------------------------|-----------------------|
| GET    | `/api/v1/profiles/`         | List user profiles    |
| POST   | `/api/v1/profiles/`         | Create new profile    |
| DELETE | `/api/v1/profiles/{id}`     | Delete a profile      |

### Watchlist & History
| Method | Endpoint                                          | Description            |
|--------|---------------------------------------------------|------------------------|
| GET    | `/api/v1/profiles/{id}/watchlist`                 | Get "My List"          |
| POST   | `/api/v1/profiles/{id}/watchlist/{content_id}`    | Add to watchlist       |
| DELETE | `/api/v1/profiles/{id}/watchlist/{content_id}`    | Remove from watchlist  |
| POST   | `/api/v1/profiles/{id}/history`                   | Record watch progress  |
| GET    | `/api/v1/profiles/{id}/history`                   | Get watch history      |

### Search
| Method | Endpoint           | Description       |
|--------|--------------------|--------------------|
| GET    | `/api/v1/search/`  | Search content     |

### Health
| Method | Endpoint           | Description        |
|--------|--------------------|--------------------|
| GET    | `/api/v1/health`   | Health check       |
| GET    | `/api/v1/ready`    | Readiness check    |

## Project Structure

```
netflix/
├── src/
│   ├── api/
│   │   ├── routes/
│   │   │   ├── auth.py          # Authentication endpoints
│   │   │   ├── content.py       # Content browsing & management
│   │   │   ├── health.py        # Health checks
│   │   │   ├── profiles.py      # Profile management
│   │   │   ├── search.py        # Content search
│   │   │   └── watchlist.py     # Watchlist & watch history
│   │   └── deps.py              # Dependency injection
│   ├── core/
│   │   ├── config.py            # Application settings
│   │   ├── database.py          # Database connection
│   │   ├── logging.py           # Structured logging
│   │   └── security.py          # JWT & password hashing
│   ├── models/
│   │   ├── content.py           # Content, Genre, Season, Episode
│   │   └── user.py              # User, Profile, Subscription, WatchHistory
│   ├── schemas/
│   │   ├── content.py           # Content request/response schemas
│   │   └── user.py              # User request/response schemas
│   ├── services/
│   │   ├── recommendation.py    # Recommendation engine
│   │   └── streaming.py         # Video streaming & CDN
│   └── main.py                  # Application entry point
├── tests/
│   ├── conftest.py              # Test fixtures
│   ├── test_auth.py             # Auth tests
│   ├── test_content.py          # Content tests
│   └── test_health.py           # Health check tests
├── alembic/                     # Database migrations
├── .github/workflows/ci.yml     # CI pipeline
├── Dockerfile                   # Production Docker image
├── docker-compose.yml           # Local development stack
├── requirements.txt             # Python dependencies
└── pyproject.toml               # Project configuration
```

## Subscription Plans

| Feature          | Basic  | Standard | Premium |
|-----------------|--------|----------|---------|
| Max Resolution  | 480p   | 1080p    | 4K      |
| Concurrent Screens | 1   | 2        | 4       |
| Downloads       | No     | Yes      | Yes     |

## Running Tests

```bash
# Run all tests
pytest tests/ -v

# Run with coverage
pytest tests/ --cov=src --cov-report=html

# Run specific test category
pytest tests/ -m unit -v
```

## License

Proprietary - All rights reserved.
