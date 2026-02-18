# IDaaS Platform - Project Overview

**Project**: Identity-as-a-Service (IDaaS)
**Version**: 1.0.0
**Last Updated**: 2026-02-17

---

## 1. Introduction

The Identity-as-a-Service (IDaaS) Platform is an enterprise-grade identity and access
management solution that consolidates authentication, authorization, user provisioning,
and security policy enforcement into a single managed service. Built on open-source
foundations (Keycloak, Flask, YugabyteDB) and modern cloud-native principles, the
platform aims to deliver SSO, MFA, federation, and zero-trust capabilities comparable
to commercial providers such as Okta, Auth0, and Microsoft Entra ID.

The platform is designed for multi-tenant SaaS delivery, enabling organizations to
onboard engineering teams, workforce users, and customer-facing applications through
a unified identity fabric that supports modern protocols (OIDC/OAuth2) alongside
legacy systems (LDAP, SAML).

---

## 2. Vision and Goals

| Objective | Description |
|-----------|-------------|
| Developer Experience | SDKs, quickstarts, tenant self-service, API-first design |
| Zero-Trust Security | Device posture, phishing-resistant MFA, continuous risk evaluation |
| Hybrid Compatibility | First-class OIDC/OAuth2 with legacy LDAP and SAML support |
| Global Reliability | 99.99% availability via distributed control planes and failover |
| Compliance & Audit | SOC 2, ISO 27001, GDPR trails with policy versioning and data residency |

---

## 3. Platform Components

### 3.1 Core Services

**Keycloak Identity Provider**
- Multi-tenant realm architecture for tenant isolation
- Authentication flows: OIDC, OAuth2, SAML 2.0, LDAP federation
- Multi-factor authentication: TOTP, WebAuthn/FIDO2 (planned)
- Dynamic client registration and identity brokering
- Fine-grained authorization services with RBAC/ABAC

**Flask Web Application** (`apps/webapp/`)
- Python 3.11 with Flask 3.1.1 framework
- Application factory pattern with environment-based configuration
- Security headers middleware (HSTS, CSP, X-Frame-Options, XSS Protection)
- Kubernetes-ready health endpoints: `/health`, `/readiness`, `/liveness`
- Metrics endpoint at `/metrics` for operational monitoring
- Gunicorn WSGI server for production (4 workers, 2 threads)

**OAuth2 Proxy**
- Reverse proxy enforcing OIDC authentication before reaching the webapp
- Keycloak OIDC provider integration
- Session storage in DragonflyDB (Redis-compatible)
- Forwards identity headers: X-Forwarded-Email, X-Forwarded-User, X-Forwarded-Groups

**MFA Authenticator App** (`apps/mfa-authenticator/`)
- Flutter mobile application (iOS/Android) compatible with Keycloak TOTP
- BLoC state management pattern
- QR code scanning for account enrollment
- Secure storage for TOTP secrets via flutter_secure_storage
- Material Design 3 with light/dark theme support

### 3.2 Data Layer

**YugabyteDB** (Managed DBaaS)
- Distributed SQL database with PostgreSQL wire compatibility
- Stores Keycloak identity, session, consent, and policy data
- xCluster replication for global consistency
- Connection via JDBC: `jdbc:postgresql://endpoint:5433/keycloak?ssl=true`

**DragonflyDB** (Managed DBaaS)
- High-performance in-memory datastore (Redis-compatible, ~25x faster)
- Database 0: Webapp cache
- Database 1: OAuth2 Proxy session storage
- Connection via Redis protocol with SSL/TLS

### 3.3 Infrastructure

**Kubernetes** (Production runtime)
- Namespace `idaas` with ResourceQuota (16 CPU req / 32 CPU limit, 32Gi/64Gi memory)
- LimitRange enforcing per-container bounds (100m-4 CPU, 128Mi-8Gi)
- Deployments: Keycloak (2 replicas), Webapp (3 replicas), OAuth2 Proxy (2 replicas)
- HPA on webapp: 3-10 replicas based on CPU (70%) and memory (80%) utilization
- PodDisruptionBudgets on all deployments
- NetworkPolicy restricting traffic flow between tiers
- RBAC with dedicated ServiceAccount and least-privilege Role

**Ingress**
- NGINX Ingress Controller with TLS termination
- cert-manager with Let's Encrypt ClusterIssuer
- Rate limiting: 100 RPS / 1000 RPM
- Security headers injected at ingress layer
- Session affinity via cookie

**Terraform** (`infra/main.tf`)
- Currently a placeholder for Kubernetes namespace provisioning
- Planned: Full cloud provider infrastructure automation

---

## 4. CI/CD Pipelines

The platform supports three CI/CD systems:

### 4.1 GitHub Actions (`.github/workflows/`)

- **ci.yml**: Test, lint, security scan, Docker build, E2E tests, quality gate
- **deploy.yaml**: Build/push to GHCR, deploy to staging/production via kubectl
- Matrix strategy for parallel image builds
- Automatic rollback on deployment failure

### 4.2 Jenkins (`Jenkinsfile`)

- 10-stage pipeline: Checkout, Lint, Dependency Scan, SAST, Unit Tests,
  Build Images, Container Scan, Integration Tests, Tag/Push, Deploy
- Parallel stages for Helm lint + Python lint, and image builds
- Manual approval gate for production deployment
- Artifact archival for all security reports

### 4.3 Tekton (`tekton/`)

- Kubernetes-native pipeline with 8 tasks
- Reusable task definitions: git-clone, python-test, build-docker-image, security-scan
- Workspace-based data sharing between tasks
- Webhook-triggered automation via TriggerTemplate

---

## 5. Security Posture

### 5.1 Application Security
- Security headers on all responses (HSTS, CSP, X-Frame-Options, etc.)
- Non-root container execution (UID 1000)
- Multi-stage Docker builds minimizing attack surface
- Bandit SAST scanning, Safety dependency scanning
- Trivy container vulnerability scanning
- Flake8 code quality enforcement

### 5.2 Infrastructure Security
- Kubernetes RBAC with dedicated service accounts
- Network policies enforcing tier-based traffic isolation
- Pod security contexts: runAsNonRoot, drop ALL capabilities
- Resource quotas preventing resource exhaustion
- TLS termination at ingress with forced HTTPS redirect

### 5.3 Secrets Management
- Kubernetes Secrets for database credentials, OAuth2 secrets, API keys
- Environment variable injection from Secrets/ConfigMaps
- `.env.example` with CHANGEME placeholders for all sensitive values
- Cookie secret length validation in deployment script

---

## 6. Repository Structure

```
IDaaS2/
├── apps/
│   ├── webapp/           # Flask application (Python 3.11)
│   │   ├── app.py        # Application factory
│   │   ├── config.py     # Configuration classes
│   │   ├── extensions.py # Middleware (logging, security, errors)
│   │   ├── Dockerfile    # Multi-stage production build
│   │   ├── tests/        # Unit tests (pytest)
│   │   └── requirements.txt
│   ├── oauth2-proxy/     # OAuth2 Proxy Dockerfile
│   └── mfa-authenticator/ # Flutter TOTP app
├── charts/               # Helm charts
│   ├── keycloak/
│   ├── webapp/
│   └── oauth2-proxy/
├── k8s/                  # Raw Kubernetes manifests
│   ├── 00-namespace.yaml
│   ├── 01-secrets-configmap.yaml
│   ├── 02-keycloak-deployment.yaml
│   ├── 03-webapp-deployment.yaml
│   ├── 04-oauth2-proxy-deployment.yaml
│   ├── 05-ingress.yaml
│   └── 06-rbac-network-policy.yaml
├── keycloak/             # Realm templates
├── tekton/               # Tekton CI/CD pipeline
├── infra/                # Terraform (placeholder)
├── scripts/              # Security scanning scripts
├── tests/                # E2E tests
├── ops/                  # Runbooks
├── docs/                 # Documentation
├── security-reports/     # Scan output
├── docker-compose.yml    # Base orchestration
├── docker-compose.prod.yml
├── docker-compose.dev.yml
├── docker-compose.ci.yml
├── Jenkinsfile
├── deploy.sh
└── .github/workflows/    # GitHub Actions
```

---

## 7. Getting Started

### Quick Start (Docker Compose)
```bash
git clone https://github.com/your-org/IDaaS2.git
cd IDaaS2
docker-compose up -d

# Access points:
# Keycloak Admin: http://localhost:8080 (admin/admin)
# Webapp via OAuth2 Proxy: http://localhost:4180
# Webapp direct: http://localhost:8081
```

### Development Setup
```bash
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d
cd apps/webapp
pip install -r requirements.txt
pytest tests/ -v
```

### Run Security Scans
```bash
./scripts/run-all-scans.sh
```

---

## 8. API Endpoints

| Endpoint | Method | Auth Required | Description |
|----------|--------|---------------|-------------|
| `/` | GET | No | Main page with authentication status |
| `/health` | GET | No | Health check (status, timestamp, service, version) |
| `/readiness` | GET | No | Kubernetes readiness probe |
| `/liveness` | GET | No | Kubernetes liveness probe |
| `/metrics` | GET | No | Application metrics (name, version, python_version) |
| `/api/user-info` | GET | Yes | Authenticated user details (email, username, groups) |

---

## 9. Technology Stack Summary

| Layer | Technology | Version |
|-------|-----------|---------|
| Language | Python | 3.11 |
| Framework | Flask | 3.1.1 |
| WSGI Server | Gunicorn | 23.0.0 |
| Identity Provider | Keycloak | 23.0 |
| Auth Proxy | OAuth2 Proxy | 7.5.1 |
| SQL Database | YugabyteDB | 2.21.0 (DBaaS) |
| Cache/Sessions | DragonflyDB | 1.15.1 (DBaaS) |
| Container Runtime | Docker | Multi-stage builds |
| Orchestration | Kubernetes | 1.20+ |
| Package Manager | Helm | 3.x |
| CI/CD | GitHub Actions, Jenkins, Tekton | Latest |
| IaC | Terraform | Planned |
| Mobile | Flutter | SDK >=3.0 |
| Security Scanning | Bandit, Safety, Trivy, Flake8 | Latest |
