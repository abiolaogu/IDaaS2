# Low-Level Design (LLD) — IDaaS
> Version: 1.0 | Last Updated: 2026-02-18 | Status: Draft
> Classification: Internal | Author: AIDD System

---

## 1. Introduction

This Low-Level Design document provides implementation-level detail for each IDaaS
component, including class structures, API specifications, configuration details,
container specifications, and Kubernetes resource definitions.

---

## 2. Flask Web Application - Detailed Design

### 2.1 Application Factory Pattern

```python
# apps/webapp/app.py
def create_app(config_name=None):
    """Application factory with environment-based configuration."""
    if config_name is None:
        config_name = os.environ.get('FLASK_ENV', 'development')

    app = Flask(__name__)
    app.config.from_object(config_map[config_name])

    # Initialize extensions
    register_extensions(app)
    register_blueprints(app)
    register_error_handlers(app)

    return app
```

### 2.2 Configuration Classes

```python
# apps/webapp/config.py
class BaseConfig:
    SECRET_KEY = os.environ.get('SECRET_KEY', 'change-me')
    OIDC_ISSUER = os.environ.get('OIDC_ISSUER_URL')
    DRAGONFLY_URL = os.environ.get('DRAGONFLY_CACHE_URL')

class DevelopmentConfig(BaseConfig):
    DEBUG = True
    TESTING = False

class TestingConfig(BaseConfig):
    DEBUG = False
    TESTING = True

class ProductionConfig(BaseConfig):
    DEBUG = False
    TESTING = False
    SESSION_COOKIE_SECURE = True
    SESSION_COOKIE_HTTPONLY = True
    SESSION_COOKIE_SAMESITE = 'Lax'
```

### 2.3 Security Middleware Pipeline

```python
# apps/webapp/extensions.py - Security headers middleware
@app.after_request
def set_security_headers(response):
    response.headers['Strict-Transport-Security'] = 'max-age=31536000; includeSubDomains'
    response.headers['Content-Security-Policy'] = "default-src 'self'"
    response.headers['X-Frame-Options'] = 'DENY'
    response.headers['X-Content-Type-Options'] = 'nosniff'
    response.headers['X-XSS-Protection'] = '1; mode=block'
    response.headers['Referrer-Policy'] = 'strict-origin-when-cross-origin'
    return response
```

### 2.4 Route Definitions

| Route | Method | Handler | Auth Required | Description |
|-------|--------|---------|---------------|-------------|
| `/` | GET | `index()` | Yes (via OAuth2 Proxy) | Main dashboard |
| `/health` | GET | `health_check()` | No | K8s health probe |
| `/readiness` | GET | `readiness_check()` | No | K8s readiness probe |
| `/liveness` | GET | `liveness_check()` | No | K8s liveness probe |
| `/metrics` | GET | `metrics()` | No | Prometheus metrics |

### 2.5 Identity Header Processing

```python
def get_current_user():
    """Extract user identity from OAuth2 Proxy forwarded headers."""
    return {
        'email': request.headers.get('X-Forwarded-Email', ''),
        'username': request.headers.get('X-Forwarded-User', ''),
        'groups': request.headers.get('X-Forwarded-Groups', '').split(','),
        'access_token': request.headers.get('X-Forwarded-Access-Token', '')
    }
```

---

## 3. Keycloak Configuration - Detailed Design

### 3.1 Realm Configuration

```json
{
  "realm": "idaas-tenant",
  "enabled": true,
  "sslRequired": "external",
  "registrationAllowed": false,
  "verifyEmail": true,
  "loginTheme": "idaas",
  "accessTokenLifespan": 300,
  "ssoSessionIdleTimeout": 1800,
  "ssoSessionMaxLifespan": 36000,
  "offlineSessionIdleTimeout": 2592000,
  "bruteForceProtected": true,
  "permanentLockout": false,
  "maxFailureWaitSeconds": 900,
  "minimumQuickLoginWaitSeconds": 60,
  "waitIncrementSeconds": 60,
  "quickLoginCheckMilliSeconds": 1000,
  "maxDeltaTimeSeconds": 43200,
  "failureFactor": 5,
  "passwordPolicy": "length(12) and upperCase(1) and lowerCase(1) and digits(1) and specialChars(1) and notUsername and passwordHistory(5)"
}
```

### 3.2 OIDC Client Definition

```json
{
  "clientId": "idaas-webapp",
  "name": "IDaaS Web Application",
  "protocol": "openid-connect",
  "publicClient": false,
  "directAccessGrantsEnabled": false,
  "serviceAccountsEnabled": false,
  "authorizationServicesEnabled": true,
  "redirectUris": ["https://app.example.com/oauth2/callback"],
  "webOrigins": ["https://app.example.com"],
  "defaultClientScopes": ["openid", "email", "profile", "roles"],
  "optionalClientScopes": ["offline_access", "microprofile-jwt"],
  "attributes": {
    "pkce.code.challenge.method": "S256",
    "post.logout.redirect.uris": "https://app.example.com/*",
    "backchannel.logout.url": "https://app.example.com/oauth2/sign_out"
  }
}
```

### 3.3 Authentication Flow Configuration

```
Browser Flow:
  1. Cookie (check existing session)
  2. Identity Provider Redirector (optional external IdP)
  3. Forms:
     a. Username/Password Form
     b. Conditional OTP:
        - Condition: User configured OTP
        - OTP Form (TOTP 6-digit code)
     c. WebAuthn Authenticator (planned):
        - Condition: User registered FIDO2 key
        - WebAuthn challenge/response
```

### 3.4 RBAC Role Hierarchy

```
Realm Roles:
├── platform-admin        (full platform management)
├── tenant-admin          (realm-level management)
├── user-manager          (user CRUD within realm)
├── app-developer         (client registration, SDK access)
├── auditor               (read-only audit logs)
└── end-user              (standard authentication)

Client Roles (idaas-webapp):
├── manage-users          (user administration APIs)
├── manage-clients        (client registration APIs)
├── view-reports          (analytics and audit reports)
└── manage-realm          (realm configuration)
```

---

## 4. OAuth2 Proxy - Detailed Configuration

### 4.1 Environment Variables

```yaml
OAUTH2_PROXY_PROVIDER: keycloak-oidc
OAUTH2_PROXY_PROVIDER_DISPLAY_NAME: "IDaaS Login"
OAUTH2_PROXY_OIDC_ISSUER_URL: http://keycloak:8080/realms/idaas-tenant
OAUTH2_PROXY_CLIENT_ID: idaas-webapp
OAUTH2_PROXY_CLIENT_SECRET: ${OAUTH2_CLIENT_SECRET}
OAUTH2_PROXY_REDIRECT_URL: https://app.example.com/oauth2/callback
OAUTH2_PROXY_UPSTREAMS: http://webapp:8080
OAUTH2_PROXY_SESSION_STORE_TYPE: redis
OAUTH2_PROXY_REDIS_CONNECTION_URL: ${DRAGONFLY_SESSION_URL}
OAUTH2_PROXY_COOKIE_SECRET: ${COOKIE_SECRET}     # 32-byte base64
OAUTH2_PROXY_COOKIE_SECURE: "true"
OAUTH2_PROXY_COOKIE_HTTPONLY: "true"
OAUTH2_PROXY_COOKIE_SAMESITE: "lax"
OAUTH2_PROXY_EMAIL_DOMAINS: "*"
OAUTH2_PROXY_PASS_ACCESS_TOKEN: "true"
OAUTH2_PROXY_SET_XAUTHREQUEST: "true"
OAUTH2_PROXY_SKIP_PROVIDER_BUTTON: "true"
OAUTH2_PROXY_CODE_CHALLENGE_METHOD: "S256"
```

---

## 5. Container Specifications

### 5.1 Flask Webapp Dockerfile

```dockerfile
# Multi-stage build
FROM python:3.11-slim AS builder
WORKDIR /build
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

FROM python:3.11-slim AS runtime
RUN groupadd -r appuser && useradd -r -g appuser -d /app appuser
WORKDIR /app
COPY --from=builder /install /usr/local
COPY . .
RUN chown -R appuser:appuser /app
USER appuser
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s CMD curl -f http://localhost:8080/health || exit 1
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "4", "--threads", "2", "app:create_app()"]
```

### 5.2 Container Security Context

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  runAsGroup: 1000
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  capabilities:
    drop: [ALL]
  seccompProfile:
    type: RuntimeDefault
```

---

## 6. Kubernetes Resource Definitions

### 6.1 Webapp Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
  namespace: idaas
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: webapp
  template:
    spec:
      serviceAccountName: idaas-sa
      containers:
      - name: webapp
        image: ghcr.io/org/idaas-webapp:latest
        ports:
        - containerPort: 8080
        resources:
          requests: { cpu: 200m, memory: 256Mi }
          limits: { cpu: 1000m, memory: 1Gi }
        livenessProbe:
          httpGet: { path: /liveness, port: 8080 }
          initialDelaySeconds: 10
          periodSeconds: 30
        readinessProbe:
          httpGet: { path: /readiness, port: 8080 }
          initialDelaySeconds: 5
          periodSeconds: 10
        env:
        - name: FLASK_ENV
          value: production
        - name: OIDC_ISSUER_URL
          valueFrom:
            secretKeyRef: { name: idaas-secrets, key: oidc-issuer-url }
```

### 6.2 HPA Configuration

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: webapp-hpa
  namespace: idaas
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: webapp
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target: { type: Utilization, averageUtilization: 70 }
  - type: Resource
    resource:
      name: memory
      target: { type: Utilization, averageUtilization: 80 }
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
      - type: Pods
        value: 2
        periodSeconds: 60
    scaleDown:
      stabilizationWindowSeconds: 300
```

### 6.3 NetworkPolicy

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: webapp-netpol
  namespace: idaas
spec:
  podSelector:
    matchLabels:
      app: webapp
  policyTypes: [Ingress, Egress]
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: oauth2-proxy
    ports:
    - port: 8080
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: keycloak
    ports:
    - port: 8080
  - to: []  # Allow external DB connections
    ports:
    - port: 5433
    - port: 6379
```

---

## 7. MFA Authenticator App - Detailed Design

### 7.1 BLoC Architecture

```
lib/
├── main.dart                    # App entry point
├── bloc/
│   ├── auth_bloc.dart           # Authentication state management
│   ├── totp_bloc.dart           # TOTP generation state
│   └── account_bloc.dart        # Account management state
├── models/
│   ├── totp_account.dart        # TOTP account data model
│   └── totp_code.dart           # Generated code model
├── screens/
│   ├── home_screen.dart         # Account list with TOTP codes
│   ├── scan_screen.dart         # QR code scanner
│   └── settings_screen.dart     # App settings
├── services/
│   ├── totp_service.dart        # RFC 6238 TOTP generation
│   ├── secure_storage.dart      # flutter_secure_storage wrapper
│   └── qr_scanner_service.dart  # Camera QR code scanning
└── widgets/
    ├── totp_card.dart           # Individual TOTP display widget
    └── countdown_timer.dart     # 30-second countdown indicator
```

### 7.2 TOTP Generation (RFC 6238)

```dart
String generateTOTP(String secret, {int period = 30, int digits = 6}) {
  final time = DateTime.now().millisecondsSinceEpoch ~/ 1000 ~/ period;
  final timeBytes = _int64ToBytes(time);
  final key = base32Decode(secret);
  final hmac = Hmac(sha1, key).convert(timeBytes);
  final offset = hmac.bytes[hmac.bytes.length - 1] & 0x0F;
  final code = ((hmac.bytes[offset] & 0x7F) << 24 |
                (hmac.bytes[offset + 1] & 0xFF) << 16 |
                (hmac.bytes[offset + 2] & 0xFF) << 8 |
                (hmac.bytes[offset + 3] & 0xFF)) % pow(10, digits);
  return code.toString().padLeft(digits, '0');
}
```

---

*Document generated by the AIDD pipeline. Implementation references from apps/webapp/, keycloak/, and k8s/ directories.*
