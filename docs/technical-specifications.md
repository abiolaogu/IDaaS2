# Technical Specifications — IDaaS
> Version: 1.0 | Last Updated: 2026-02-18 | Status: Draft
> Classification: Internal | Author: AIDD System

---

## 1. Introduction

This document provides the definitive technical specifications for the IDaaS platform,
covering protocol compliance, API contracts, performance targets, security requirements,
and infrastructure specifications.

---

## 2. Protocol Specifications

### 2.1 OpenID Connect 1.0

| Specification | Value |
|---------------|-------|
| Conformance Level | OpenID Connect Core 1.0 |
| Discovery | `/.well-known/openid-configuration` (RFC 8414) |
| Response Types | `code` |
| Grant Types | `authorization_code`, `client_credentials`, `refresh_token`, `urn:ietf:params:oauth:grant-type:device_code` |
| Token Endpoint Auth | `client_secret_basic`, `client_secret_post`, `private_key_jwt` |
| PKCE | S256 (RFC 7636) - required for public clients, recommended for confidential |
| ID Token Signing | RS256 (RSA PKCS#1 v1.5 with SHA-256) |
| ID Token Encryption | None (planned: RSA-OAEP with A256GCM) |
| Supported Scopes | `openid`, `email`, `profile`, `address`, `phone`, `offline_access`, `roles` |
| UserInfo Endpoint | GET and POST supported |
| Dynamic Registration | Supported (RFC 7591) |

### 2.2 OAuth 2.0

| Specification | Value |
|---------------|-------|
| Core | RFC 6749, RFC 6750 |
| PKCE | RFC 7636 (S256 challenge method) |
| Token Revocation | RFC 7009 |
| Token Introspection | RFC 7662 |
| Device Authorization | RFC 8628 |
| JWT Access Tokens | RFC 9068 |
| Security BCP | RFC 9700 |

### 2.3 SAML 2.0 (Planned)

| Specification | Value |
|---------------|-------|
| Profiles | Web Browser SSO (SP-initiated, IdP-initiated) |
| Bindings | HTTP-POST, HTTP-Redirect |
| Name ID Formats | `urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress`, `persistent`, `transient` |
| Assertion Signing | RSA-SHA256 |
| Metadata Exchange | SAML 2.0 Metadata (auto-import) |

### 2.4 SCIM 2.0 (Planned)

| Specification | Value |
|---------------|-------|
| Core Schema | RFC 7643 |
| Protocol | RFC 7644 |
| Supported Resources | User, Group |
| Supported Operations | GET, POST, PUT, PATCH, DELETE |
| Filtering | `eq`, `co`, `sw`, `gt`, `lt`, `and`, `or` operators |
| Pagination | `startIndex` and `count` parameters |
| Bulk Operations | Planned |
| Change Notifications | Webhook (planned) |

### 2.5 LDAP v3 (Planned)

| Specification | Value |
|---------------|-------|
| Protocol | RFC 4511 |
| Bind Methods | Simple bind, SASL (GSSAPI) |
| Search | Base, one-level, subtree |
| Schema | inetOrgPerson, posixAccount, groupOfNames |
| Transport Security | LDAPS (port 636) or StartTLS (port 389) |

---

## 3. API Specifications

### 3.1 Keycloak Admin REST API

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/admin/realms` | GET/POST | List/create realms |
| `/admin/realms/{realm}/users` | GET/POST | List/create users |
| `/admin/realms/{realm}/users/{id}` | GET/PUT/DELETE | Manage user |
| `/admin/realms/{realm}/clients` | GET/POST | List/create clients |
| `/admin/realms/{realm}/roles` | GET/POST | List/create roles |
| `/admin/realms/{realm}/groups` | GET/POST | List/create groups |
| `/admin/realms/{realm}/events` | GET | Query audit events |

**Authentication**: Bearer token with `realm-management` client roles.

### 3.2 Flask Application API

| Endpoint | Method | Auth | Response |
|----------|--------|------|----------|
| `/` | GET | OAuth2 Proxy | HTML page with user context |
| `/health` | GET | None | `{"status": "healthy"}` |
| `/readiness` | GET | None | `{"status": "ready"}` / 503 |
| `/liveness` | GET | None | `{"status": "alive"}` / 503 |
| `/metrics` | GET | None | Prometheus text format |

### 3.3 SCIM 2.0 API (Planned)

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/scim/v2/Users` | GET | List users with filtering and pagination |
| `/scim/v2/Users` | POST | Create user |
| `/scim/v2/Users/{id}` | GET | Get user by SCIM ID |
| `/scim/v2/Users/{id}` | PUT | Replace user |
| `/scim/v2/Users/{id}` | PATCH | Partial update user |
| `/scim/v2/Users/{id}` | DELETE | Delete user |
| `/scim/v2/Groups` | GET/POST | List/create groups |
| `/scim/v2/Groups/{id}` | GET/PUT/PATCH/DELETE | Manage group |
| `/scim/v2/Schemas` | GET | List supported schemas |
| `/scim/v2/ResourceTypes` | GET | List resource types |
| `/scim/v2/ServiceProviderConfig` | GET | Provider capabilities |

---

## 4. Token Specifications

### 4.1 Access Token (JWT)

| Field | Type | Description |
|-------|------|-------------|
| `iss` | string | `https://auth.example.com/realms/{realm}` |
| `sub` | string (UUID) | User unique identifier |
| `aud` | string/array | Target audience (client_id or `account`) |
| `exp` | integer | Expiration time (Unix epoch) |
| `iat` | integer | Issued at time (Unix epoch) |
| `azp` | string | Authorized party (client_id) |
| `realm_access` | object | `{"roles": ["role1", "role2"]}` |
| `resource_access` | object | `{"client_id": {"roles": [...]}}` |
| `scope` | string | Space-separated granted scopes |
| `email` | string | User email (if `email` scope granted) |
| `preferred_username` | string | Username (if `profile` scope granted) |

**Signing**: RS256 with realm-specific RSA key pair (2048-bit minimum)
**Lifetime**: 300 seconds (5 minutes)

### 4.2 Refresh Token

| Property | Value |
|----------|-------|
| Format | Opaque (server-side reference) |
| Lifetime | 1800 seconds (30 minutes) |
| Storage | YugabyteDB (Keycloak session store) |
| Rotation | Enabled (each refresh issues new refresh token) |
| Revocation | Supported via token revocation endpoint |

---

## 5. Security Specifications

### 5.1 Cryptographic Standards

| Purpose | Algorithm | Key Size |
|---------|-----------|----------|
| JWT Signing | RS256 | 2048-bit RSA |
| TLS | TLS 1.3 | ECDHE + AES-256-GCM |
| Password Hashing | bcrypt | Cost factor 12 |
| TOTP | HMAC-SHA1 | 160-bit shared secret |
| Session Encryption | AES-256-GCM | 256-bit |

### 5.2 Security Headers

| Header | Value |
|--------|-------|
| `Strict-Transport-Security` | `max-age=31536000; includeSubDomains` |
| `Content-Security-Policy` | `default-src 'self'` |
| `X-Frame-Options` | `DENY` |
| `X-Content-Type-Options` | `nosniff` |
| `X-XSS-Protection` | `1; mode=block` |
| `Referrer-Policy` | `strict-origin-when-cross-origin` |
| `Permissions-Policy` | `camera=(), microphone=(), geolocation=()` |

### 5.3 Rate Limiting

| Scope | Limit |
|-------|-------|
| Per IP (requests per second) | 100 |
| Per IP (requests per minute) | 1,000 |
| Login attempts per user | 5 failures before lockout |
| Lockout duration | 15 minutes (progressive) |

---

## 6. Performance Specifications

| Metric | Target | Measurement |
|--------|--------|-------------|
| Token issuance (P50) | < 50ms | Authorization server response time |
| Token issuance (P95) | < 200ms | Authorization server response time |
| Token issuance (P99) | < 500ms | Authorization server response time |
| Login page load (P95) | < 1 second | Full page render including assets |
| UserInfo endpoint (P95) | < 100ms | API response time |
| SCIM create user (P95) | < 500ms | API response time (planned) |
| Concurrent sessions | 10,000 | Active authenticated sessions |
| Auth throughput | 500 /second | Successful authentications per second |
| Availability | 99.99% | Monthly uptime percentage |

---

## 7. Infrastructure Specifications

### 7.1 Container Images

| Image | Base | Size Target | Registry |
|-------|------|-------------|----------|
| idaas-webapp | python:3.11-slim | < 200 MiB | ghcr.io |
| keycloak | quay.io/keycloak/keycloak:24.x | < 500 MiB | quay.io |
| oauth2-proxy | quay.io/oauth2-proxy/oauth2-proxy:7.x | < 50 MiB | quay.io |

### 7.2 Kubernetes Resource Specifications

| Resource | Specification |
|----------|---------------|
| Namespace | `idaas` |
| ResourceQuota | 16 CPU request / 32 CPU limit, 32Gi mem request / 64Gi mem limit |
| LimitRange | 100m-4 CPU, 128Mi-8Gi per container |
| NetworkPolicy | Deny-all default with explicit allow rules |
| PodDisruptionBudget | minAvailable: 1 for all deployments |
| ServiceAccount | Dedicated `idaas-sa` with least-privilege RBAC |

### 7.3 Database Specifications

| Database | Spec | Connection Pool |
|----------|------|----------------|
| YugabyteDB | PostgreSQL-compatible, RF=3, 3-5 nodes | Min: 5, Max: 20 per pod |
| DragonflyDB | Redis-compatible, ~25x Redis throughput | Max: 100 connections per pod |

---

## 8. Compliance Specifications

| Standard | Scope | Implementation |
|----------|-------|----------------|
| SOC 2 Type II | All IDaaS services | Audit logging, access controls, monitoring |
| ISO 27001 | Platform infrastructure | Risk management, ISMS, asset classification |
| GDPR | User data processing | Consent management, data export, right to erasure |
| NIST SP 800-63B | Authentication assurance | TOTP (AAL2), WebAuthn (AAL3 planned) |
| PCI DSS 4.0 | If payment data transits | TLS 1.3, access logging, key management |

---

*Document generated by the AIDD pipeline. Specifications derived from protocol RFCs and platform architecture.*
