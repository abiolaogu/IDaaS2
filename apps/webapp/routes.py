"""Application routes and views."""
from flask import Blueprint, request, current_app
from datetime import datetime
import platform
import sys
import orjson
from flask import Response

# Create blueprint for main routes
main_bp = Blueprint('main', __name__)


def json_response(data, status=200):
    """Create a JSON response using orjson."""
    return Response(
        orjson.dumps(data),
        status=status,
        mimetype='application/json'
    )


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
            return json_response(response_data), 200
        else:
            current_app.logger.debug("Unauthenticated request")
            return json_response({
                "message": "Hello, stranger! You are not authenticated.",
                "authenticated": False
            }), 200
    except Exception as e:
        current_app.logger.error(f"Error processing request: {str(e)}")
        return json_response({
            "error": "Failed to process request",
            "message": str(e)
        }, status=500)


@main_bp.route('/health')
def health():
    """Health check endpoint for monitoring and load balancers."""
    return json_response({
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
        return json_response({
            "status": "ready",
            "timestamp": datetime.utcnow().isoformat()
        }), 200
    except Exception as e:
        current_app.logger.error(f"Readiness check failed: {str(e)}")
        return json_response({
            "status": "not ready",
            "error": str(e)
        }, status=503)


@main_bp.route('/liveness')
def liveness():
    """Liveness probe for Kubernetes."""
    return json_response({
        "status": "alive",
        "timestamp": datetime.utcnow().isoformat()
    }), 200


@main_bp.route('/metrics')
def metrics():
    """Basic application metrics endpoint."""
    return json_response({
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
            return json_response({
                "error": "Not authenticated",
                "authenticated": False
            }, status=401)

        return json_response({
            "authenticated": True,
            "email": email,
            "username": user,
            "groups": groups.split(',') if groups else [],
            "timestamp": datetime.utcnow().isoformat()
        }), 200
    except Exception as e:
        current_app.logger.error(f"Error retrieving user info: {str(e)}")
        return json_response({
            "error": "Failed to retrieve user information",
            "message": str(e)
        }, status=500)
