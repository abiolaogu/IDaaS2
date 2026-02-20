# Workflows Document — IDaaS
> Version: 1.0 | Last Updated: 2026-02-18 | Status: Draft
> Classification: Internal | Author: AIDD System

---

## 1. Introduction

This document defines the key operational and identity workflows within the IDaaS platform,
covering authentication flows, user lifecycle management, administrative processes, and
CI/CD pipeline workflows.

---

## 2. Authentication Workflows

### 2.1 OIDC Authorization Code Flow with PKCE

```
┌──────┐     ┌────────────┐     ┌──────────────┐     ┌──────────┐
│Client│     │OAuth2 Proxy │     │   Keycloak   │     │  Flask   │
└──┬───┘     └─────┬───────┘     └──────┬───────┘     └────┬─────┘
   │  GET /app     │                     │                   │
   │──────────────▶│                     │                   │
   │               │  No session found   │                   │
   │  302 Redirect │  to /authorize      │                   │
   │◀──────────────│                     │                   │
   │  GET /authorize?response_type=code  │                   │
   │  &client_id=...&code_challenge=...  │                   │
   │────────────────────────────────────▶│                   │
   │               │    Login page       │                   │
   │◀────────────────────────────────────│                   │
   │  POST credentials + MFA            │                   │
   │────────────────────────────────────▶│                   │
   │               │    302 + auth code  │                   │
   │◀────────────────────────────────────│                   │
   │  Redirect to OAuth2 Proxy callback  │                   │
   │──────────────▶│                     │                   │
   │               │ POST /token         │                   │
   │               │ (code + verifier)   │                   │
   │               │────────────────────▶│                   │
   │               │ ID + Access tokens  │                   │
   │               │◀────────────────────│                   │
   │               │ Set session cookie   │                   │
   │               │ Store in DragonflyDB │                   │
   │               │ Proxy to upstream    │                   │
   │               │─────────────────────────────────────────▶│
   │  200 + page   │  X-Forwarded-User/Email/Groups          │
   │◀──────────────────────────────────────────────────────────│
```

### 2.2 TOTP MFA Enrollment Flow

1. User logs into Keycloak with username/password
2. Keycloak authentication flow detects MFA not enrolled
3. Keycloak presents QR code containing TOTP secret URI
4. User scans QR code with IDaaS MFA Authenticator (Flutter app)
5. Flutter app stores TOTP secret in platform secure storage
6. User enters 6-digit TOTP code from authenticator app
7. Keycloak validates code and marks TOTP as enrolled
8. Subsequent logins require TOTP as second factor

### 2.3 SAML 2.0 SP-Initiated SSO (Planned)

1. User accesses SAML-protected service provider application
2. SP generates SAML AuthnRequest
3. SP redirects user to Keycloak SAML IdP endpoint
4. Keycloak authenticates user (or uses existing SSO session)
5. Keycloak generates SAML Response with signed Assertion
6. User is redirected back to SP with SAML Response (POST binding)
7. SP validates signature, extracts attributes, creates local session

### 2.4 OAuth 2.0 Client Credentials Flow (Machine-to-Machine)

1. Service client sends POST to Keycloak `/token` endpoint
2. Request includes `grant_type=client_credentials`, `client_id`, `client_secret`
3. Keycloak validates client credentials
4. Keycloak issues access token (JWT) with service account roles
5. Client uses access token as Bearer header for API calls
6. Resource server validates JWT signature, expiry, and scopes

---

## 3. User Lifecycle Workflows

### 3.1 Self-Service Registration

1. User navigates to registration page
2. User fills registration form (email, name, password)
3. Keycloak sends email verification link
4. User clicks verification link
5. Keycloak activates account
6. User can now authenticate via SSO

### 3.2 SCIM Inbound Provisioning (Planned)

```
┌──────────┐     ┌──────────────┐     ┌──────────┐     ┌──────────┐
│ HR System│     │  SCIM Service │     │ Keycloak │     │ SaaS App │
└────┬─────┘     └──────┬────────┘     └────┬─────┘     └────┬─────┘
     │ POST /scim/v2/Users                  │                  │
     │──────────────────▶│                  │                  │
     │                   │ Create user      │                  │
     │                   │─────────────────▶│                  │
     │                   │ User created     │                  │
     │                   │◀─────────────────│                  │
     │                   │ Outbound provision│                  │
     │                   │──────────────────────────────────────▶
     │  201 Created      │                  │                  │
     │◀──────────────────│                  │                  │
```

### 3.3 Password Reset Flow

1. User clicks "Forgot Password" on login page
2. Keycloak sends password reset email with time-limited token
3. User clicks link within 15-minute window
4. User enters new password (complexity validation enforced)
5. Keycloak updates credential, invalidates existing sessions
6. User is redirected to login page for fresh authentication

### 3.4 Account Deprovisioning

1. HR system triggers SCIM DELETE or manager initiates deactivation
2. SCIM service marks user as disabled in Keycloak
3. All active sessions for user are terminated immediately
4. Refresh tokens are revoked
5. Outbound SCIM deprovisioning disables accounts in downstream SaaS apps
6. After 90-day grace period, user data is permanently purged

---

## 4. Administrative Workflows

### 4.1 Tenant Onboarding

1. Tenant admin submits onboarding request
2. Platform admin creates new Keycloak realm for tenant
3. Configure realm settings: login theme, email provider, session timeouts
4. Register OAuth2/OIDC clients for tenant applications
5. Configure identity federation (external IdPs if applicable)
6. Set up RBAC roles and default group mappings
7. Create initial admin user with realm-admin privileges
8. Validate SSO login flow end-to-end
9. Hand off credentials and documentation to tenant admin

### 4.2 Client Application Registration

1. Developer accesses admin console or self-service portal
2. Developer provides: application name, type (web/SPA/native/service), redirect URIs
3. System generates client_id and client_secret (for confidential clients)
4. Developer configures OAuth2/OIDC scopes (openid, email, profile, custom)
5. System assigns default roles and policies to the client
6. Developer downloads client configuration or OIDC discovery metadata
7. Developer integrates SDK and tests login flow

### 4.3 Role and Permission Management

1. Admin navigates to realm role management
2. Admin creates realm-level or client-level roles
3. Admin optionally creates composite roles (role hierarchies)
4. Admin creates groups and assigns role mappings to groups
5. Admin assigns users to groups (inheriting group roles)
6. Role changes take effect on next token refresh (within 5 minutes)

---

## 5. CI/CD Pipeline Workflows

### 5.1 GitHub Actions CI Pipeline

```
┌───────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│ Git Push  │───▶│  Lint &  │───▶│ Security │───▶│  Unit    │
│ / PR Open │    │  Format  │    │  Scan    │    │  Tests   │
└───────────┘    └──────────┘    └──────────┘    └──────────┘
                                                       │
                 ┌──────────┐    ┌──────────┐    ┌─────▼────┐
                 │  Deploy  │◀───│  E2E     │◀───│  Docker  │
                 │  Stage   │    │  Tests   │    │  Build   │
                 └──────────┘    └──────────┘    └──────────┘
```

**Stages**:
1. **Lint & Format**: Flake8 Python linting, YAML validation
2. **Security Scan**: Bandit (SAST), Safety (dependency vulnerabilities), Trivy (container)
3. **Unit Tests**: pytest with coverage (minimum 80% threshold)
4. **Docker Build**: Multi-stage build, push to GHCR
5. **E2E Tests**: Simulated authentication flow testing
6. **Deploy**: kubectl apply to staging, manual approval for production

### 5.2 Jenkins Pipeline

10-stage pipeline with parallel execution:
1. Checkout source code
2. Python lint (Flake8) || Helm lint (parallel)
3. Dependency scan (Safety)
4. SAST scan (Bandit)
5. Unit tests (pytest)
6. Build Docker images (webapp || keycloak || oauth2-proxy parallel)
7. Container scan (Trivy)
8. Integration tests
9. Tag and push images
10. Deploy (manual approval gate for production)

### 5.3 Tekton Kubernetes-Native Pipeline

8 reusable tasks executed in Kubernetes:
1. `git-clone` - Fetch source from repository
2. `python-lint` - Flake8 code quality
3. `python-test` - pytest execution
4. `security-scan` - Trivy + Bandit
5. `build-docker-image` - Kaniko in-cluster build
6. `push-image` - Push to container registry
7. `deploy-staging` - kubectl apply
8. `smoke-test` - Post-deployment health verification

---

## 6. Incident Response Workflow

1. **Detection**: Monitoring alert fires (anomalous login patterns, failed MFA spike)
2. **Triage**: On-call engineer assesses severity (P1-P4)
3. **Containment**: Disable compromised accounts, revoke sessions, enable IP blocking
4. **Investigation**: Query audit event logs, correlate with SIEM
5. **Remediation**: Patch vulnerability, rotate credentials, update policies
6. **Recovery**: Re-enable services, validate authentication flows
7. **Post-Mortem**: Document root cause, update runbooks, implement preventive controls

---

## 7. Backup and Recovery Workflow

1. **Scheduled Backup**: YugabyteDB automated daily snapshots (retained 30 days)
2. **On-Demand Backup**: Manual backup before major changes via DBaaS console
3. **Recovery Point**: RPO < 1 hour (continuous WAL archival)
4. **Recovery Time**: RTO < 30 minutes (automated restore from snapshot)
5. **Validation**: Post-restore authentication flow smoke test
6. **DragonflyDB**: No backup required (ephemeral cache; sessions regenerate on login)

---

*Document generated by the AIDD pipeline. Workflow sequences derived from architecture.md and prd.md.*
