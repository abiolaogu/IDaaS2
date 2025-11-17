# Multi-stage Dockerfile for Flask webapp with security best practices
# Stage 1: Build stage
FROM python:3.11-slim as builder

# Set build arguments
ARG APP_VERSION=1.0.0
ARG BUILD_DATE
ARG VCS_REF

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /build

# Copy requirements file
COPY requirements.txt .

# Install Python dependencies
RUN pip install --user --no-warn-script-location -r requirements.txt

# Stage 2: Runtime stage
FROM python:3.11-slim

# Add metadata labels
LABEL maintainer="IDaaS Platform Team" \
      org.opencontainers.image.title="IDaaS Platform Web Application" \
      org.opencontainers.image.description="Identity-as-a-Service Platform Flask Application" \
      org.opencontainers.image.version="${APP_VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${VCS_REF}"

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    FLASK_ENV=production \
    PATH=/home/appuser/.local/bin:$PATH

# Create non-root user
RUN groupadd -r appuser && \
    useradd -r -g appuser -u 1000 -m -s /sbin/nologin appuser

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Set working directory
WORKDIR /app

# Copy Python dependencies from builder
COPY --from=builder --chown=appuser:appuser /root/.local /home/appuser/.local

# Copy application code
COPY --chown=appuser:appuser . .

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl --fail http://localhost:8080/health || exit 1

# Use gunicorn for production
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "4", "--threads", "2", "--timeout", "60", "--access-logfile", "-", "--error-logfile", "-", "--log-level", "info", "app:create_app()"]
