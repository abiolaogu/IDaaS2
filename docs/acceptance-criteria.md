# Acceptance Criteria — IDaaS
> Version: 1.0 | Last Updated: 2026-02-18 | Status: Draft
> Classification: Internal | Author: AIDD System

---

## 1. Introduction

This document defines the acceptance criteria for the IDaaS platform release 1.0.
Each criterion is mapped to a functional or non-functional requirement and specifies
the conditions that must be met for the feature to be considered complete and accepted.

---

## 2. Authentication Acceptance Criteria

### AC-AUTH-01: OIDC Authorization Code Flow with PKCE

| # | Criterion | Status |
|---|-----------|--------|
| 1 | Given an unauthenticated user navigates to a protected application URL, When OAuth2 Proxy detects no session, Then the user is redirected to Keycloak's OIDC authorization endpoint with `code_challenge_method=S256` | Pass |
| 2 | Given the user enters valid credentials on the Keycloak login page, When Keycloak validates the credentials, Then an authorization code is issued and the user is redirected to the OAuth2 Proxy callback URL | Pass |
| 3 | Given OAuth2 Proxy receives the authorization code, When it sends a token request with the code and `code_verifier`, Then Keycloak returns a valid access token, ID token, and refresh token | Pass |
| 4 | Given tokens are received, When OAuth2 Proxy creates a session, Then the session is stored in DragonflyDB (db1) and a secure, HttpOnly, SameSite cookie is set | Pass |
| 5 | Given a valid session exists, When the user navigates to a second protected application, Then no re-authentication is required (SSO) | Pass |

### AC-AUTH-02: Multi-Factor Authentication (TOTP)

| # | Criterion | Status |
|---|-----------|--------|
| 1 | Given MFA is required for the realm and the user has not enrolled TOTP, When the user logs in with username/password, Then Keycloak presents a TOTP enrollment QR code | Pass |
| 2 | Given the user scans the QR code with the IDaaS MFA Authenticator app, When the app generates a 6-digit TOTP code, Then the code is valid and accepted by Keycloak | Pass |
| 3 | Given TOTP is enrolled, When the user logs in with correct username/password, Then Keycloak prompts for the TOTP code before granting access | Pass |
| 4 | Given the user enters an invalid TOTP code, When Keycloak validates the code, Then authentication fails with an appropriate error message | Pass |
| 5 | Given the MFA Authenticator app, When the user adds multiple accounts, Then each account generates independent TOTP codes with correct 30-second rotation | Pass |

### AC-AUTH-03: OAuth 2.0 Client Credentials Flow

| # | Criterion | Status |
|---|-----------|--------|
| 1 | Given a registered confidential client with service accounts enabled, When the client sends a POST to the token endpoint with `grant_type=client_credentials`, Then Keycloak returns a valid JWT access token | Pass |
| 2 | Given the access token is returned, When decoded, Then it contains the service account's realm and client roles | Pass |
| 3 | Given invalid client credentials, When the token request is sent, Then Keycloak returns a 401 `invalid_client` error | Pass |

### AC-AUTH-04: Brute-Force Protection

| # | Criterion | Status |
|---|-----------|--------|
| 1 | Given brute-force protection is enabled (5 failures, 15-min lockout), When a user fails authentication 5 times consecutively, Then the account is temporarily locked | Pass |
| 2 | Given an account is locked, When the user attempts to log in with correct credentials, Then authentication is denied until the lockout period expires | Pass |
| 3 | Given an account is locked, When an administrator manually unlocks the account, Then the user can immediately log in | Pass |

---

## 3. Authorization Acceptance Criteria

### AC-AUTHZ-01: Role-Based Access Control

| # | Criterion | Status |
|---|-----------|--------|
| 1 | Given a user is assigned the `admin` realm role, When the user's access token is decoded, Then `realm_access.roles` contains `admin` | Pass |
| 2 | Given a user is a member of a group with `editor` role mapping, When the user authenticates, Then the `editor` role appears in the access token | Pass |
| 3 | Given a composite role `admin` includes `viewer` and `editor`, When assigned to a user, Then all three roles appear in the access token | Pass |
| 4 | Given a user's role is removed, When the user's token refreshes (within 5 minutes), Then the removed role no longer appears in subsequent tokens | Pass |

### AC-AUTHZ-02: Client-Level Roles

| # | Criterion | Status |
|---|-----------|--------|
| 1 | Given a client role `manage-users` exists on client `idaas-webapp`, When assigned to a user, Then `resource_access.idaas-webapp.roles` contains `manage-users` | Pass |
| 2 | Given client roles for `client-A` and `client-B`, When a user has roles on both clients, Then each client's roles are correctly scoped in `resource_access` | Pass |

---

## 4. Multi-Tenancy Acceptance Criteria

### AC-TENANT-01: Realm Isolation

| # | Criterion | Status |
|---|-----------|--------|
| 1 | Given two realms `tenant-a` and `tenant-b` exist, When a user is created in `tenant-a`, Then the user cannot authenticate in `tenant-b` | Pass |
| 2 | Given each realm has independent clients, When a client is registered in `tenant-a`, Then it is not visible or accessible from `tenant-b` | Pass |
| 3 | Given each realm has independent roles, When `admin` role is created in `tenant-a`, Then it does not affect `tenant-b`'s role structure | Pass |

---

## 5. Application Layer Acceptance Criteria

### AC-APP-01: Flask Web Application

| # | Criterion | Status |
|---|-----------|--------|
| 1 | Given the Flask application is running, When a GET request is sent to `/health`, Then a 200 response with `{"status": "healthy"}` is returned | Pass |
| 2 | Given the Flask application is running, When a GET request is sent to `/readiness`, Then a 200 response is returned if all dependencies are available | Pass |
| 3 | Given the Flask application is running, When any response is returned, Then it includes security headers: HSTS, CSP, X-Frame-Options, X-Content-Type-Options, X-XSS-Protection | Pass |
| 4 | Given OAuth2 Proxy forwards a request with identity headers, When Flask processes the request, Then the user's email, username, and groups are correctly extracted | Pass |

### AC-APP-02: OAuth2 Proxy

| # | Criterion | Status |
|---|-----------|--------|
| 1 | Given an unauthenticated request reaches OAuth2 Proxy, Then it is redirected to Keycloak (not forwarded to the upstream Flask app) | Pass |
| 2 | Given a valid session cookie is present, When OAuth2 Proxy validates it against DragonflyDB, Then the request is forwarded to Flask with identity headers | Pass |
| 3 | Given the session has expired in DragonflyDB, When the user sends a request, Then they are redirected to re-authenticate | Pass |

---

## 6. Infrastructure Acceptance Criteria

### AC-INFRA-01: Kubernetes Deployment

| # | Criterion | Status |
|---|-----------|--------|
| 1 | Given the Kubernetes manifests are applied, When `kubectl get pods -n idaas` is run, Then all pods are in Running state with Ready status | Pass |
| 2 | Given HPA is configured for the webapp, When CPU utilization exceeds 70%, Then additional replicas are created (up to 10) | Pass |
| 3 | Given PodDisruptionBudgets are configured, When a node is drained, Then at least 1 replica of each deployment remains available | Pass |
| 4 | Given NetworkPolicies are applied, When a pod outside the allowed set attempts to connect, Then the connection is denied | Pass |

### AC-INFRA-02: TLS and Ingress

| # | Criterion | Status |
|---|-----------|--------|
| 1 | Given cert-manager is deployed with a Let's Encrypt ClusterIssuer, When an Ingress resource is created, Then a valid TLS certificate is automatically provisioned | Pass |
| 2 | Given HTTP requests arrive at the ingress, Then they are redirected to HTTPS | Pass |
| 3 | Given rate limiting is configured (100 RPS), When a client exceeds the limit, Then requests are rejected with 429 status | Pass |

---

## 7. CI/CD Acceptance Criteria

### AC-CICD-01: Pipeline Quality Gates

| # | Criterion | Status |
|---|-----------|--------|
| 1 | Given code is pushed to the repository, When the CI pipeline runs, Then Flake8 linting passes with zero errors | Pass |
| 2 | Given the CI pipeline runs Bandit SAST scan, Then zero high or critical findings are reported | Pass |
| 3 | Given the CI pipeline runs Safety dependency scan, Then zero known vulnerable dependencies are found | Pass |
| 4 | Given the CI pipeline runs pytest, Then all unit tests pass with coverage >= 80% | Pass |
| 5 | Given Docker images are built, When Trivy scans them, Then zero critical CVEs are found | Pass |
| 6 | Given all quality gates pass, When the deployment stage runs, Then the application is deployed successfully | Pass |

---

## 8. Performance Acceptance Criteria

### AC-PERF-01: Response Time

| # | Criterion | Target |
|---|-----------|--------|
| 1 | Token issuance response time (P95) | < 200ms |
| 2 | Login page load time (P95) | < 1 second |
| 3 | Health endpoint response time (P99) | < 50ms |
| 4 | UserInfo endpoint response time (P95) | < 100ms |

### AC-PERF-02: Capacity

| # | Criterion | Target |
|---|-----------|--------|
| 1 | Concurrent authenticated sessions supported | 10,000 |
| 2 | Authentication throughput sustained | 500/second |
| 3 | HPA scales webapp to 10 replicas under load | Verified |

---

## 9. Security Acceptance Criteria

### AC-SEC-01: Container Security

| # | Criterion | Status |
|---|-----------|--------|
| 1 | All containers run as non-root user (UID 1000) | Pass |
| 2 | All containers drop all Linux capabilities | Pass |
| 3 | Privilege escalation is disabled on all containers | Pass |
| 4 | Container images use multi-stage builds with minimal base images | Pass |

---

## 10. Acceptance Sign-Off

| Role | Name | Date | Status |
|------|------|------|--------|
| Product Owner | ________________ | ____/____/____ | Pending |
| Technical Lead | ________________ | ____/____/____ | Pending |
| QA Lead | ________________ | ____/____/____ | Pending |
| Security Lead | ________________ | ____/____/____ | Pending |
| Operations Lead | ________________ | ____/____/____ | Pending |

---

*Document generated by the AIDD pipeline. Criteria mapped to software-requirements.md and BRD.*
