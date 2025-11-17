# Multi-stage Dockerfile for Keycloak with security best practices
# Stage 1: Base image with security updates
FROM quay.io/keycloak/keycloak:23.0.0 as builder

# Set environment variables
ENV KC_DB=postgres
ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=true

# Build Keycloak with production optimizations
WORKDIR /opt/keycloak
RUN /opt/keycloak/bin/kc.sh build

# Stage 2: Production image
FROM quay.io/keycloak/keycloak:23.0.0

# Copy built artifacts from builder
COPY --from=builder /opt/keycloak/ /opt/keycloak/

# Create non-root user (keycloak image already has this, but being explicit)
USER 1000

# Set working directory
WORKDIR /opt/keycloak

# Environment variables for production
ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=true
ENV KC_HTTP_ENABLED=false
ENV KC_HOSTNAME_STRICT=true
ENV KC_HOSTNAME_STRICT_HTTPS=true
ENV KC_PROXY=edge

# The following should be set via environment variables at runtime:
# KC_DB_URL - Database JDBC URL
# KC_DB_USERNAME - Database username
# KC_DB_PASSWORD - Database password
# KC_HOSTNAME - Keycloak hostname
# KEYCLOAK_ADMIN - Admin username
# KEYCLOAK_ADMIN_PASSWORD - Admin password

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl --fail http://localhost:8080/health/ready || exit 1

# Expose ports
EXPOSE 8080 8443

# Use the optimized start command
ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
CMD ["start", "--optimized"]
