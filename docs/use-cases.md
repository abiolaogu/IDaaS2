# Use Cases Document — IDaaS
> Version: 1.0 | Last Updated: 2026-02-18 | Status: Draft
> Classification: Internal | Author: AIDD System

---

## 1. Introduction

This document enumerates the use cases for the IDaaS platform, organized by actor and
functional domain. Each use case includes preconditions, main flow, alternate flows,
and postconditions.

---

## 2. Actor Definitions

| Actor | Description |
|-------|-------------|
| End User | Workforce or customer user authenticating to applications |
| Tenant Admin | Organization administrator managing users, roles, and policies |
| Platform Admin | IDaaS platform operator managing realms, infrastructure, monitoring |
| Developer | Application developer integrating with IDaaS via SDKs and APIs |
| External IdP | Federated identity provider (Azure AD, Google, Okta) |
| HR System | Human resources system triggering provisioning events |
| API Consumer | Backend service authenticating via client credentials |

---

## 3. Authentication Use Cases

### UC-AUTH-01: Single Sign-On via OIDC

| Field | Value |
|-------|-------|
| **ID** | UC-AUTH-01 |
| **Actor** | End User |
| **Description** | User authenticates once and accesses multiple applications without re-entering credentials |
| **Preconditions** | User has an active account in the tenant realm; application is registered as OIDC client |
| **Main Flow** | 1. User navigates to application URL. 2. OAuth2 Proxy detects no session. 3. User is redirected to Keycloak login. 4. User enters credentials. 5. Keycloak issues authorization code. 6. OAuth2 Proxy exchanges code for tokens. 7. Session cookie is set. 8. User accesses application. 9. User navigates to second application. 10. Existing SSO session is detected; no re-authentication required. |
| **Alternate Flow** | A1: Invalid credentials -- Keycloak returns error, user retries (max 5 attempts before lockout). |
| **Postconditions** | User has active SSO session; session stored in DragonflyDB |
| **Priority** | Critical |

### UC-AUTH-02: Multi-Factor Authentication (TOTP)

| Field | Value |
|-------|-------|
| **ID** | UC-AUTH-02 |
| **Actor** | End User |
| **Description** | User completes second-factor authentication using TOTP code from mobile authenticator |
| **Preconditions** | User has TOTP enrolled; MFA policy is enabled for the realm |
| **Main Flow** | 1. User enters username and password. 2. Keycloak validates primary credentials. 3. Keycloak prompts for TOTP code. 4. User opens IDaaS MFA Authenticator app. 5. User enters 6-digit TOTP code. 6. Keycloak validates code against stored secret. 7. Authentication succeeds. |
| **Alternate Flow** | A1: Invalid TOTP -- user retries. A2: TOTP not enrolled -- Keycloak redirects to enrollment flow. |
| **Postconditions** | User authenticated at AAL2 assurance level |
| **Priority** | Critical |

### UC-AUTH-03: SAML Federation SSO (Planned)

| Field | Value |
|-------|-------|
| **ID** | UC-AUTH-03 |
| **Actor** | End User, External IdP |
| **Description** | User authenticates via external SAML IdP and is federated into IDaaS |
| **Preconditions** | External IdP is configured as identity broker in Keycloak; SAML metadata exchanged |
| **Main Flow** | 1. User selects external IdP on login page. 2. Keycloak generates SAML AuthnRequest. 3. User is redirected to external IdP. 4. User authenticates at external IdP. 5. External IdP returns SAML Response. 6. Keycloak validates assertion signature. 7. Keycloak maps attributes and creates/links local account (JIT provisioning). 8. User accesses application. |
| **Alternate Flow** | A1: SAML assertion validation fails -- error displayed, user redirected to login. |
| **Postconditions** | Federated user has local session; account linked to external IdP |
| **Priority** | High |

### UC-AUTH-04: Client Credentials (Machine-to-Machine)

| Field | Value |
|-------|-------|
| **ID** | UC-AUTH-04 |
| **Actor** | API Consumer |
| **Description** | Backend service obtains access token using client credentials grant |
| **Preconditions** | Service client registered with service account enabled |
| **Main Flow** | 1. Service sends POST to `/realms/{realm}/protocol/openid-connect/token`. 2. Request includes `grant_type=client_credentials`, `client_id`, `client_secret`. 3. Keycloak validates credentials. 4. Keycloak issues JWT access token with service account roles. 5. Service uses Bearer token for API calls. |
| **Postconditions** | Service has valid access token (5-minute TTL) |
| **Priority** | High |

### UC-AUTH-05: Passwordless Authentication (Planned)

| Field | Value |
|-------|-------|
| **ID** | UC-AUTH-05 |
| **Actor** | End User |
| **Description** | User authenticates using WebAuthn/FIDO2 security key or biometric |
| **Preconditions** | User has registered FIDO2 authenticator; WebAuthn flow configured |
| **Main Flow** | 1. User enters username. 2. Keycloak sends WebAuthn challenge. 3. Browser prompts for security key or biometric. 4. User touches security key or provides biometric. 5. Authenticator signs challenge. 6. Keycloak verifies signature. 7. Authentication succeeds without password. |
| **Postconditions** | User authenticated at AAL3 assurance level |
| **Priority** | Medium |

---

## 4. User Management Use Cases

### UC-USER-01: Self-Service Registration

| Field | Value |
|-------|-------|
| **ID** | UC-USER-01 |
| **Actor** | End User |
| **Description** | New user creates account via self-service registration |
| **Preconditions** | Registration is enabled for the realm |
| **Main Flow** | 1. User navigates to registration page. 2. User enters email, first name, last name, password. 3. Password complexity validated (12+ chars, mixed case, digits, special). 4. Keycloak sends verification email. 5. User clicks verification link. 6. Account is activated. |
| **Postconditions** | New user account with verified email; default "end-user" role assigned |
| **Priority** | High |

### UC-USER-02: Password Reset

| Field | Value |
|-------|-------|
| **ID** | UC-USER-02 |
| **Actor** | End User |
| **Description** | User resets forgotten password via email verification |
| **Preconditions** | User has verified email address |
| **Main Flow** | 1. User clicks "Forgot Password". 2. User enters email. 3. Keycloak sends reset link (15-minute expiry). 4. User clicks link. 5. User enters new password. 6. Password is updated; existing sessions invalidated. |
| **Postconditions** | New credential stored; user can authenticate with new password |
| **Priority** | High |

### UC-USER-03: SCIM User Provisioning (Planned)

| Field | Value |
|-------|-------|
| **ID** | UC-USER-03 |
| **Actor** | HR System |
| **Description** | HR system creates user account via SCIM 2.0 API |
| **Preconditions** | HR system has SCIM bearer token; SCIM service is operational |
| **Main Flow** | 1. HR system sends POST `/scim/v2/Users` with user attributes. 2. SCIM service validates request against SCIM schema. 3. SCIM service creates user in Keycloak realm. 4. SCIM service triggers outbound provisioning to SaaS apps. 5. 201 Created returned with user resource. |
| **Postconditions** | User exists in Keycloak and downstream SaaS applications |
| **Priority** | High |

### UC-USER-04: Account Deprovisioning (Planned)

| Field | Value |
|-------|-------|
| **ID** | UC-USER-04 |
| **Actor** | HR System, Tenant Admin |
| **Description** | User account is disabled and access revoked across all systems |
| **Main Flow** | 1. HR system sends SCIM PATCH to disable user (or admin disables in console). 2. User marked as disabled in Keycloak. 3. All active sessions terminated. 4. Refresh tokens revoked. 5. Outbound SCIM deprovisioning sent to SaaS apps. 6. After retention period, data permanently purged. |
| **Postconditions** | User cannot authenticate; downstream access revoked |
| **Priority** | High |

---

## 5. Administration Use Cases

### UC-ADMIN-01: Tenant Realm Creation

| Field | Value |
|-------|-------|
| **ID** | UC-ADMIN-01 |
| **Actor** | Platform Admin |
| **Description** | Create new isolated tenant realm in Keycloak |
| **Main Flow** | 1. Admin accesses Keycloak admin console. 2. Admin creates new realm with tenant name. 3. Configure login theme, email, password policies. 4. Register initial OIDC clients. 5. Create admin user with realm-admin role. 6. Validate SSO flow. |
| **Postconditions** | Isolated tenant realm operational |
| **Priority** | Critical |

### UC-ADMIN-02: Client Application Registration

| Field | Value |
|-------|-------|
| **ID** | UC-ADMIN-02 |
| **Actor** | Developer, Tenant Admin |
| **Description** | Register new application as OIDC or SAML client |
| **Main Flow** | 1. Admin/developer provides app name, type, redirect URIs. 2. System generates client_id and secret. 3. Configure scopes, roles, PKCE settings. 4. Download OIDC discovery metadata or client config. 5. Integrate and test authentication flow. |
| **Postconditions** | Application can authenticate users via IDaaS |
| **Priority** | High |

### UC-ADMIN-03: Role and Group Management

| Field | Value |
|-------|-------|
| **ID** | UC-ADMIN-03 |
| **Actor** | Tenant Admin |
| **Description** | Create and manage RBAC roles and group assignments |
| **Main Flow** | 1. Admin creates realm or client roles. 2. Admin creates groups with role mappings. 3. Admin assigns users to groups. 4. Role changes propagate on next token refresh. |
| **Postconditions** | Users receive updated roles and permissions |
| **Priority** | High |

---

## 6. Operational Use Cases

### UC-OPS-01: Monitor Platform Health

| Field | Value |
|-------|-------|
| **ID** | UC-OPS-01 |
| **Actor** | Platform Admin |
| **Description** | Monitor service health, performance, and availability |
| **Main Flow** | 1. Review /metrics endpoints for each service. 2. Check Kubernetes pod status and HPA scaling. 3. Monitor audit event stream for anomalies. 4. Review DragonflyDB session counts. 5. Verify YugabyteDB connection pool health. |
| **Postconditions** | Platform health status confirmed |
| **Priority** | Critical |

### UC-OPS-02: Incident Response

| Field | Value |
|-------|-------|
| **ID** | UC-OPS-02 |
| **Actor** | Platform Admin |
| **Description** | Respond to security incident or service degradation |
| **Main Flow** | 1. Alert detected (anomalous login, MFA failure spike). 2. Assess severity. 3. Contain: disable accounts, block IPs, revoke sessions. 4. Investigate audit logs. 5. Remediate root cause. 6. Recover services. 7. Document post-mortem. |
| **Postconditions** | Incident resolved; preventive controls updated |
| **Priority** | Critical |

---

## 7. Use Case Priority Matrix

| Priority | Use Cases |
|----------|-----------|
| Critical | UC-AUTH-01, UC-AUTH-02, UC-ADMIN-01, UC-OPS-01, UC-OPS-02 |
| High | UC-AUTH-03, UC-AUTH-04, UC-USER-01, UC-USER-02, UC-USER-03, UC-USER-04, UC-ADMIN-02, UC-ADMIN-03 |
| Medium | UC-AUTH-05 |

---

*Document generated by the AIDD pipeline. Use cases align with BRD requirements and PRD feature specifications.*
