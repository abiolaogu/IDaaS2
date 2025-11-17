"""Flask extensions and middleware."""
from flask import Flask, request, g
import logging
import time


def setup_logging(app: Flask) -> None:
    """Configure application logging."""
    log_level = getattr(logging, app.config['LOG_LEVEL'].upper())
    logging.basicConfig(
        level=log_level,
        format=app.config['LOG_FORMAT']
    )

    # Set Flask's logger level
    app.logger.setLevel(log_level)


def setup_security_headers(app: Flask) -> None:
    """Add security headers to all responses."""
    @app.after_request
    def add_security_headers(response):
        """Add security headers."""
        response.headers['X-Content-Type-Options'] = 'nosniff'
        response.headers['X-Frame-Options'] = 'DENY'
        response.headers['X-XSS-Protection'] = '1; mode=block'
        response.headers['Strict-Transport-Security'] = 'max-age=31536000; includeSubDomains'
        response.headers['Content-Security-Policy'] = "default-src 'self'"
        return response


def setup_request_logging(app: Flask) -> None:
    """Log all incoming requests."""
    @app.before_request
    def log_request():
        """Log request details."""
        g.start_time = time.time()
        app.logger.info(
            f"Request started: {request.method} {request.path} "
            f"from {request.remote_addr}"
        )

    @app.after_request
    def log_response(response):
        """Log response details."""
        if hasattr(g, 'start_time'):
            elapsed = time.time() - g.start_time
            app.logger.info(
                f"Request completed: {request.method} {request.path} "
                f"- Status: {response.status_code} - Duration: {elapsed:.3f}s"
            )
        return response


def setup_error_handlers(app: Flask) -> None:
    """Configure error handlers."""
    @app.errorhandler(404)
    def not_found(error):
        """Handle 404 errors."""
        app.logger.warning(f"404 error: {request.path}")
        return {"error": "Not found", "status": 404}, 404

    @app.errorhandler(500)
    def internal_error(error):
        """Handle 500 errors."""
        app.logger.error(f"500 error: {str(error)}")
        return {"error": "Internal server error", "status": 500}, 500

    @app.errorhandler(Exception)
    def handle_exception(error):
        """Handle unexpected exceptions."""
        app.logger.exception(f"Unhandled exception: {str(error)}")
        return {"error": "An unexpected error occurred", "status": 500}, 500
