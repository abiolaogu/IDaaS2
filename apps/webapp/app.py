"""IDaaS Platform - Flask Application Factory."""
import os
from flask import Flask
from config import config
from extensions import (
    setup_logging,
    setup_security_headers,
    setup_request_logging,
    setup_error_handlers
)
from routes import main_bp


def create_app(config_name=None):
    """
    Application factory pattern for creating Flask app instances.

    Args:
        config_name: Configuration name ('development', 'testing', 'production')

    Returns:
        Flask application instance
    """
    if config_name is None:
        config_name = os.environ.get('FLASK_ENV', 'development')

    app = Flask(__name__)

    # Load configuration
    app.config.from_object(config.get(config_name, config['default']))
    config[config_name].init_app(app)

    # Setup logging
    setup_logging(app)
    app.logger.info(f"Starting {app.config['APP_NAME']} v{app.config['APP_VERSION']}")
    app.logger.info(f"Environment: {config_name}")

    # Setup security headers
    setup_security_headers(app)

    # Setup request logging
    setup_request_logging(app)

    # Setup error handlers
    setup_error_handlers(app)

    # Register blueprints
    app.register_blueprint(main_bp)
    app.logger.info("Blueprints registered successfully")

    return app


if __name__ == "__main__":
    # Create application instance
    app = create_app()

    # Run the application
    app.run(
        host=app.config['HOST'],
        port=app.config['PORT'],
        debug=app.config['DEBUG']
    )
