# Testing Requirements (AIDD) — IDaaS
> Version: 1.0 | Last Updated: 2026-02-18 | Status: Draft
> Classification: Internal | Author: AIDD System

---

## 1. Introduction

This document defines the testing requirements for the IDaaS platform as part of the
AI-Driven Development (AIDD) pipeline. It covers test strategy, test categories,
test case specifications, automation requirements, and quality gates.

---

## 2. Test Strategy

### 2.1 Test Pyramid

```
              ┌───────────┐
              │   E2E     │  ~10% - Simulated auth flows
              │  Tests    │
           ┌──┴───────────┴──┐
           │  Integration     │  ~20% - Component interaction
           │  Tests           │
        ┌──┴──────────────────┴──┐
        │    Unit Tests           │  ~70% - Function/class level
        │    (pytest)             │
        └─────────────────────────┘
```

### 2.2 Test Environments

| Environment | Purpose | Data |
|-------------|---------|------|
| Local (Docker Compose) | Developer testing | Ephemeral containers |
| CI (GitHub Actions/Jenkins/Tekton) | Automated pipeline testing | Docker Compose CI config |
| Staging (Kubernetes) | Pre-production validation | Anonymized production data |
| Production | Smoke tests post-deployment | Production (read-only tests) |

### 2.3 Quality Gates

All quality gates must pass before deployment to staging or production:

| Gate | Tool | Threshold |
|------|------|-----------|
| Code Linting | Flake8 | Zero errors |
| Static Analysis (SAST) | Bandit | Zero high/critical findings |
| Dependency Scan | Safety | Zero known vulnerabilities |
| Unit Test Pass Rate | pytest | 100% pass |
| Unit Test Coverage | pytest-cov | >= 80% line coverage |
| Container Scan | Trivy | Zero critical CVEs |
| E2E Test Pass Rate | Custom | 100% pass |

---

## 3. Unit Test Requirements

### 3.1 Flask Application Tests

**Location**: `apps/webapp/tests/`

| Test File | Scope | Test Cases |
|-----------|-------|------------|
| `test_app.py` | Application factory | App creation, config loading, extension init |
| `test_routes.py` | Route handlers | Health, readiness, liveness, metrics, index |
| `test_config.py` | Configuration | Dev/test/prod config values, env overrides |

**Required Test Cases**:

```python
# TC-UNIT-001: Application Factory
def test_create_app_returns_flask_instance():
    """Verify create_app() returns a valid Flask application."""
    app = create_app('testing')
    assert isinstance(app, Flask)
    assert app.config['TESTING'] is True

# TC-UNIT-002: Health Endpoint
def test_health_endpoint_returns_200(client):
    """Verify /health returns 200 with healthy status."""
    response = client.get('/health')
    assert response.status_code == 200
    assert response.json['status'] == 'healthy'

# TC-UNIT-003: Readiness Endpoint
def test_readiness_endpoint(client):
    """Verify /readiness returns 200 when dependencies available."""
    response = client.get('/readiness')
    assert response.status_code == 200

# TC-UNIT-004: Liveness Endpoint
def test_liveness_endpoint(client):
    """Verify /liveness returns 200 when process is running."""
    response = client.get('/liveness')
    assert response.status_code == 200

# TC-UNIT-005: Security Headers
def test_security_headers(client):
    """Verify all security headers are present on responses."""
    response = client.get('/health')
    assert 'Strict-Transport-Security' in response.headers
    assert 'Content-Security-Policy' in response.headers
    assert 'X-Frame-Options' in response.headers
    assert response.headers['X-Content-Type-Options'] == 'nosniff'

# TC-UNIT-006: Identity Header Extraction
def test_identity_headers(client):
    """Verify user identity is extracted from forwarded headers."""
    response = client.get('/', headers={
        'X-Forwarded-Email': 'test@example.com',
        'X-Forwarded-User': 'testuser',
        'X-Forwarded-Groups': 'admin,editor'
    })
    assert response.status_code == 200

# TC-UNIT-007: Configuration Environment Selection
def test_production_config():
    """Verify production config has security settings enabled."""
    app = create_app('production')
    assert app.config['DEBUG'] is False
    assert app.config['TESTING'] is False
```

### 3.2 MFA Authenticator Tests

| Test Area | Test Cases |
|-----------|------------|
| TOTP Generation | Correct 6-digit codes per RFC 6238; codes change every 30 seconds |
| QR Parsing | Valid otpauth:// URI parsing; error handling for malformed QR |
| Secure Storage | Secrets stored encrypted; secrets retrievable after app restart |
| Account Management | Add account; remove account; multiple accounts |

---

## 4. Integration Test Requirements

### 4.1 Authentication Flow Tests

| ID | Test Case | Components | Expected Result |
|----|-----------|------------|-----------------|
| TC-INT-001 | OIDC Authorization Code Flow | OAuth2 Proxy + Keycloak | User authenticated, session created |
| TC-INT-002 | Token Exchange | OAuth2 Proxy + Keycloak | Valid access/ID/refresh tokens returned |
| TC-INT-003 | Session Persistence | OAuth2 Proxy + DragonflyDB | Session stored and retrievable |
| TC-INT-004 | Identity Header Forwarding | OAuth2 Proxy + Flask | X-Forwarded headers present in request |
| TC-INT-005 | Client Credentials Flow | API Client + Keycloak | Service account token issued |
| TC-INT-006 | Token Refresh | OAuth2 Proxy + Keycloak | New access token issued from refresh token |
| TC-INT-007 | Session Expiry | OAuth2 Proxy + DragonflyDB | Expired session triggers re-authentication |

### 4.2 Database Integration Tests

| ID | Test Case | Components | Expected Result |
|----|-----------|------------|-----------------|
| TC-INT-010 | Keycloak-YugabyteDB Connection | Keycloak + YugabyteDB | Keycloak starts with DB backend |
| TC-INT-011 | User Persistence | Keycloak + YugabyteDB | Created user retrievable after restart |
| TC-INT-012 | Session Storage | OAuth2 Proxy + DragonflyDB | Redis SET/GET operations succeed |
| TC-INT-013 | Cache Operations | Flask + DragonflyDB | Cache write/read/expiry works correctly |

---

## 5. End-to-End Test Requirements

### 5.1 E2E Test Scenarios

**Location**: `tests/e2e_test.py`

| ID | Scenario | Steps | Expected Result |
|----|----------|-------|-----------------|
| TC-E2E-001 | Complete Login Flow | Navigate to app > Redirect to login > Enter credentials > MFA > Access app | User sees authenticated page |
| TC-E2E-002 | SSO Across Applications | Login to app A > Navigate to app B | App B accessible without re-auth |
| TC-E2E-003 | Logout Flow | Click logout > Attempt to access protected page | Redirected to login page |
| TC-E2E-004 | Password Reset | Click forgot password > Receive email > Reset > Login with new password | Login succeeds with new password |
| TC-E2E-005 | Failed Login | Enter wrong password 3 times | Error messages displayed |
| TC-E2E-006 | Account Lockout | Enter wrong password 5 times | Account locked, cannot login |
| TC-E2E-007 | Session Timeout | Login > Wait for session idle timeout | Re-authentication required |

### 5.2 Simulated Auth Header Testing

The current E2E test suite (`tests/e2e_test.py`) uses simulated authentication headers
to test the application layer without requiring a running Keycloak instance:

```python
# Simulated auth header test
def test_authenticated_access(client):
    response = client.get('/', headers={
        'X-Forwarded-Email': 'e2e-test@example.com',
        'X-Forwarded-User': 'e2e-testuser',
        'X-Forwarded-Groups': 'admin'
    })
    assert response.status_code == 200
```

---

## 6. Security Test Requirements

### 6.1 Static Analysis (SAST)

| Tool | Target | Configuration |
|------|--------|---------------|
| Bandit | Python source code | All confidence levels; exclude tests/ |
| Flake8 | Python source code | Default rules + security plugins |

### 6.2 Dependency Scanning

| Tool | Target | Configuration |
|------|--------|---------------|
| Safety | Python requirements.txt | All vulnerability databases |
| npm audit | Flutter/Dart dependencies | (if applicable) |

### 6.3 Container Scanning

| Tool | Target | Configuration |
|------|--------|---------------|
| Trivy | Docker images | Critical + High severity |
| Trivy | Kubernetes manifests | Misconfigurations |

### 6.4 Penetration Testing Checklist

| Category | Test | OWASP Reference |
|----------|------|-----------------|
| Authentication | Brute-force protection validation | A07:2021 |
| Authentication | Session fixation resistance | A07:2021 |
| Authentication | Token replay protection | A07:2021 |
| Authorization | Privilege escalation attempts | A01:2021 |
| Authorization | IDOR (Insecure Direct Object Reference) | A01:2021 |
| Injection | SQL injection on all inputs | A03:2021 |
| Injection | XSS on all rendered outputs | A03:2021 |
| Configuration | Security header validation | A05:2021 |
| Configuration | TLS configuration strength | A02:2021 |
| Configuration | Default credential detection | A07:2021 |
| Cryptography | JWT signature bypass attempts | A02:2021 |
| Cryptography | Weak algorithm detection | A02:2021 |

---

## 7. Performance Test Requirements

### 7.1 Load Testing Scenarios

| Scenario | Tool | Configuration | Target |
|----------|------|---------------|--------|
| Authentication throughput | k6 / Locust | 500 virtual users, 10-minute ramp | 500 auth/sec sustained |
| Concurrent sessions | k6 / Locust | 10,000 virtual users, steady state | All sessions active |
| Token endpoint latency | k6 / Locust | 100 VU, 5-minute run | P95 < 200ms |
| HPA scaling validation | k6 / Locust | Ramp to trigger scale-up | Pods scale to 10 within 3 minutes |

### 7.2 Soak Testing

| Scenario | Duration | Configuration |
|----------|----------|---------------|
| 24-hour stability | 24 hours | 200 VU steady state, monitoring for memory leaks, connection exhaustion |

---

## 8. Test Automation Requirements

### 8.1 CI Pipeline Integration

All tests must execute automatically in all three CI pipelines:

| Pipeline | Unit Tests | Integration Tests | E2E Tests | Security Scans |
|----------|-----------|-------------------|-----------|----------------|
| GitHub Actions | pytest stage | Docker Compose stage | E2E stage | Bandit + Safety + Trivy |
| Jenkins | Unit Tests stage | Integration stage | E2E stage | SAST + Dep Scan + Container Scan |
| Tekton | python-test task | integration-test task | smoke-test task | security-scan task |

### 8.2 Test Reporting

- JUnit XML output for CI integration
- Coverage HTML reports archived as build artifacts
- Security scan reports in SARIF format for GitHub integration
- Test execution time tracking for performance regression detection

---

## 9. Test Data Management

| Data Type | Strategy | Lifecycle |
|-----------|----------|-----------|
| Test users | Created in test setup, deleted in teardown | Per test run |
| Test realms | Dedicated `test-realm` in CI environment | Per pipeline run |
| Test clients | Registered as part of test fixtures | Per test run |
| Credentials | Generated randomly; never hardcoded | Ephemeral |

---

*Document generated by the AIDD pipeline. Testing requirements aligned with CI/CD pipeline configurations.*
