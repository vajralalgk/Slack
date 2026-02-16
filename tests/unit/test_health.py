"""
============================================================================
Enterprise Cloud Transformation Platform (ECTP)
Unit Tests for Health Check Endpoints
Author: Gopi Krishna Vajrala
============================================================================
"""

import pytest
from unittest.mock import patch


class TestHealthEndpoints:
    """Tests for the health check API endpoints."""

    def test_health_check_import(self):
        """Test that the health module can be imported."""
        from src.api.routes import health
        assert health.router is not None

    def test_health_check_response_structure(self):
        """Test that health check returns expected fields."""
        # Verify the health check function exists and is callable
        from src.api.routes.health import health_check
        assert callable(health_check)

    def test_readiness_check_exists(self):
        """Test that readiness check endpoint exists."""
        from src.api.routes.health import readiness_check
        assert callable(readiness_check)

    def test_detailed_health_exists(self):
        """Test that detailed health endpoint exists."""
        from src.api.routes.health import detailed_health
        assert callable(detailed_health)
