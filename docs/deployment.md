# Deployment Guide — IDaaS
> Version: 1.0 | Last Updated: 2026-02-18 | Status: Draft
> Classification: Internal | Author: AIDD System

---

## 1. Introduction

This guide covers deployment procedures for the IDaaS platform across all environments:
local development (Docker Compose), staging (Kubernetes), and production (Kubernetes).
It includes prerequisites, step-by-step instructions, validation procedures, and
rollback strategies.

---

## 2. Prerequisites

### 2.1 Tools Required

| Tool | Version | Purpose |
|------|---------|---------|
| Docker | 24+ | Container runtime |
| Docker Compose | 2.24+ | Local orchestration |
| kubectl | 1.28+ | Kubernetes CLI |
| Helm | 3.14+ | Kubernetes package management |
| Python | 3.11+ | Application development |
| Git | 2.40+ | Source control |
| curl / jq | Latest | API testing and JSON parsing |

### 2.2 Access Requirements

| Resource | Access |
|----------|--------|
| Container Registry (GHCR) | Push and pull access |
| Kubernetes Cluster | `kubectl` configured with `idaas` namespace permissions |
| YugabyteDB (DBaaS) | Connection credentials (host, port, username, password) |
| DragonflyDB (DBaaS) | Connection URL with TLS (host, port, password) |
| DNS Provider | Ability to create A/CNAME records |
| Let's Encrypt | Outbound HTTPS access for ACME challenges |

---

## 3. Environment Configuration

### 3.1 Required Environment Variables

```bash
# Keycloak
KEYCLOAK_ADMIN=admin
KEYCLOAK_ADMIN_PASSWORD=<secure-password>
KC_DB=postgres
KC_DB_URL=jdbc:postgresql://<yugabyte-host>:5433/keycloak?ssl=true
KC_DB_USERNAME=<db-username>
KC_DB_PASSWORD=<db-password>
KC_HOSTNAME=auth.example.com

# OAuth2 Proxy
OAUTH2_PROXY_CLIENT_ID=idaas-webapp
OAUTH2_PROXY_CLIENT_SECRET=<client-secret>
OAUTH2_PROXY_COOKIE_SECRET=<32-byte-base64>
OAUTH2_PROXY_OIDC_ISSUER_URL=https://auth.example.com/realms/master

# DragonflyDB
DRAGONFLY_CACHE_URL=rediss://<dragonfly-host>:6379/0
DRAGONFLY_SESSION_URL=rediss://<dragonfly-host>:6379/1

# Flask
FLASK_ENV=production
SECRET_KEY=<secure-random-key>
```

### 3.2 Generating Secrets

```bash
# Generate OAuth2 Proxy cookie secret (32 bytes, base64)
python3 -c "import secrets; print(secrets.token_urlsafe(32))"

# Generate Flask secret key
python3 -c "import secrets; print(secrets.token_hex(32))"
```

---

## 4. Local Development Deployment (Docker Compose)

### 4.1 Starting the Development Environment

```bash
# Clone the repository
git clone <repository-url> && cd IDaaS2

# Start with development overrides
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# Verify services are running
docker compose ps
```

### 4.2 Accessing Services Locally

| Service | URL | Credentials |
|---------|-----|-------------|
| Keycloak Admin | http://localhost:8080/admin | admin / admin (dev only) |
| Web Application | http://localhost:8081 | Via Keycloak login |
| OAuth2 Proxy | http://localhost:4180 | Automatic redirect |

### 4.3 Development Workflow

```bash
# Hot-reload is enabled in dev mode
# Edit files in apps/webapp/ and changes reflect automatically

# Run unit tests
cd apps/webapp && python -m pytest tests/ -v

# Run linting
flake8 apps/webapp/

# Run security scan
bandit -r apps/webapp/ -x tests
```

### 4.4 Stopping the Environment

```bash
docker compose -f docker-compose.yml -f docker-compose.dev.yml down
# Add -v to remove volumes (data will be lost)
```

---

## 5. CI Environment Deployment

### 5.1 Docker Compose CI Configuration

The CI configuration (`docker-compose.ci.yml`) includes local YugabyteDB and
DragonflyDB containers to eliminate external DBaaS dependencies:

```bash
docker compose -f docker-compose.yml -f docker-compose.ci.yml up -d
# Wait for services to be healthy
docker compose -f docker-compose.yml -f docker-compose.ci.yml ps

# Run tests
python -m pytest tests/ -v --junitxml=test-results.xml

# Cleanup
docker compose -f docker-compose.yml -f docker-compose.ci.yml down -v
```

---

## 6. Staging/Production Kubernetes Deployment

### 6.1 Step 1: Create Namespace and RBAC

```bash
kubectl apply -f k8s/00-namespace.yaml
# Creates: namespace, ResourceQuota, LimitRange, ServiceAccount, Role, RoleBinding
```

### 6.2 Step 2: Create Secrets

```bash
kubectl apply -f k8s/01-secrets.yaml
# Or create secrets imperatively:
kubectl create secret generic idaas-secrets -n idaas \
  --from-literal=keycloak-admin-password=<password> \
  --from-literal=db-password=<password> \
  --from-literal=oauth2-client-secret=<secret> \
  --from-literal=cookie-secret=<secret> \
  --from-literal=dragonfly-url=<url>
```

### 6.3 Step 3: Deploy Keycloak

```bash
kubectl apply -f k8s/02-keycloak-deployment.yaml
# Wait for Keycloak to be ready (initial startup takes ~60 seconds)
kubectl rollout status deployment/keycloak -n idaas --timeout=120s
# Verify health
kubectl exec -n idaas deploy/keycloak -- curl -s http://localhost:8080/health/ready
```

### 6.4 Step 4: Deploy OAuth2 Proxy

```bash
kubectl apply -f k8s/03-oauth2-proxy-deployment.yaml
kubectl rollout status deployment/oauth2-proxy -n idaas --timeout=60s
```

### 6.5 Step 5: Deploy Flask Webapp

```bash
kubectl apply -f k8s/04-webapp-deployment.yaml
kubectl rollout status deployment/webapp -n idaas --timeout=60s
```

### 6.6 Step 6: Apply Network Policies

```bash
kubectl apply -f k8s/05-network-policies.yaml
```

### 6.7 Step 7: Configure Ingress

```bash
kubectl apply -f k8s/06-ingress.yaml
# Verify TLS certificate provisioning
kubectl get certificate -n idaas
# Wait for certificate to be ready
kubectl wait --for=condition=ready certificate/idaas-tls -n idaas --timeout=120s
```

### 6.8 Step 8: Apply HPA

```bash
kubectl apply -f k8s/07-hpa.yaml
# Verify HPA status
kubectl get hpa -n idaas
```

---

## 7. Helm Chart Deployment (Alternative)

```bash
# Deploy Keycloak
helm upgrade --install keycloak charts/keycloak \
  -n idaas --create-namespace \
  -f charts/keycloak/values.yaml \
  --set db.url=<yugabyte-url> \
  --set db.password=<password>

# Deploy OAuth2 Proxy
helm upgrade --install oauth2-proxy charts/oauth2-proxy \
  -n idaas \
  -f charts/oauth2-proxy/values.yaml

# Deploy Webapp
helm upgrade --install webapp charts/webapp \
  -n idaas \
  -f charts/webapp/values.yaml
```

---

## 8. Post-Deployment Validation

### 8.1 Health Check Validation

```bash
# Keycloak health
curl -s https://auth.example.com/health/ready | jq .
# Expected: {"status": "UP"}

# Flask health
curl -s https://app.example.com/health | jq .
# Expected: {"status": "healthy"}

# OAuth2 Proxy (should redirect to Keycloak)
curl -s -o /dev/null -w "%{http_code}" https://app.example.com/
# Expected: 302 (redirect to auth)
```

### 8.2 Authentication Flow Validation

1. Open `https://app.example.com` in a browser
2. Verify redirect to Keycloak login page
3. Authenticate with valid credentials
4. Verify MFA prompt (if enabled)
5. Verify successful redirect to application
6. Verify identity headers are populated (check page content)

### 8.3 Kubernetes Verification

```bash
# All pods running
kubectl get pods -n idaas
# Expected: All pods STATUS=Running, READY=1/1 or 2/2

# Services resolving
kubectl get svc -n idaas

# Ingress configured
kubectl get ingress -n idaas

# HPA active
kubectl get hpa -n idaas

# PDB configured
kubectl get pdb -n idaas
```

---

## 9. Rollback Procedures

### 9.1 Kubernetes Rollback

```bash
# View deployment history
kubectl rollout history deployment/webapp -n idaas

# Rollback to previous revision
kubectl rollout undo deployment/webapp -n idaas

# Rollback to specific revision
kubectl rollout undo deployment/webapp -n idaas --to-revision=2

# Verify rollback
kubectl rollout status deployment/webapp -n idaas
```

### 9.2 Helm Rollback

```bash
# View release history
helm history webapp -n idaas

# Rollback to previous release
helm rollback webapp -n idaas

# Rollback to specific revision
helm rollback webapp 2 -n idaas
```

---

## 10. Production Deployment Checklist

| # | Item | Verified |
|---|------|----------|
| 1 | All secrets created and encrypted at rest | [ ] |
| 2 | TLS certificates provisioned and valid | [ ] |
| 3 | DNS records pointing to ingress IP | [ ] |
| 4 | YugabyteDB connectivity verified | [ ] |
| 5 | DragonflyDB connectivity verified | [ ] |
| 6 | Keycloak admin console accessible | [ ] |
| 7 | Keycloak realm configured with production settings | [ ] |
| 8 | OAuth2 Proxy client registered in Keycloak | [ ] |
| 9 | Authentication flow tested end-to-end | [ ] |
| 10 | MFA enforcement validated | [ ] |
| 11 | HPA scaling verified | [ ] |
| 12 | NetworkPolicies applied | [ ] |
| 13 | PodDisruptionBudgets configured | [ ] |
| 14 | Rate limiting tested | [ ] |
| 15 | Security headers validated | [ ] |
| 16 | Monitoring and alerting configured | [ ] |
| 17 | Backup and recovery tested | [ ] |
| 18 | Rollback procedure tested | [ ] |

---

*Document generated by the AIDD pipeline. Deployment steps derived from k8s/, charts/, and docker-compose configurations.*
