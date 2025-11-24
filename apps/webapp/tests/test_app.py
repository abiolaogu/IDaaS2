"""Tests for application factory."""
import pytest
import os
from app import create_app


class TestAppFactory:
    """Test application factory."""

    def test_create_app_default(self):
        """Test creating app with default configuration."""
        app = create_app()
        assert app is not None
        assert app.config['APP_NAME'] == 'IDaaS Platform'

    def test_create_app_development(self):
        """Test creating app with development configuration."""
        app = create_app('development')
        assert app.config['DEBUG'] is True

    def test_create_app_testing(self):
        """Test creating app with testing configuration."""
        app = create_app('testing')
        assert app.config['TESTING'] is True

    def test_create_app_production_requires_secret_key(self):
        """Test that production configuration requires SECRET_KEY to be set."""
        # Without SECRET_KEY, production should raise ValueError
        with pytest.raises(ValueError, match='SECRET_KEY must be set'):
            create_app('production')

    def test_blueprints_registered(self):
        """Test that blueprints are registered."""
        app = create_app('testing')
        # Check that main blueprint is registered
        assert 'main' in [bp.name for bp in app.blueprints.values()]

    def test_error_handlers_registered(self):
        """Test that error handlers are registered."""
        app = create_app('testing')
        client = app.test_client()

        # Test 404 handler
        response = client.get('/nonexistent')
        assert response.status_code == 404

    def test_app_context(self):
        """Test application context."""
        app = create_app('testing')
        with app.app_context():
            assert app.config['APP_NAME'] == 'IDaaS Platform'
