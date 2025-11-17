"""
End-to-End tests for the IDaaS Platform.

This is a simulated end-to-end test suite. It verifies that the web application
correctly handles headers that would be passed by the authentication proxy.
For real E2E tests, consider using Selenium or Playwright for browser automation.
"""
import requests
import pytest
import time
import os

# Base URL can be configured via environment variable
BASE_URL = os.environ.get("E2E_BASE_URL", "http://localhost:8080")


class TestHealthEndpoints:
    """Test health check and monitoring endpoints."""

    def test_health_endpoint(self):
        """Verify health check endpoint returns healthy status."""
        response = requests.get(f"{BASE_URL}/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"
        assert "timestamp" in data
        assert "service" in data
        assert "version" in data

    def test_readiness_endpoint(self):
        """Verify readiness probe endpoint."""
        response = requests.get(f"{BASE_URL}/readiness")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "ready"
        assert "timestamp" in data

    def test_liveness_endpoint(self):
        """Verify liveness probe endpoint."""
        response = requests.get(f"{BASE_URL}/liveness")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "alive"

    def test_metrics_endpoint(self):
        """Verify metrics endpoint returns application information."""
        response = requests.get(f"{BASE_URL}/metrics")
        assert response.status_code == 200
        data = response.json()
        assert "app_name" in data
        assert "version" in data
        assert "python_version" in data


class TestAuthenticationFlow:
    """Test authentication flows with OAuth2 Proxy headers."""

    def test_unauthenticated_access(self):
        """
        Simulates a request from an unauthenticated user.
        OAuth2-Proxy would not forward any identity headers.
        """
        response = requests.get(BASE_URL)
        assert response.status_code == 200
        data = response.json()
        assert data["authenticated"] is False
        assert "stranger" in data["message"].lower()

    def test_authenticated_access_email_only(self):
        """
        Simulates a request from an authenticated user with email.
        OAuth2-Proxy adds the X-Forwarded-Email header after successful login.
        """
        headers = {"X-Forwarded-Email": "test@example.com"}
        response = requests.get(BASE_URL, headers=headers)
        assert response.status_code == 200
        data = response.json()
        assert data["authenticated"] is True
        assert data["email"] == "test@example.com"
        assert "test@example.com" in data["message"]

    def test_authenticated_access_with_user(self):
        """Test authenticated request with email and username."""
        headers = {
            "X-Forwarded-Email": "admin@example.com",
            "X-Forwarded-User": "admin"
        }
        response = requests.get(BASE_URL, headers=headers)
        assert response.status_code == 200
        data = response.json()
        assert data["authenticated"] is True
        assert data["email"] == "admin@example.com"
        assert data["user"] == "admin"

    def test_authenticated_access_with_groups(self):
        """Test authenticated request with groups."""
        headers = {
            "X-Forwarded-Email": "developer@example.com",
            "X-Forwarded-User": "dev1",
            "X-Forwarded-Groups": "developers,admins,users"
        }
        response = requests.get(BASE_URL, headers=headers)
        assert response.status_code == 200
        data = response.json()
        assert data["authenticated"] is True
        assert data["email"] == "developer@example.com"
        assert data["user"] == "dev1"
        assert "developers" in data["groups"]
        assert "admins" in data["groups"]
        assert "users" in data["groups"]


class TestAPIEndpoints:
    """Test API endpoints."""

    def test_user_info_unauthenticated(self):
        """Test user-info endpoint without authentication."""
        response = requests.get(f"{BASE_URL}/api/user-info")
        assert response.status_code == 401
        data = response.json()
        assert data["authenticated"] is False
        assert "error" in data

    def test_user_info_authenticated(self):
        """Test user-info endpoint with authentication."""
        headers = {
            "X-Forwarded-Email": "testuser@example.com",
            "X-Forwarded-User": "testuser",
            "X-Forwarded-Groups": "testers"
        }
        response = requests.get(f"{BASE_URL}/api/user-info", headers=headers)
        assert response.status_code == 200
        data = response.json()
        assert data["authenticated"] is True
        assert data["email"] == "testuser@example.com"
        assert data["username"] == "testuser"
        assert "testers" in data["groups"]
        assert "timestamp" in data


class TestSecurityHeaders:
    """Test security headers are present in responses."""

    def test_security_headers_present(self):
        """Verify security headers are present in responses."""
        response = requests.get(BASE_URL)

        # Check for common security headers
        assert "X-Content-Type-Options" in response.headers
        assert response.headers["X-Content-Type-Options"] == "nosniff"

        assert "X-Frame-Options" in response.headers
        assert response.headers["X-Frame-Options"] == "DENY"

        assert "X-XSS-Protection" in response.headers

        assert "Strict-Transport-Security" in response.headers

        assert "Content-Security-Policy" in response.headers


class TestErrorHandling:
    """Test error handling."""

    def test_404_not_found(self):
        """Test 404 error for non-existent endpoints."""
        response = requests.get(f"{BASE_URL}/nonexistent")
        assert response.status_code == 404
        data = response.json()
        assert "error" in data
        assert data["status"] == 404


class TestPerformance:
    """Basic performance tests."""

    def test_response_time_health(self):
        """Verify health endpoint responds quickly."""
        start_time = time.time()
        response = requests.get(f"{BASE_URL}/health")
        elapsed = time.time() - start_time

        assert response.status_code == 200
        # Health check should respond in under 1 second
        assert elapsed < 1.0

    def test_response_time_main(self):
        """Verify main endpoint responds quickly."""
        start_time = time.time()
        response = requests.get(BASE_URL)
        elapsed = time.time() - start_time

        assert response.status_code == 200
        # Main endpoint should respond in under 2 seconds
        assert elapsed < 2.0


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
