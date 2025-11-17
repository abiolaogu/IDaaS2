# Dockerfile for OAuth2 Proxy with security best practices
# Using official OAuth2 Proxy image with minimal modifications
FROM quay.io/oauth2-proxy/oauth2-proxy:v7.5.1-alpine

# Add metadata labels
LABEL maintainer="IDaaS Platform Team" \
      org.opencontainers.image.title="OAuth2 Proxy" \
      org.opencontainers.image.description="OAuth2 Proxy for IDaaS Platform" \
      org.opencontainers.image.version="7.5.1"

# OAuth2 Proxy runs as non-root user by default (UID 2000)
# No additional user creation needed

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:4180/ping || exit 1

# Expose ports
# 4180 - HTTP port
# 4443 - HTTPS port (if configured)
EXPOSE 4180 4443

# The default entrypoint is already set by the base image
# Configuration should be provided via:
# - Environment variables
# - Config file mounted at /etc/oauth2-proxy/oauth2-proxy.cfg
# - Command-line arguments
