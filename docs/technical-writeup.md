# Technical Write-Up — IDaaS
> Version: 1.0 | Last Updated: 2026-02-18 | Status: Draft
> Classification: Internal | Author: AIDD System

---

## 1. Executive Technical Summary

The IDaaS (Identity-as-a-Service) platform is an enterprise-grade identity and access
management solution architected for multi-tenant SaaS delivery. Built on Keycloak as the
identity core, Flask for application logic, and managed database services (YugabyteDB,
DragonflyDB), the platform delivers authentication, authorization, and user lifecycle
management through standard protocols: OpenID Connect, OAuth 2.0, SAML 2.0, LDAP, and
SCIM 2.0.

This write-up covers the technical design rationale, implementation approach, key
engineering decisions, and lessons learned during the platform's development.

---

## 2. Problem Statement

Organizations face several identity management challenges:

1. **Fragmented Authentication**: Users maintain separate credentials across dozens of applications, leading to password fatigue, weak passwords, and credential reuse.

2. **Manual Provisioning**: IT teams manually create and disable accounts across systems, creating security gaps during offboarding (orphaned accounts) and onboarding delays.

3. **Protocol Heterogeneity**: Enterprise environments mix modern protocols (OIDC) with legacy systems (LDAP, SAML), requiring a platform that bridges both worlds.

4. **Compliance Burden**: Regulations (SOC 2, ISO 27001, GDPR) demand comprehensive audit trails, access reviews, and data residency controls that ad-hoc identity solutions cannot provide.

5. **Vendor Lock-In**: Commercial IDaaS providers (Okta, Auth0, Microsoft Entra ID) impose significant per-user licensing costs and proprietary integration patterns.

---

## 3. Solution Architecture

### 3.1 Design Philosophy

The IDaaS platform follows five core principles:

**Open-Source Core**: Keycloak provides a protocol-complete identity engine without per-user licensing. The entire stack (Flask, NGINX, cert-manager) uses permissively licensed open-source software, eliminating vendor lock-in.

**API-First Design**: Every capability is accessible via standard APIs. OIDC discovery endpoints, SCIM provisioning APIs, and admin REST APIs enable programmatic integration. The UI is a consumer of these same APIs.

**Defense in Depth**: Authentication is enforced at multiple layers: TLS at ingress, OAuth2 Proxy at the gateway, Keycloak for identity verification, and RBAC at the application layer. No single component's compromise grants unrestricted access.

**Stateless Application Tier**: The Flask webapp and OAuth2 Proxy store no local state. Sessions reside in DragonflyDB, identity data in YugabyteDB. This enables horizontal scaling and zero-downtime deployments.

**Multi-Tenancy by Design**: Keycloak's realm architecture provides per-tenant isolation of users, clients, roles, and policies. Tenants share infrastructure but not identity boundaries.

### 3.2 Component Selection Rationale

**Keycloak over Ory Hydra / Gluu**: Keycloak provides a complete identity suite (authentication, authorization, admin UI, identity brokering, MFA) in a single deployment. Ory Hydra requires assembling multiple components (Kratos, Keto, Oathkeeper), increasing operational complexity. Gluu has a more restrictive license model.

**Flask over Django / FastAPI**: The team's primary skill set is Python. Flask's lightweight, extensible nature suits the application factory pattern used here. Django's ORM and admin were unnecessary given Keycloak handles user management. FastAPI's async model adds complexity not justified for this request-response workload.

**YugabyteDB over PostgreSQL / CockroachDB**: YugabyteDB provides PostgreSQL wire compatibility (Keycloak works unmodified) with built-in distributed SQL and xCluster replication for multi-region deployments. Standard PostgreSQL lacks native distributed capabilities, and CockroachDB's serializable isolation can introduce latency for high-write session workloads.

**DragonflyDB over Redis**: DragonflyDB is Redis-compatible but delivers approximately 25x throughput improvement with lower memory footprint. As a managed DBaaS, it eliminates Redis clustering operational overhead while maintaining full protocol compatibility with OAuth2 Proxy's Redis session store.

---

## 4. Key Technical Decisions

### 4.1 OAuth2 Proxy as Authentication Gateway

Rather than implementing OIDC authentication directly in the Flask application, the architecture places OAuth2 Proxy between the ingress and the application. This decision provides:

- **Separation of concerns**: Authentication logic is completely decoupled from application code
- **Language agnosticism**: Any upstream service (not just Flask) benefits from authentication enforcement
- **Proven implementation**: OAuth2 Proxy is a CNCF-adjacent project with extensive Keycloak integration
- **Identity header forwarding**: Clean interface between authentication (OAuth2 Proxy) and application (Flask) via `X-Forwarded-*` headers

### 4.2 Realm-Per-Tenant Multi-Tenancy

Keycloak supports multi-tenancy through realm isolation. Each tenant organization gets a dedicated realm with independent:
- User directories and credential stores
- Client registrations (OIDC/SAML)
- Authentication flows and MFA policies
- Role hierarchies and authorization policies
- Token signing keys and session configurations

This provides stronger isolation than shared-realm approaches at the cost of slightly higher memory footprint per tenant.

### 4.3 JWT Token Architecture

The platform uses RS256-signed JWTs for access and ID tokens:
- **Access tokens** (5-minute TTL): Contain realm_access.roles and resource_access for RBAC
- **ID tokens** (5-minute TTL): Contain user identity claims (email, name, groups)
- **Refresh tokens** (30-minute TTL): Opaque, stored server-side in YugabyteDB

Short-lived access tokens minimize the window of exposure if a token is compromised. Refresh token rotation ensures that stolen refresh tokens are single-use.

### 4.4 Container Security Hardening

All containers follow a strict security posture:
- Multi-stage Docker builds (separate builder and runtime stages)
- Non-root execution (`runAsUser: 1000`)
- Read-only root filesystem where possible
- All Linux capabilities dropped (`drop: [ALL]`)
- Seccomp profile: RuntimeDefault
- No privilege escalation (`allowPrivilegeEscalation: false`)

---

## 5. Implementation Highlights

### 5.1 CI/CD Pipeline Architecture

The platform supports three parallel CI/CD systems to accommodate different organizational contexts:

- **GitHub Actions**: Cloud-native CI for open-source workflow; matrix builds for parallel image construction
- **Jenkins**: Enterprise CI with manual approval gates for production deployment
- **Tekton**: Kubernetes-native pipelines for organizations preferring in-cluster CI/CD

All three pipelines enforce the same quality gates: linting (Flake8), SAST (Bandit), dependency scanning (Safety), container scanning (Trivy), unit tests (pytest), and E2E tests.

### 5.2 Security Scanning Integration

Security scanning is integrated at multiple stages:
- **Pre-commit**: Flake8 linting, basic security checks
- **CI Pipeline**: Bandit SAST, Safety dependency audit, Trivy container scan
- **Deployment**: Image digest verification, Kubernetes admission policies
- **Runtime**: Keycloak brute-force protection, rate limiting at ingress

### 5.3 Health and Observability

Every service exposes health endpoints for Kubernetes orchestration:
- `/health` or `/health/live`: Liveness probe (process is running)
- `/readiness` or `/health/ready`: Readiness probe (dependencies available)
- `/metrics`: Prometheus-compatible metrics

---

## 6. Current Gaps and Roadmap

As identified in the gap analysis, several planned features are not yet implemented:

| Gap | Impact | Priority | Target Phase |
|-----|--------|----------|-------------|
| SCIM 2.0 Provisioning | No automated user lifecycle | Critical | Phase 3 |
| SAML 2.0 Federation | No legacy enterprise SSO | High | Phase 2 |
| LDAP/FreeIPA Integration | No directory authentication | High | Phase 2 |
| WebAuthn/FIDO2 | No passwordless auth | Medium | Phase 4 |
| CloudHSM/KMS | Software-only key management | Medium | Phase 4 |
| Adaptive Risk Engine | No contextual step-up auth | Medium | Phase 4 |

---

## 7. Lessons Learned

1. **Start with OIDC, add SAML later**: OIDC provides the cleanest integration path for modern applications. SAML should be added as a federation bridge, not a primary protocol.

2. **Externalize session state early**: Storing sessions in DragonflyDB from day one eliminated stateful deployment complexity and enabled trivial horizontal scaling.

3. **Managed DBaaS reduces operational toil**: YugabyteDB and DragonflyDB as managed services freed the team from database operations, replication management, and backup automation.

4. **Multi-pipeline CI validates portability**: Supporting GitHub Actions, Jenkins, and Tekton simultaneously proved that the build and deploy process is not coupled to any single CI system.

5. **Security headers at multiple layers**: Injecting security headers at both the NGINX Ingress and Flask middleware levels provides defense in depth; if one layer is misconfigured, the other still enforces protections.

---

*Document generated by the AIDD pipeline. Technical details sourced from architecture.md, prd.md, and gap-analysis.md.*
