"""Application routes and views."""
from flask import Blueprint, request, jsonify, current_app
from datetime import datetime
import platform
import sys

# Create blueprint for main routes
main_bp = Blueprint('main', __name__)


@main_bp.route('/')
def index():
    """Main route that displays authenticated user information."""
    try:
        # Get forwarded headers from OAuth2 Proxy
        email = request.headers.get(current_app.config['FORWARDED_EMAIL_HEADER'])
        user = request.headers.get(current_app.config['FORWARDED_USER_HEADER'])
        groups = request.headers.get(current_app.config['FORWARDED_GROUPS_HEADER'])

        if email:
            current_app.logger.info(f"Authenticated user: {email}")
            response_data = {
                "message": f"Hello, {email}! You are authenticated.",
                "authenticated": True,
                "user": user,
                "email": email,
                "groups": groups.split(',') if groups else []
            }
            return jsonify(response_data), 200
        else:
            current_app.logger.debug("Unauthenticated request")
            return jsonify({
                "message": "Hello, stranger! You are not authenticated.",
                "authenticated": False
            }), 200
    except Exception as e:
        current_app.logger.error(f"Error processing request: {str(e)}")
        return jsonify({
            "error": "Failed to process request",
            "message": str(e)
        }), 500


@main_bp.route('/health')
def health():
    """Health check endpoint for monitoring and load balancers."""
    return jsonify({
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat(),
        "service": current_app.config['APP_NAME'],
        "version": current_app.config['APP_VERSION']
    }), 200


@main_bp.route('/readiness')
def readiness():
    """Readiness probe for Kubernetes."""
    # Add any checks here (database connections, external services, etc.)
    try:
        # For now, just return ready
        return jsonify({
            "status": "ready",
            "timestamp": datetime.utcnow().isoformat()
        }), 200
    except Exception as e:
        current_app.logger.error(f"Readiness check failed: {str(e)}")
        return jsonify({
            "status": "not ready",
            "error": str(e)
        }), 503


@main_bp.route('/liveness')
def liveness():
    """Liveness probe for Kubernetes."""
    return jsonify({
        "status": "alive",
        "timestamp": datetime.utcnow().isoformat()
    }), 200


@main_bp.route('/metrics')
def metrics():
    """Basic application metrics endpoint."""
    return jsonify({
        "app_name": current_app.config['APP_NAME'],
        "version": current_app.config['APP_VERSION'],
        "python_version": sys.version,
        "platform": platform.platform(),
        "timestamp": datetime.utcnow().isoformat()
    }), 200


@main_bp.route('/api/user-info')
def user_info():
    """API endpoint to retrieve authenticated user information."""
    try:
        email = request.headers.get(current_app.config['FORWARDED_EMAIL_HEADER'])
        user = request.headers.get(current_app.config['FORWARDED_USER_HEADER'])
        groups = request.headers.get(current_app.config['FORWARDED_GROUPS_HEADER'])

        if not email:
            return jsonify({
                "error": "Not authenticated",
                "authenticated": False
            }), 401

        return jsonify({
            "authenticated": True,
            "email": email,
            "username": user,
            "groups": groups.split(',') if groups else [],
            "timestamp": datetime.utcnow().isoformat()
        }), 200
    except Exception as e:
        current_app.logger.error(f"Error retrieving user info: {str(e)}")
        return jsonify({
            "error": "Failed to retrieve user information",
            "message": str(e)
        }), 500
