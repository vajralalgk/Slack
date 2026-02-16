# Getting Started with ECTP

**Author:** Gopi Krishna Vajrala
**Audience:** New team members, developers, and operators

---

## Welcome to ECTP

The Enterprise Cloud Transformation Platform (ECTP) is your organization's unified platform for cloud infrastructure, IT service management, and Higher Education system integration.

## Quick Start (5 Minutes)

### 1. Clone the Repository
```bash
git clone <repository-url>
cd ECTP
```

### 2. Set Up Python Environment
```bash
# Create virtual environment
python3.11 -m venv .venv
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### 3. Configure Environment
```bash
# Copy example environment file
cp .env.example .env

# Edit .env with your local settings
# At minimum, set:
#   ECTP_DB_PASSWORD=your_local_postgres_password
#   ECTP_REDIS_HOST=localhost
```

### 4. Start Local Services (Docker)
```bash
# Start PostgreSQL and Redis
docker-compose -f deployment/docker/docker-compose.yml up -d
```

### 5. Run the Application
```bash
# Start the API server
uvicorn src.api.main:app --reload --host 0.0.0.0 --port 8000
```

### 6. Access the API
- **Swagger UI:** http://localhost:8000/docs
- **ReDoc:** http://localhost:8000/redoc
- **Health Check:** http://localhost:8000/health

## Next Steps

- Read the [Architecture Document](../architecture/architecture-document.md)
- Review the [API Design Standards](../design/api-design-standards.md)
- Check the [Contributing Guide](../../CONTRIBUTING.md)
- Explore the [Admin Runbook](../runbooks/admin-runbook.md)

## Getting Help

- Check documentation in `/docs`
- Review Architecture Decision Records in `/docs/adr`
- Contact: Gopi Krishna Vajrala (Platform Architect)
