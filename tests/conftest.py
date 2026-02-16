"""
============================================================================
Enterprise Cloud Transformation Platform (ECTP)
Pytest Configuration and Shared Fixtures
Author: Gopi Krishna Vajrala
============================================================================

WHY THIS MODULE EXISTS:
    conftest.py is automatically loaded by pytest and provides shared
    test fixtures available to ALL test files without explicit import.
    This enables:
    1. Consistent test setup across all test modules
    2. Reusable mock objects for external dependencies
    3. Test isolation (each test gets fresh fixtures)
    4. Clean test code (no boilerplate setup in each test)
============================================================================
"""

import os
import pytest


# Set test environment variables BEFORE importing application modules.
# WHY: Settings are loaded at import time, so env vars must be set first.
os.environ["ECTP_ENV"] = "development"
os.environ["ECTP_DEBUG"] = "true"
os.environ["ECTP_LOG_LEVEL"] = "DEBUG"
os.environ["ECTP_DB_HOST"] = "localhost"
os.environ["ECTP_DB_NAME"] = "ectp_test"
os.environ["ECTP_DB_USER"] = "test_user"
os.environ["ECTP_DB_PASSWORD"] = "test_password"
os.environ["ECTP_JWT_SECRET_KEY"] = "test-secret-key-for-testing-only"


@pytest.fixture
def test_settings():
    """
    Provides a test Settings instance with known values.

    WHY: Tests need predictable configuration values.
    This fixture ensures tests don't depend on the developer's
    local .env file or system environment variables.
    """
    from src.core.config.settings import Settings
    return Settings(
        app_name="ECTP-Test",
        env="development",
        debug=True,
        log_level="DEBUG",
        db_host="localhost",
        db_port=5432,
        db_name="ectp_test",
        db_user="test_user",
        db_password="test_password",
    )


@pytest.fixture
def sample_migration_plan():
    """
    Provides a sample migration plan for testing.

    WHY: Many tests need a valid migration plan object.
    This fixture provides one with all required fields populated.
    """
    return {
        "name": "Test Banner DB Migration",
        "description": "Migrate Banner database from on-prem to AWS RDS",
        "strategy": "replatform",
        "source_system": "Banner Oracle DB",
        "target_aws_service": "RDS PostgreSQL",
        "priority": 2,
        "owner": "Cloud Operations",
        "estimated_downtime_minutes": 120,
    }


@pytest.fixture
def sample_incident():
    """Provides a sample ServiceNow incident for testing."""
    return {
        "short_description": "Test RDS connection pool exhausted",
        "description": "Database connection pool reached maximum capacity during peak enrollment",
        "priority": "2",
        "category": "Cloud Infrastructure",
        "assignment_group": "Cloud Operations",
    }
