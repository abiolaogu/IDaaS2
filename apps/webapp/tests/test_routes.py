"""Tests for application routes."""
import pytest
import json
from app import create_app


class TestRoutes:
    """Test application routes."""

    @pytest.fixture
    def app(self):
        """Create application instance for testing."""
        app = create_app('testing')
        return app

    @pytest.fixture
    def client(self, app):
        """Create test client."""
        return app.test_client()

    def test_index_unauthenticated(self, client):
        """Test index route without authentication."""
        response = client.get('/')
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['authenticated'] is False
        assert 'stranger' in data['message']

    def test_index_authenticated(self, client):
        """Test index route with authentication."""
        headers = {'X-Forwarded-Email': 'test@example.com'}
        response = client.get('/', headers=headers)
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['authenticated'] is True
        assert data['email'] == 'test@example.com'
        assert 'test@example.com' in data['message']

    def test_index_with_all_headers(self, client):
        """Test index route with all forwarded headers."""
        headers = {
            'X-Forwarded-Email': 'admin@example.com',
            'X-Forwarded-User': 'admin',
            'X-Forwarded-Groups': 'admin,users'
        }
        response = client.get('/', headers=headers)
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['authenticated'] is True
        assert data['email'] == 'admin@example.com'
        assert data['user'] == 'admin'
        assert 'admin' in data['groups']
        assert 'users' in data['groups']

    def test_health_endpoint(self, client):
        """Test health check endpoint."""
        response = client.get('/health')
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['status'] == 'healthy'
        assert 'timestamp' in data
        assert data['service'] == 'IDaaS Platform'
        assert data['version'] == '1.0.0'

    def test_readiness_endpoint(self, client):
        """Test readiness probe endpoint."""
        response = client.get('/readiness')
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['status'] == 'ready'
        assert 'timestamp' in data

    def test_liveness_endpoint(self, client):
        """Test liveness probe endpoint."""
        response = client.get('/liveness')
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['status'] == 'alive'
        assert 'timestamp' in data

    def test_metrics_endpoint(self, client):
        """Test metrics endpoint."""
        response = client.get('/metrics')
        assert response.status_code == 200
        data = json.loads(response.data)
        assert 'app_name' in data
        assert 'version' in data
        assert 'python_version' in data
        assert 'platform' in data
        assert 'timestamp' in data

    def test_user_info_unauthenticated(self, client):
        """Test user info endpoint without authentication."""
        response = client.get('/api/user-info')
        assert response.status_code == 401
        data = json.loads(response.data)
        assert data['authenticated'] is False
        assert 'error' in data

    def test_user_info_authenticated(self, client):
        """Test user info endpoint with authentication."""
        headers = {
            'X-Forwarded-Email': 'user@example.com',
            'X-Forwarded-User': 'testuser',
            'X-Forwarded-Groups': 'developers,testers'
        }
        response = client.get('/api/user-info', headers=headers)
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['authenticated'] is True
        assert data['email'] == 'user@example.com'
        assert data['username'] == 'testuser'
        assert 'developers' in data['groups']
        assert 'testers' in data['groups']

    def test_404_error(self, client):
        """Test 404 error handling."""
        response = client.get('/nonexistent')
        assert response.status_code == 404
        data = json.loads(response.data)
        assert 'error' in data
        assert data['status'] == 404

    def test_security_headers(self, client):
        """Test security headers are present."""
        response = client.get('/')
        assert 'X-Content-Type-Options' in response.headers
        assert response.headers['X-Content-Type-Options'] == 'nosniff'
        assert 'X-Frame-Options' in response.headers
        assert response.headers['X-Frame-Options'] == 'DENY'
        assert 'X-XSS-Protection' in response.headers
        assert 'Strict-Transport-Security' in response.headers
        assert 'Content-Security-Policy' in response.headers
