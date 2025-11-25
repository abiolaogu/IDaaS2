# CI/CD Configuration

This document explains the CI/CD pipeline configuration for the IDaaS platform.

## Overview

The CI/CD pipeline uses GitHub Actions to automatically test, scan, and validate code changes. It consists of 5 main jobs:

1. **Test Flask Web Application** - Unit tests with 95% coverage
2. **Security Scanning** - Bandit security scans and Flake8 linting
3. **Build Docker Images** - Build all container images
4. **End-to-End Tests** - Integration tests with running services
5. **Quality Gate** - Final validation that all checks passed

## Architecture

### DBaaS vs Local Databases

The platform supports two deployment models:

**Production (DBaaS)**:
- Uses external managed databases (YugabyteDB and DragonflyDB DBaaS)
- Configured via `.env` with connection strings
- See `DBAAS_DEPLOYMENT.md`

**CI/CD (Local)**:
- Uses local database containers for testing
- Automatically provisioned during CI runs
- Configured via `docker-compose.ci.yml`

### Why Separate CI Configuration?

The main `docker-compose.yml` is designed for production with DBaaS and requires external database URLs. For CI/CD testing, we need self-contained environments without external dependencies.

**Solution**: `docker-compose.ci.yml` overlay file that:
- Adds local YugabyteDB container for testing
- Adds local DragonflyDB container for testing
- Overrides environment variables to use local databases
- Ensures tests run in isolation

## Files

### `.github/workflows/ci.yml`

Main CI/CD workflow file with 5 jobs:

```yaml
jobs:
  test-webapp:        # Run unit tests
  security-scan:      # Security and code quality
  docker-build:       # Build container images
  e2e-tests:          # End-to-end integration tests
  quality-gate:       # Final validation
```

### `docker-compose.ci.yml`

CI-specific Docker Compose overlay that adds local databases:

```yaml
services:
  yugabytedb:       # Local YugabyteDB for CI
  dragonflydb:      # Local DragonflyDB for CI
  keycloak:         # Override to use local DB
  webapp:           # Override to use local DB
  oauth2-proxy:     # Override to use local DB
```

**Usage in CI**:
```bash
docker-compose -f docker-compose.yml -f docker-compose.ci.yml up -d
```

This combines:
- `docker-compose.yml` - Base application services
- `docker-compose.ci.yml` - Local databases + overrides

## Running Tests Locally

### Unit Tests

```bash
cd apps/webapp
python -m venv venv
source venv/bin/activate  # or: venv\Scripts\activate on Windows
pip install -r requirements.txt
pytest tests/ -v --cov=. --cov-report=html
```

View coverage: `open htmlcov/index.html`

### Security Scans

```bash
cd apps/webapp
pip install bandit flake8

# Run Bandit security scan
bandit -r . --exclude ./venv,./tests

# Run Flake8 linting
flake8 . --exclude=venv,tests --max-line-length=120
```

### E2E Tests

```bash
# Start services with CI configuration
docker-compose -f docker-compose.yml -f docker-compose.ci.yml up -d

# Wait for services to be ready
sleep 30

# Run E2E tests
pip install pytest requests
E2E_BASE_URL=http://localhost:8081 pytest tests/e2e_test.py -v

# Clean up
docker-compose -f docker-compose.yml -f docker-compose.ci.yml down -v
```

### Build Docker Images

```bash
# Build webapp
docker build -t idaas-webapp:test apps/webapp

# Build Keycloak
docker build -t idaas-keycloak:test apps/keycloak

# Build OAuth2 Proxy
docker build -t idaas-oauth2-proxy:test apps/oauth2-proxy
```

## Workflow Triggers

The pipeline runs on:

**Push events**:
- `main` branch
- `develop` branch
- Any `claude/**` branch

**Pull request events**:
- Targeting `main` branch
- Targeting `develop` branch

## Job Dependencies

```
test-webapp ─────┐
                 ├──► docker-build ──► e2e-tests ──► quality-gate
security-scan ───┘
```

- `docker-build` waits for both `test-webapp` and `security-scan`
- `e2e-tests` waits for `docker-build`
- `quality-gate` waits for all previous jobs

If any job fails, subsequent dependent jobs are skipped.

## Environment Variables

### CI Environment

Set automatically by GitHub Actions:

```yaml
PYTHON_VERSION: '3.11'
NODE_VERSION: '18'
E2E_BASE_URL: http://localhost:8081
```

### Test Credentials (CI only)

Hardcoded in `docker-compose.ci.yml`:

```yaml
YUGABYTE_USER: keycloak
YUGABYTE_PASSWORD: ci_test_password
DRAGONFLY_PASSWORD: ci_test_password
SECRET_KEY: ci-test-secret-key-not-for-production
```

⚠️ **Note**: These credentials are only for CI testing and should never be used in production!

## Troubleshooting

### Tests Failing in CI but Pass Locally

**Common causes**:
1. **Missing environment variables** - Check `.github/workflows/ci.yml`
2. **Different Python version** - CI uses Python 3.11
3. **Timing issues** - Services may need more startup time in CI

**Solution**: Increase sleep time or add retry logic:
```yaml
- name: Wait for services
  run: |
    timeout 120 bash -c 'until curl -f http://localhost:8081/health; do sleep 2; done'
```

### Docker Build Failing

**Common causes**:
1. **Missing Dockerfile** - Ensure Dockerfiles exist
2. **Build context issues** - Check `context` in workflow
3. **Dependency errors** - Check requirements.txt

**Solution**: Test build locally:
```bash
docker build -t test apps/webapp
```

### E2E Tests Timing Out

**Common causes**:
1. **Services not ready** - Database initialization takes time
2. **Network issues** - Containers can't communicate
3. **Resource constraints** - CI environment is resource-limited

**Solutions**:
- Increase timeout: `timeout 180` instead of `timeout 120`
- Add health checks: Use `depends_on` with `condition: service_healthy`
- Check logs: `docker-compose logs` in "Show logs on failure" step

### Security Scan Failures

**Bandit issues**:
- Review security warnings carefully
- Add `# nosec` comment for false positives (with justification)
- Fix actual security issues

**Flake8 issues**:
- Fix code style violations
- Adjust max line length if needed: `--max-line-length=120`

## Quality Standards

### Test Coverage

- **Minimum**: 80% code coverage
- **Target**: 95% code coverage
- **Current**: 95% ✅

### Security

- **No high-severity issues** from Bandit
- **No critical vulnerabilities** in dependencies
- **All Flake8 checks passing**

### Performance

- Health endpoint: < 1 second response time
- Main endpoint: < 2 seconds response time
- E2E test suite: < 5 minutes total

## Continuous Improvement

### Adding New Tests

1. Add unit tests to `apps/webapp/tests/`
2. Add E2E tests to `tests/e2e_test.py`
3. Ensure tests are isolated (no external dependencies)
4. Run locally before pushing

### Updating Dependencies

1. Update `requirements.txt`
2. Test locally: `pip install -r requirements.txt && pytest`
3. Push and verify CI passes
4. Update `CHANGELOG.md`

### Modifying CI Pipeline

1. Edit `.github/workflows/ci.yml`
2. Test changes in a feature branch
3. Verify all jobs complete successfully
4. Merge to main

## Best Practices

✅ **DO**:
- Keep tests fast (< 5 min total)
- Test in isolation (no external services)
- Use meaningful test names
- Add comments for complex logic
- Keep coverage above 80%

❌ **DON'T**:
- Commit secrets or credentials
- Skip failing tests
- Disable security checks
- Use production databases in CI
- Merge with failing checks

## Related Documentation

- `DBAAS_DEPLOYMENT.md` - Production DBaaS deployment
- `HA_DEPLOYMENT.md` - High availability setup
- `DEPLOYMENT.md` - General deployment guide
- `TEST_RESULTS.md` - Test coverage reports

## Support

For CI/CD issues:
1. Check GitHub Actions logs
2. Run tests locally to reproduce
3. Review this documentation
4. Open an issue with logs and error messages
