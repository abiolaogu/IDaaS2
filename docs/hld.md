# High-Level Design (HLD) — IDaaS
> Version: 1.0 | Last Updated: 2026-02-18 | Status: Draft
> Classification: Internal | Author: AIDD System

---

## 1. Introduction

### 1.1 Purpose

This High-Level Design document provides a system-level view of the IDaaS platform
architecture, describing the major subsystems, their interactions, data flows, and
deployment topology without descending into implementation-level detail.

### 1.2 Scope

Covers the complete IDaaS platform: identity provider, application layer, authentication
gateway, data tier, external integrations, and operational infrastructure.

---

## 2. System Context

### 2.1 External Actors

| Actor | Description | Protocol |
|-------|-------------|----------|
| End Users (Browser) | Workforce and customer users accessing web applications | HTTPS |
| Mobile Users | MFA authenticator app users | HTTPS / TOTP |
| API Consumers | Backend services and third-party integrations | OAuth 2.0 Bearer |
| External IdPs | Federated identity providers (Azure AD, Google, Okta) | SAML 2.0 / OIDC |
| HR Systems | Employee lifecycle management systems (Workday, BambooHR) | SCIM 2.0 |
| SaaS Applications | Downstream applications receiving provisioned accounts | OIDC / SAML / SCIM |
| DevOps Engineers | Platform operators managing deployment and monitoring | kubectl / Helm / CI |

### 2.2 System Boundary Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     IDaaS Platform Boundary                  │
│                                                              │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  Ingress Layer                                         │  │
│  │  - NGINX Ingress Controller (TLS, rate limiting)       │  │
│  │  - cert-manager (automated certificate provisioning)   │  │
│  └───────────────────────┬───────────────────────────────┘  │
│                          │                                   │
│  ┌───────────────────────▼───────────────────────────────┐  │
│  │  Authentication Layer                                  │  │
│  │  - Keycloak (OIDC/OAuth2/SAML/LDAP/MFA)               │  │
│  │  - OAuth2 Proxy (session enforcement)                  │  │
│  └───────────────────────┬───────────────────────────────┘  │
│                          │                                   │
│  ┌───────────────────────▼───────────────────────────────┐  │
│  │  Application Layer                                     │  │
│  │  - Flask Web Application (business logic, UI)          │  │
│  │  - SCIM Provisioning Service (planned)                 │  │
│  └───────────────────────┬───────────────────────────────┘  │
│                          │                                   │
│  ┌───────────────────────▼───────────────────────────────┐  │
│  │  Data Layer                                            │  │
│  │  - YugabyteDB (SQL persistence)                        │  │
│  │  - DragonflyDB (cache and session store)               │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## 3. Major Subsystems

### 3.1 Identity Provider Subsystem (Keycloak)

**Function**: Centralized authentication, authorization, and identity management.

**Responsibilities**:
- Protocol handling: OIDC, OAuth 2.0, SAML 2.0, LDAP v3
- User credential validation and storage
- Multi-factor authentication orchestration (TOTP, WebAuthn)
- Token issuance and lifecycle (JWT access tokens, refresh tokens, ID tokens)
- Realm-based multi-tenancy isolation
- Identity brokering for external IdPs
- Fine-grained authorization services (RBAC, ABAC)
- Admin console for realm and user management

**Scale**: 2 replicas, session affinity, 500m-2000m CPU, 1-2Gi memory

### 3.2 Authentication Gateway Subsystem (OAuth2 Proxy)

**Function**: Enforce authentication on all requests to protected upstream services.

**Responsibilities**:
- Intercept unauthenticated HTTP requests
- Redirect to Keycloak OIDC authorization endpoint
- Exchange authorization codes for tokens
- Manage session cookies backed by DragonflyDB
- Forward identity headers to upstream Flask application

**Scale**: 2 replicas, 100m-500m CPU, 128Mi-512Mi memory

### 3.3 Web Application Subsystem (Flask)

**Function**: Business logic, user interface, and API layer.

**Responsibilities**:
- Render application pages with user identity context
- Expose health, readiness, liveness, and metrics endpoints
- Apply security headers (HSTS, CSP, X-Frame-Options)
- Process identity headers from OAuth2 Proxy
- Serve as the upstream target for OAuth2 Proxy

**Scale**: 3-10 replicas (HPA), 200m-1000m CPU, 256Mi-1Gi memory

### 3.4 Data Subsystem

**Function**: Persistent and ephemeral data management.

| Component | Type | Purpose |
|-----------|------|---------|
| YugabyteDB | Distributed SQL | Keycloak schema: users, credentials, sessions, events, roles, clients |
| DragonflyDB db0 | In-memory cache | Flask application cache (page fragments, API responses) |
| DragonflyDB db1 | In-memory sessions | OAuth2 Proxy encrypted session data |

### 3.5 Mobile MFA Subsystem (Flutter Authenticator)

**Function**: Time-based one-time password generation for second-factor authentication.

**Responsibilities**:
- QR code scanning for Keycloak TOTP enrollment
- RFC 6238 TOTP code generation (30-second interval, 6 digits)
- Secure storage of TOTP secrets using platform secure storage
- Multiple account support with account management UI

---

## 4. High-Level Data Flow

### 4.1 Authentication Data Flow

```
User -> NGINX Ingress (TLS 1.3) -> OAuth2 Proxy
  -> [No session] -> Redirect to Keycloak
    -> User authenticates (credentials + MFA)
    -> Keycloak issues authorization code
  -> OAuth2 Proxy exchanges code for tokens
  -> Session stored in DragonflyDB (db1)
  -> Request forwarded to Flask with identity headers
  -> Flask renders page with user context
```

### 4.2 Token Data Flow

```
Keycloak signs JWT (RS256) with realm private key
  -> Access Token: 5 min TTL, contains roles/scopes/claims
  -> ID Token: 5 min TTL, contains user identity attributes
  -> Refresh Token: 30 min TTL, stored in Keycloak DB
OAuth2 Proxy stores session cookie mapping to DragonflyDB
Flask receives identity via X-Forwarded-* headers (no direct token access)
```

### 4.3 Provisioning Data Flow (Planned)

```
HR System -> SCIM 2.0 API -> SCIM Service
  -> Create/Update/Delete user in Keycloak
  -> Trigger outbound provisioning to SaaS apps
  -> Log sync event to audit trail
```

---

## 5. Deployment Topology

### 5.1 Kubernetes Namespace Layout

```
Namespace: idaas
├── Deployments
│   ├── keycloak (2 replicas)
│   ├── webapp (3 replicas, HPA 3-10)
│   └── oauth2-proxy (2 replicas)
├── Services
│   ├── keycloak-svc (ClusterIP, port 8080)
│   ├── webapp-svc (ClusterIP, port 8080)
│   └── oauth2-proxy-svc (ClusterIP, port 4180)
├── Ingress
│   ├── auth.example.com -> keycloak-svc
│   └── app.example.com -> oauth2-proxy-svc
├── ConfigMaps & Secrets
├── ServiceAccount + RBAC
├── NetworkPolicies
├── PodDisruptionBudgets
├── ResourceQuota (16 CPU req, 32Gi mem req)
└── LimitRange (100m-4 CPU, 128Mi-8Gi per container)
```

### 5.2 External Dependencies

| Dependency | Type | Connectivity |
|-----------|------|-------------|
| YugabyteDB | DBaaS | PostgreSQL wire protocol over TLS (port 5433) |
| DragonflyDB | DBaaS | Redis protocol over TLS (port 6379) |
| Let's Encrypt | Certificate Authority | ACME protocol (HTTPS) |
| Container Registry (GHCR) | Image storage | HTTPS pull from Kubernetes |
| DNS Provider | Name resolution | Standard DNS |

---

## 6. Non-Functional Requirements Summary

| Quality Attribute | Target | Design Decision |
|-------------------|--------|-----------------|
| Availability | 99.99% | Multi-replica, PDB, HPA, managed DBaaS |
| Latency | P95 < 200ms token issuance | DragonflyDB caching, session affinity |
| Scalability | 10,000 concurrent sessions | HPA auto-scaling, stateless app tier |
| Security | Zero trust, phishing-resistant MFA | TLS everywhere, OAuth2 Proxy enforcement, MFA |
| Recoverability | RPO < 1h, RTO < 30m | DBaaS snapshots, session regeneration |
| Observability | Full request traceability | /metrics endpoints, audit event logging |

---

## 7. Technology Decision Log

| Decision | Choice | Rationale | Alternatives Considered |
|----------|--------|-----------|------------------------|
| Identity Provider | Keycloak | Open-source, protocol-complete, multi-tenant | Ory Hydra, Gluu, Authelia |
| Application Framework | Flask | Python team skills, lightweight, extensible | Django, FastAPI |
| Auth Gateway | OAuth2 Proxy | OIDC-native, Keycloak-integrated, lightweight | Pomerium, Traefik Forward Auth |
| SQL Database | YugabyteDB | PostgreSQL-compatible, distributed, managed | CockroachDB, Aurora, Citus |
| Cache Store | DragonflyDB | Redis-compatible, 25x performance, managed | Redis, Memcached, Valkey |
| Container Orchestration | Kubernetes | Industry standard, auto-scaling, declarative | Docker Swarm, Nomad |
| Mobile Framework | Flutter | Cross-platform iOS/Android from single codebase | React Native, Kotlin Multiplatform |

---

*Document generated by the AIDD pipeline. For detailed component specifications, see lld.md.*
