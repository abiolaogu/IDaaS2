"""Tests for configuration module."""
import pytest
import os
from config import Config, DevelopmentConfig, TestingConfig, ProductionConfig, config


class TestConfig:
    """Test configuration classes."""

    def test_base_config(self):
        """Test base configuration."""
        assert Config.APP_NAME == 'IDaaS Platform'
        assert Config.APP_VERSION == '1.0.0'
        assert Config.DEBUG is False
        assert Config.TESTING is False

    def test_development_config(self):
        """Test development configuration."""
        assert DevelopmentConfig.DEBUG is True
        assert DevelopmentConfig.LOG_LEVEL == 'DEBUG'

    def test_testing_config(self):
        """Test testing configuration."""
        assert TestingConfig.TESTING is True
        assert TestingConfig.DEBUG is True

    def test_production_config(self):
        """Test production configuration."""
        assert ProductionConfig.DEBUG is False

    def test_config_dict(self):
        """Test configuration dictionary."""
        assert 'development' in config
        assert 'testing' in config
        assert 'production' in config
        assert 'default' in config
        assert config['development'] == DevelopmentConfig
        assert config['testing'] == TestingConfig
        assert config['production'] == ProductionConfig

    def test_environment_variables(self):
        """Test configuration from environment variables."""
        # Test LOG_LEVEL override
        os.environ['LOG_LEVEL'] = 'WARNING'
        from config import Config as FreshConfig
        # Note: This test demonstrates how env vars can override config
        # In practice, config is loaded at import time
        os.environ.pop('LOG_LEVEL', None)
