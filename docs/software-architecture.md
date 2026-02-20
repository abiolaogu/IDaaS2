# Software Architecture Document — IDaaS
> Version: 1.0 | Last Updated: 2026-02-18 | Status: Draft
> Classification: Internal | Author: AIDD System

---

## 1. Introduction

### 1.1 Purpose

This document describes the software architecture of the IDaaS (Identity-as-a-Service)
platform, detailing the system decomposition, component interactions, technology choices,
and design decisions that govern the platform's construction.

### 1.2 Scope

The architecture covers all software components: Keycloak identity provider, Flask web
application, OAuth2 Proxy gateway, SCIM provisioning service (planned), MFA authenticator
app, data stores (YugabyteDB, DragonflyDB), and supporting infrastructure services.

---

## 2. Architectural Style

The IDaaS platform employs a **layered microservices architecture** with the following tiers:

```
┌─────────────────────────────────────────────────────────┐
│  Presentation Tier                                       │
│  - Flask Web Application (Jinja2 templates)              │
│  - Flutter MFA Authenticator (mobile)                    │
│  - Admin Console (Keycloak Admin UI)                     │
├─────────────────────────────────────────────────────────┤
│  API Gateway Tier                                        │
│  - NGINX Ingress Controller (TLS, rate limiting)         │
│  - OAuth2 Proxy (OIDC authentication enforcement)        │
├─────────────────────────────────────────────────────────┤
│  Identity Services Tier                                  │
│  - Keycloak (OIDC, OAuth2, SAML, LDAP, MFA)             │
│  - SCIM 2.0 Provisioning Service (planned)               │
├─────────────────────────────────────────────────────────┤
│  Data Tier                                               │
│  - YugabyteDB (SQL - identity, sessions, policies)       │
│  - DragonflyDB (cache, OAuth2 Proxy sessions)            │
└─────────────────────────────────────────────────────────┘
```

### 2.1 Architecture Principles

| Principle | Application |
|-----------|-------------|
| API-First | All services expose RESTful APIs; OIDC/SCIM endpoints are protocol-compliant |
| Defense in Depth | TLS everywhere, OAuth2 Proxy gateway, Keycloak authentication, RBAC authorization |
| Twelve-Factor App | Environment-based config, stateless processes, disposable containers |
| Separation of Concerns | Identity logic in Keycloak, app logic in Flask, session state in DragonflyDB |
| Fail-Safe Defaults | Deny-by-default access, secure headers, non-root containers |

---

## 3. Component Architecture

### 3.1 Keycloak Identity Provider

**Responsibility**: Central identity broker for all authentication and authorization.

**Technology**: Keycloak 24.x on Quarkus runtime (Java 17)

**Key Features**:
- Multi-tenant realm isolation (one realm per tenant organization)
- Protocol support: OIDC, OAuth 2.0 (authorization code, client credentials, device flow), SAML 2.0, LDAP v3
- Authentication flows: username/password, TOTP MFA, WebAuthn/FIDO2 (planned)
- Fine-grained authorization services (RBAC + ABAC via Keycloak Authorization Services)
- Identity brokering for external IdPs (Google, Azure AD, Okta)
- Dynamic client registration for developer self-service

**Deployment**: 2 replicas, 500m-2000m CPU, 1Gi-2Gi memory, session affinity via ClientIP

### 3.2 Flask Web Application

**Responsibility**: Application UI and business logic layer.

**Technology**: Python 3.11, Flask 3.1.1, Gunicorn WSGI server

**Design Patterns**:
- Application Factory Pattern (`create_app()`)
- Blueprint-based route organization
- Middleware pipeline: logging, security headers (HSTS, CSP, X-Frame-Options), error handlers

**Endpoints**:
| Endpoint | Purpose |
|----------|---------|
| `/` | Main application page |
| `/health` | Kubernetes health check |
| `/readiness` | Kubernetes readiness probe |
| `/liveness` | Kubernetes liveness probe |
| `/metrics` | Operational metrics |

**Deployment**: 3 replicas (HPA: 3-10), 200m-1000m CPU, 256Mi-1Gi memory

### 3.3 OAuth2 Proxy

**Responsibility**: Authentication enforcement gateway between NGINX Ingress and Flask app.

**Technology**: OAuth2 Proxy 7.x

**Flow**:
1. Intercept unauthenticated requests to `app.example.com`
2. Redirect to Keycloak OIDC authorization endpoint
3. Exchange authorization code for ID token and access token
4. Store session in DragonflyDB (Redis protocol)
5. Forward authenticated requests with identity headers (`X-Forwarded-Email`, `X-Forwarded-User`, `X-Forwarded-Groups`)

**Deployment**: 2 replicas, 100m-500m CPU, 128Mi-512Mi memory

### 3.4 MFA Authenticator App

**Responsibility**: Mobile TOTP authenticator compatible with Keycloak.

**Technology**: Flutter (Dart), BLoC state management

**Features**: QR code enrollment, TOTP generation (RFC 6238), secure secret storage, Material Design 3

### 3.5 SCIM 2.0 Provisioning Service (Planned)

**Responsibility**: Automated user and group lifecycle management.

**Planned Architecture**:
- REST API: `/scim/v2/Users`, `/scim/v2/Groups`, `/scim/v2/Schemas`, `/scim/v2/ServiceProviderConfig`
- Inbound provisioning from HR systems (Workday, BambooHR)
- Outbound connectors for SaaS targets (Google Workspace, Salesforce, Slack)
- Event-driven reconciliation via webhook or message bus

---

## 4. Data Architecture

### 4.1 YugabyteDB (Managed DBaaS)

**Role**: Primary SQL persistence for Keycloak and application data.

- PostgreSQL wire-compatible distributed SQL
- Connection: `jdbc:postgresql://endpoint:5433/keycloak?ssl=true`
- Tables: user_entity, credential, realm, client, user_role_mapping, user_session, offline_session, event_entity
- xCluster replication for multi-region consistency

### 4.2 DragonflyDB (Managed DBaaS)

**Role**: In-memory cache and session store.

- Redis-compatible protocol (25x faster than Redis)
- Database 0: Flask webapp cache (page fragments, API responses)
- Database 1: OAuth2 Proxy session storage (OIDC session cookies)
- SSL/TLS encrypted connections

---

## 5. Security Architecture

### 5.1 Authentication Flow

```
Client -> NGINX (TLS) -> OAuth2 Proxy -> Keycloak OIDC -> MFA Challenge
                                      <- ID Token + Access Token
       -> OAuth2 Proxy (session cookie) -> Flask App (identity headers)
```

### 5.2 Token Architecture

| Token | Type | Lifetime | Storage |
|-------|------|----------|---------|
| Access Token | JWT (RS256) | 5 minutes | Client memory |
| Refresh Token | Opaque | 30 minutes | Keycloak DB |
| ID Token | JWT (RS256) | 5 minutes | OAuth2 Proxy session |
| Session Cookie | Encrypted | 8 hours | DragonflyDB |

### 5.3 Security Controls

- TLS 1.3 termination at NGINX Ingress (cert-manager + Let's Encrypt)
- Rate limiting: 100 RPS / 1000 RPM per client IP
- Security headers: HSTS, CSP, X-Frame-Options, X-Content-Type-Options, X-XSS-Protection
- Non-root containers with dropped capabilities (`drop: [ALL]`)
- Kubernetes NetworkPolicy restricting inter-service traffic
- RBAC with dedicated ServiceAccounts and least-privilege Roles
- Container image scanning: Trivy, Bandit, Safety

---

## 6. Integration Patterns

### 6.1 Protocol Matrix

| Protocol | Direction | Use Case |
|----------|-----------|----------|
| OIDC / OAuth 2.0 | Inbound | Web/mobile SSO, API authorization |
| SAML 2.0 | Inbound/Outbound | Enterprise federation (planned) |
| LDAP v3 | Outbound | Directory authentication (planned) |
| SCIM 2.0 | Inbound/Outbound | User provisioning (planned) |
| Redis Protocol | Internal | Session storage, caching |
| PostgreSQL Wire | Internal | SQL persistence |

### 6.2 JWT Claim Structure

```json
{
  "iss": "https://auth.example.com/realms/{tenant}",
  "sub": "user-uuid",
  "aud": "idaas-webapp",
  "exp": 1708300000,
  "iat": 1708299700,
  "azp": "idaas-webapp",
  "realm_access": { "roles": ["admin", "user"] },
  "resource_access": { "idaas-webapp": { "roles": ["manage-users"] } },
  "scope": "openid email profile",
  "email": "user@example.com",
  "preferred_username": "jdoe",
  "tenant_id": "org-123"
}
```

---

## 7. Deployment Architecture

- **Container Runtime**: Docker (OCI images)
- **Orchestration**: Kubernetes with NGINX Ingress Controller
- **Package Management**: Helm 3 charts (`charts/keycloak`, `charts/webapp`, `charts/oauth2-proxy`)
- **CI/CD**: GitHub Actions, Jenkins, Tekton (3 parallel pipelines)
- **Infrastructure as Code**: Terraform (planned expansion from namespace placeholder)
- **Monitoring**: `/metrics` endpoints, Kubernetes HPA on CPU (70%) and memory (80%)

---

## 8. Quality Attributes

| Attribute | Target | Mechanism |
|-----------|--------|-----------|
| Availability | 99.99% | Multi-replica deployments, PodDisruptionBudgets, HPA |
| Scalability | 10,000 concurrent sessions | HPA 3-10 replicas, DragonflyDB session offload |
| Latency | P95 < 200ms (token issuance) | DragonflyDB caching, Keycloak session affinity |
| Security | Zero credential breaches | MFA, short-lived JWTs, TLS everywhere |
| Maintainability | < 1 hour mean time to deploy | CI/CD automation, Helm charts, blue-green deploys |

---

*Document generated by the AIDD pipeline. See architecture.md for infrastructure diagrams and prd.md for component details.*
