# IDaaS Platform - Architecture Document

**Project**: Identity-as-a-Service (IDaaS)
**Version**: 1.0.0
**Last Updated**: 2026-02-17

---

## 1. Architecture Overview

The IDaaS platform follows a layered, microservices-oriented architecture deployed
on Kubernetes. Traffic flows from external clients through an NGINX Ingress controller,
into an OAuth2 Proxy authentication gateway, which delegates identity verification to
Keycloak before forwarding authenticated requests to the Flask web application.
Persistent state is managed by external DBaaS providers (YugabyteDB for SQL,
DragonflyDB for caching and sessions).

```
                         ┌─────────────────────┐
                         │   External Clients   │
                         │  (Browser, Mobile,   │
                         │   API, SaaS Apps)    │
                         └──────────┬───────────┘
                                    │
                         ┌──────────▼───────────┐
                         │   NGINX Ingress      │
                         │   (TLS Termination,  │
                         │    Rate Limiting,     │
                         │    Security Headers)  │
                         └──────────┬───────────┘
                                    │
               ┌────────────────────┼────────────────────┐
               │                    │                     │
    ┌──────────▼──────────┐  ┌─────▼──────────┐         │
    │   auth.example.com  │  │ app.example.com │         │
    │                     │  │                 │         │
    │     Keycloak        │  │  OAuth2 Proxy   │         │
    │   (Identity         │  │  (Auth Gateway) │         │
    │    Provider)        │  │                 │         │
    │   Port: 8080        │  │  Port: 4180     │         │
    └──────────┬──────────┘  └────────┬────────┘         │
               │                      │                   │
               │              ┌───────▼────────┐         │
               │              │   Flask Webapp  │         │
               │              │   (Application) │         │
               │              │   Port: 8080    │         │
               │              └───────┬─────────┘         │
               │                      │                   │
    ┌──────────▼──────────────────────▼───────────────────▼─┐
    │                     Data Layer                         │
    │  ┌──────────────────┐    ┌──────────────────────────┐ │
    │  │   YugabyteDB     │    │     DragonflyDB          │ │
    │  │   (SQL - DBaaS)  │    │   (Cache/Sessions-DBaaS) │ │
    │  │   Port: 5433     │    │   Port: 6379             │ │
    │  └──────────────────┘    └──────────────────────────┘ │
    └───────────────────────────────────────────────────────┘
```

---

## 2. Component Architecture

### 2.1 Identity Provider Layer (Keycloak)

Keycloak operates as the central identity broker providing:

**Authentication Protocols**:
- OpenID Connect (OIDC) for modern web, mobile, SPA, and API clients
- OAuth 2.0 authorization code, client credentials, device authorization flows
- SAML 2.0 for enterprise federation and legacy SSO (planned)
- LDAP v3 bindings for directory-based authentication (planned)

**Multi-Tenancy**:
- Realm-per-tenant isolation model
- Each realm has independent client registrations, users, roles, and policies
- Tenant-scoped Kubernetes namespace deployments
- Logically separated LDAP organizational units per tenant (planned)

**Deployment Configuration**:
```yaml
# From k8s/02-keycloak-deployment.yaml
replicas: 2
resources:
  requests: { cpu: 500m, memory: 1Gi }
  limits: { cpu: 2000m, memory: 2Gi }
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  allowPrivilegeEscalation: false
  capabilities: { drop: [ALL] }
```

**Health Probes**:
- Liveness: `GET /health/live` (initialDelay: 60s, period: 30s)
- Readiness: `GET /health/ready` (initialDelay: 30s, period: 10s)
- Session affinity: ClientIP with 3-hour timeout

### 2.2 Authentication Gateway (OAuth2 Proxy)

OAuth2 Proxy sits between the Ingress and the Flask webapp, enforcing that all
requests to `app.example.com` are authenticated via Keycloak OIDC.

**Flow**:
1. Unauthenticated request arrives at OAuth2 Proxy
2. OAuth2 Proxy redirects to Keycloak OIDC authorization endpoint
3. User authenticates with Keycloak (username/password, MFA)
4. Keycloak issues authorization code, OAuth2 Proxy exchanges for tokens
5. OAuth2 Proxy sets session cookie, stores session in DragonflyDB
6. OAuth2 Proxy forwards request to webapp with identity headers:
   - `X-Forwarded-Email`: User email
   - `X-Forwarded-User`: Username
   - `X-Forwarded-Groups`: Group memberships

**Configuration** (from `docker-compose.yml`):
```yaml
OAUTH2_PROXY_PROVIDER: keycloak-oidc
OAUTH2_PROXY_OIDC_ISSUER_URL: http://keycloak:8080/realms/master
OAUTH2_PROXY_UPSTREAMS: http://webapp:8080
OAUTH2_PROXY_SESSION_STORE_TYPE: redis
OAUTH2_PROXY_REDIS_CONNECTION_URL: ${DRAGONFLY_SESSION_URL}
```

### 2.3 Application Layer (Flask Webapp)

**Application Factory** (`apps/webapp/app.py`):
```python
def create_app(config_name=None):
    if config_name is None:
        config_name = os.environ.get('FLASK_ENV', 'development')
    app = Flask(__name__)
    app.config.from_object(config.get(config_name, config['default']))
    setup_logging(app)
    setup_security_headers(app)
    setup_request_logging(app)
    setup_error_handlers(app)
    app.register_blueprint(main_bp)
    return app
```

**Middleware Stack** (applied via `extensions.py`):
1. **Logging**: Structured request/response logging with timing
2. **Security Headers**: HSTS, CSP, X-Frame-Options, X-Content-Type-Options, XSS-Protection
3. **Error Handlers**: JSON responses for 404, 500, and unhandled exceptions

**Configuration Classes** (`config.py`):
- `DevelopmentConfig`: DEBUG=True, LOG_LEVEL=DEBUG
- `TestingConfig`: TESTING=True, DEBUG=True
- `ProductionConfig`: SECRET_KEY validation enforced

### 2.4 Data Layer

**YugabyteDB (PostgreSQL-compatible)**:
- Used exclusively by Keycloak for identity, credential, session, and consent storage
- Connection string: `jdbc:postgresql://host:5433/keycloak?ssl=true&sslmode=require`
- Globally replicated via xCluster for multi-region consistency

**DragonflyDB (Redis-compatible)**:
- Database 0: Webapp application cache
- Database 1: OAuth2 Proxy session storage
- ~25x performance improvement over standard Redis
- Connection: `redis://:password@host:6379/{db}?ssl=true`

---

## 3. Kubernetes Architecture

### 3.1 Namespace and Resource Management

```yaml
# 00-namespace.yaml
Namespace: idaas
ResourceQuota:
  requests.cpu: "16"
  requests.memory: 32Gi
  limits.cpu: "32"
  limits.memory: 64Gi
  persistentvolumeclaims: "10"
LimitRange:
  Container max: 4 CPU, 8Gi
  Container min: 100m CPU, 128Mi
  Container default: 500m CPU, 512Mi
```

### 3.2 Network Architecture

**Ingress** (`05-ingress.yaml`):
- NGINX Ingress Controller with TLS via cert-manager (Let's Encrypt)
- Two hosts: `app.example.com` -> OAuth2 Proxy, `auth.example.com` -> Keycloak
- Rate limiting: 100 req/s, 1000 req/min
- Session affinity cookies with 24-hour expiry

**Network Policies** (`06-rbac-network-policy.yaml`):
- Frontend (webapp) pods accept ingress only from gateway (OAuth2 Proxy) tier
- Frontend pods can egress to backend (Keycloak) tier on port 8080
- DNS egress allowed (TCP/UDP 53) for service discovery
- External egress allowed for HTTPS (443), Redis (6379), YugabyteDB (5433)

### 3.3 Scaling Strategy

**Horizontal Pod Autoscaler** (webapp):
```yaml
minReplicas: 3
maxReplicas: 10
metrics:
  - cpu: averageUtilization 70%
  - memory: averageUtilization 80%
scaleDown:
  stabilizationWindowSeconds: 300
  maxScaleDownPercent: 50% per 60s
scaleUp:
  stabilizationWindowSeconds: 0
  maxScaleUpPercent: 100% per 30s or 2 pods per 30s
```

**PodDisruptionBudgets**:
- Keycloak: minAvailable 1
- Webapp: minAvailable 2
- OAuth2 Proxy: minAvailable 1

---

## 4. Security Architecture

### 4.1 Defense in Depth

```
Layer 1: NGINX Ingress (TLS, rate limiting, security headers)
Layer 2: OAuth2 Proxy (OIDC authentication enforcement)
Layer 3: Keycloak (MFA, adaptive policies, token issuance)
Layer 4: Flask App (security headers, input validation)
Layer 5: Kubernetes (RBAC, NetworkPolicy, SecurityContext)
Layer 6: Data Layer (encrypted connections, managed DBaaS)
```

### 4.2 Token Flow

1. Client initiates login -> Keycloak issues JWT access token + refresh token
2. Access token contains: sub, email, preferred_username, realm_access.roles
3. OAuth2 Proxy validates token signature against Keycloak JWKS endpoint
4. OAuth2 Proxy extracts claims and forwards as HTTP headers
5. Flask webapp reads headers to determine authentication state
6. Token refresh handled transparently by OAuth2 Proxy

### 4.3 Secret Management

All secrets are stored in Kubernetes `Secret` resources (`01-secrets-configmap.yaml`):
- YugabyteDB credentials (URL, username, password)
- DragonflyDB connection URLs
- Keycloak admin credentials
- Webapp SECRET_KEY
- OAuth2 client ID, client secret, cookie secret

ConfigMaps store non-sensitive configuration:
- Keycloak hostname, proxy mode, log level
- Webapp Flask environment, log level, app version
- OAuth2 Proxy provider, issuer URL, redirect URL

---

## 5. Deployment Architecture

### 5.1 Environments

| Environment | Tool | Database | Notes |
|-------------|------|----------|-------|
| Development | docker-compose + dev overlay | DBaaS (dev instance) | Hot-reload, debug |
| CI/Testing | docker-compose + CI overlay | Local YugabyteDB + DragonflyDB | Isolated |
| Staging | Kubernetes (k8s manifests) | DBaaS (staging) | Production-like |
| Production | Kubernetes (k8s manifests) | DBaaS (production) | Full HA |

### 5.2 Container Images

| Image | Base | Port | Health Check |
|-------|------|------|-------------|
| idaas-webapp | python:3.11-slim | 8080 | GET /health |
| idaas-keycloak | Keycloak 23.0 | 8080/8443 | GET /health/ready |
| idaas-oauth2-proxy | OAuth2 Proxy 7.5.1-alpine | 4180 | GET /ping |

### 5.3 Rolling Update Strategy

All deployments use RollingUpdate strategy:
- `maxSurge: 1` - One extra pod during update
- `maxUnavailable: 0` - Zero downtime during rollout

---

## 6. Planned Architecture Extensions

### 6.1 SCIM Provisioning Service
- Microservice for automated user/group lifecycle management
- Event-driven architecture for downstream SaaS synchronization
- SCIM 2.0 REST API endpoints

### 6.2 API Gateway (Kong/Istio)
- JWT validation at gateway layer
- Rate limiting, throttling, circuit breaking
- API versioning and traffic management

### 6.3 Observability Stack
- OpenTelemetry instrumentation across all services
- Prometheus metrics with Grafana dashboards
- Loki/EFK log aggregation with SIEM forwarding
- Distributed tracing with Jaeger/Tempo

### 6.4 HSM/KMS Integration
- CloudHSM-backed signing keys for Keycloak JWKS
- Automated key rotation with kid versioning
- mTLS certificate management
