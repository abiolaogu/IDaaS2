# IDaaS Platform - Deployment Guide

This guide provides comprehensive instructions for deploying the IDaaS Platform in various environments.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Quick Start](#quick-start)
3. [Development Deployment](#development-deployment)
4. [Production Deployment](#production-deployment)
5. [Environment Variables](#environment-variables)
6. [CI/CD Pipeline](#cicd-pipeline)
7. [Monitoring and Maintenance](#monitoring-and-maintenance)
8. [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Software

- **Docker**: Version 20.10 or higher
- **Docker Compose**: Version 2.0 or higher
- **Git**: For cloning the repository
- **Python 3.11**: For running tests locally (optional)

### System Requirements

**Minimum:**
- 4 GB RAM
- 2 CPU cores
- 20 GB disk space

**Recommended for Production:**
- 8 GB RAM
- 4 CPU cores
- 50 GB disk space

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/IDaaS2.git
cd IDaaS2
```

### 2. Using the Deployment Script

The easiest way to deploy is using the provided deployment script:

```bash
# Deploy in development mode
cp .env.example .env
# Edit .env and set DEPLOYMENT_MODE=development
./deploy.sh deploy

# Check status
./deploy.sh status

# View logs
./deploy.sh logs

# Stop services
./deploy.sh stop
```

## Development Deployment

### Step 1: Configure Environment

```bash
cp .env.example .env
```

Edit `.env` and set:
```bash
DEPLOYMENT_MODE=development
```

### Step 2: Deploy

Using the deployment script:
```bash
./deploy.sh deploy
```

Or manually:
```bash
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d
```

### Step 3: Access Services

- **Web Application**: http://localhost:8081
- **OAuth2 Proxy**: http://localhost:4180
- **Keycloak Admin**: http://localhost:8080
  - Username: `admin`
  - Password: `admin` (development only!)
- **PostgreSQL**: localhost:5432

### Step 4: Testing

The application should be running. Test it:
```bash
curl http://localhost:8081/health
```

Expected response:
```json
{
  "status": "healthy",
  "service": "IDaaS Platform",
  "version": "1.0.0",
  "timestamp": "2025-11-24T..."
}
```

## Production Deployment

### Step 1: Generate Secrets

Generate strong, random secrets for production:

```bash
# Generate SECRET_KEY
python3 -c "import secrets; print(secrets.token_hex(32))"

# Generate OAUTH2_COOKIE_SECRET (exactly 32 bytes)
python3 -c "import secrets; print(secrets.token_urlsafe(32)[:32])"

# Generate OAUTH2_CLIENT_SECRET
python3 -c "import secrets; print(secrets.token_urlsafe(32))"

# Generate passwords
python3 -c "import secrets; print(secrets.token_urlsafe(24))"
```

### Step 2: Configure Environment

```bash
cp .env.example .env
```

Edit `.env` and set all required variables:

```bash
DEPLOYMENT_MODE=production

# Database
POSTGRES_DB=keycloak_prod
POSTGRES_USER=keycloak_prod
POSTGRES_PASSWORD=<strong-password-here>

# Keycloak
KEYCLOAK_HOSTNAME=auth.yourdomain.com
KEYCLOAK_ADMIN=admin
KEYCLOAK_ADMIN_PASSWORD=<strong-admin-password>

# Web Application
SECRET_KEY=<generated-secret-key>
APP_HOSTNAME=app.yourdomain.com

# OAuth2 Proxy
OAUTH2_CLIENT_ID=webapp-client
OAUTH2_CLIENT_SECRET=<generated-client-secret>
OAUTH2_COOKIE_SECRET=<exactly-32-bytes>
OAUTH2_EMAIL_DOMAINS=yourdomain.com
```

### Step 3: Deploy

Using the deployment script:
```bash
./deploy.sh deploy
```

Or manually:
```bash
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

### Step 4: Verify Deployment

```bash
# Check all services are running
docker-compose ps

# Check webapp health
curl https://app.yourdomain.com/health

# View logs
docker-compose logs -f
```

## Environment Variables

### Required for Production

| Variable | Description | Example |
|----------|-------------|---------|
| `POSTGRES_PASSWORD` | PostgreSQL database password | Strong random password |
| `KEYCLOAK_ADMIN_PASSWORD` | Keycloak admin password | Strong random password |
| `SECRET_KEY` | Flask secret key (64 chars) | Generated with secrets.token_hex(32) |
| `OAUTH2_CLIENT_SECRET` | OAuth2 client secret | Generated random string |
| `OAUTH2_COOKIE_SECRET` | OAuth2 cookie secret (32 bytes) | Exactly 32-byte string |
| `KEYCLOAK_HOSTNAME` | Keycloak domain | auth.example.com |
| `APP_HOSTNAME` | Application domain | app.example.com |

### Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `LOG_LEVEL` | Logging level | INFO |
| `OAUTH2_EMAIL_DOMAINS` | Allowed email domains | * (all) |
| `APP_VERSION` | Application version | 1.0.0 |

## CI/CD Pipeline

The project includes a comprehensive GitHub Actions CI/CD pipeline that runs automatically on:
- Push to `main`, `develop`, or `claude/**` branches
- Pull requests to `main` or `develop`

### Pipeline Stages

1. **Test Web Application**
   - Runs unit tests with pytest
   - Generates coverage reports (95%+ coverage)
   - Uploads coverage to Codecov

2. **Security Scanning**
   - Runs Bandit for security issues
   - Runs Flake8 for code quality
   - Generates security reports

3. **Docker Build**
   - Builds all Docker images
   - Uses build cache for faster builds
   - Validates Dockerfiles

4. **End-to-End Tests**
   - Starts full stack with docker-compose
   - Runs E2E test suite
   - Tests authentication flows

5. **Quality Gate**
   - Ensures all checks pass
   - Provides deployment approval

### Running CI/CD Locally

```bash
# Run tests
./deploy.sh test

# Or manually
cd apps/webapp
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
pytest tests/ -v --cov
```

## Monitoring and Maintenance

### Health Checks

The application provides several health check endpoints:

```bash
# Overall health
curl http://localhost:8081/health

# Readiness probe
curl http://localhost:8081/readiness

# Liveness probe
curl http://localhost:8081/liveness

# Metrics
curl http://localhost:8081/metrics
```

### Viewing Logs

```bash
# All services
./deploy.sh logs

# Specific service
./deploy.sh logs webapp
docker-compose logs -f webapp

# Last 100 lines
docker-compose logs --tail=100 webapp
```

### Backup Database

```bash
# Backup PostgreSQL
docker exec idaas-postgres pg_dump -U keycloak_prod keycloak_prod > backup_$(date +%Y%m%d).sql

# Restore
docker exec -i idaas-postgres psql -U keycloak_prod keycloak_prod < backup_20251124.sql
```

### Updating the Application

```bash
# Pull latest changes
git pull origin main

# Rebuild and restart
docker-compose up -d --build

# Or use deployment script
./deploy.sh deploy
```

## Troubleshooting

### Common Issues

#### 1. Flask Application Cannot Be Located

**Error**: `Could not locate a Flask application`

**Solution**:
```bash
# Verify FLASK_APP is set in docker-compose
grep FLASK_APP docker-compose.yml
# Should show: FLASK_APP: app:create_app()
```

#### 2. OAuth2 Proxy Cookie Secret Error

**Error**: `cookie_secret must be 16, 24, or 32 bytes`

**Solution**:
```bash
# Generate exactly 32-byte secret
python3 -c "import secrets; print(secrets.token_urlsafe(32)[:32])"
# Update OAUTH2_COOKIE_SECRET in .env
```

#### 3. Keycloak Database Authentication Failed

**Error**: `password authentication failed for user "keycloak_dev"`

**Solution**:
```bash
# Remove old database volume
docker-compose down -v
# Start fresh with correct credentials
docker-compose up -d
```

#### 4. Services Not Starting

**Check logs**:
```bash
./deploy.sh logs

# Check specific service
docker logs idaas-webapp
docker logs idaas-keycloak
docker logs idaas-postgres
```

**Check service status**:
```bash
docker-compose ps
./deploy.sh status
```

#### 5. Port Conflicts

**Error**: `port is already allocated`

**Solution**:
```bash
# Find process using port
sudo lsof -i :8080

# Stop conflicting service or change port in docker-compose.yml
```

### Getting Help

1. Check the logs: `./deploy.sh logs`
2. Verify all environment variables are set: `docker-compose config`
3. Check Docker status: `docker ps -a`
4. Review GitHub Actions for CI/CD issues
5. Open an issue on GitHub with logs and configuration

## Security Considerations

### Production Checklist

- [ ] All secrets generated with cryptographically secure random generator
- [ ] No default passwords in use
- [ ] HTTPS enabled for all external endpoints
- [ ] Firewall configured to restrict access
- [ ] Regular backups configured
- [ ] Log monitoring set up
- [ ] Security updates applied
- [ ] Access logs reviewed regularly

### Security Best Practices

1. **Never commit secrets** to version control
2. **Use strong passwords** (24+ characters)
3. **Enable HTTPS** in production
4. **Restrict email domains** for OAuth2
5. **Regular security scans** with CI/CD pipeline
6. **Keep dependencies updated**
7. **Monitor logs** for suspicious activity
8. **Backup database regularly**

## Performance Optimization

### Production Configuration

The production docker-compose includes:

- **Resource limits**: Prevent service overconsumption
- **Health checks**: Automatic restart on failure
- **Multiple webapp replicas**: Load distribution
- **Gunicorn workers**: Optimal for CPU cores
- **Connection pooling**: Database optimization

### Monitoring

Use the `/metrics` endpoint for application metrics:

```bash
curl http://localhost:8081/metrics
```

### Scaling

To scale the web application:

```bash
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d --scale webapp=4
```

## Support

For issues, questions, or contributions:

- GitHub Issues: https://github.com/yourusername/IDaaS2/issues
- Documentation: https://github.com/yourusername/IDaaS2/wiki
- Email: support@example.com
