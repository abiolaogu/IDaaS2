# Identity as a Service (IDaaS) Platform Blueprint

This document describes the SaaS Identity-as-a-Service platform for the organization. It consolidates the existing technical stack defined in the original architecture deck and expands it with best-in-class design principles used by leading providers such as Okta, Auth0, ForgeRock, Ping Identity, and Azure Entra ID.

## Vision and Goals

| Objective | Description |
|-----------|-------------|
| Developer Experience | Provide SDKs, quickstarts, and tenant self-service so engineering teams can onboard in minutes. |
| Zero-Trust Security | Enforce device posture, phishing-resistant MFA, continuous risk evaluation, and least-privilege access everywhere. |
| Hybrid Compatibility | Offer first-class support for modern apps (OIDC/OAuth2) while keeping legacy LDAP and SAML workloads running without re-platforming. |
| Global Reliability | Deliver 99.99% availability through globally distributed control planes, disaster recovery drills, and automated failover. |
| Compliance & Audit | Maintain auditable trails, policy versioning, and data residency controls to meet SOC 2, ISO 27001, GDPR, and industry regulations. |

## Platform Architecture

The platform uses a self-hosted Zero Trust Network Access (ZTNA) model. Traffic is routed to regional Kubernetes clusters managed by Rancher. Each cluster runs:

* **Keycloak** for tenant-scoped identity services (OIDC, OAuth2, SAML, LDAP federation).
* **OAuth2 Proxy** as a reverse proxy that enforces authentication and authorization before brokering traffic to downstream services.
* **API Gateways** (Kong or Istio) that enforce policies, perform token validation, and broker traffic to downstream services.
* **SCIM Synchronization Service** that handles provisioning and deprovisioning workflows across SaaS and internal apps.
* **YugabyteDB** as the globally replicated data store for identities, sessions, consents, and policy metadata.
* **OpenLDAP/FreeIPA** clusters exposed via Keycloak LDAP storage provider for workloads that require traditional directory access.

Secrets and signing keys are stored in HSM-backed vaults (CloudHSM, AWS KMS, or Azure Key Vault) with automated rotation.

### Identity & Access Protocols

* **OIDC/OAuth2** for modern web, mobile, SPA, and API clients with JWT-based tokens, refresh tokens, dynamic client registration, and device authorization flows.
* **SAML 2.0** for enterprise SaaS federation and legacy SSO.
* **LDAP v3** bindings for POSIX/Unix logins, network gear, and older applications.
* **SCIM 2.0** for automated provisioning/deprovisioning with downstream systems.
* **FIDO2/WebAuthn** and adaptive MFA to provide phishing-resistant authentication.

### Multi-Tenancy Model

* Tenant isolation through Keycloak realms, namespace-scoped Kubernetes deployments, and logically separated LDAP organizational units.
* Shared services (SCIM, observability, CI/CD) operate in control-plane clusters with per-tenant configuration stored in encrypted config stores.
* Support for customer-managed keys and tenant-level audit export to meet high-trust requirements.

### Security Controls

* Token lifecycle management with JWKS endpoints, kid rotation, and mutual TLS for service-to-service calls.
* Fine-grained authorization through Keycloak authorization services, OPA/ORY Keto policies, and attribute-based access control.
* Comprehensive audit logging for admin actions, authentication events, SCIM changes, and API usage, streamed into a SIEM (Splunk, Datadog, Panther).
* Background risk scoring and anomaly detection using UEBA models to drive step-up authentication or session revocation.

### Observability & Compliance

* OpenTelemetry instrumentation for Keycloak, SCIM services, and API gateways.
* Centralized log aggregation using Loki or Elasticsearch/Fluentd/Kibana.
* Metrics stored in Prometheus/Thanos with SLO dashboards in Grafana.
* Audit and compliance pipelines export immutable logs to cloud object storage with retention and legal hold policies.

## Delivery & Operations

### CI/CD Pipeline

* Jenkins orchestrates linting, testing, container builds, security scans, and Helm-based deployments across environments (review apps, staging, prod).
* Helm charts package Kubernetes resources; Argo CD or FluxCD performs GitOps-based reconciliations for declarative environments.
* Security gates include SAST/DAST, IaC scans, container vulnerability scanning, and policy-as-code checks before promotion.

### Repository Topology

```
repo/
├── infra/        # Terraform automation for clusters, DNS, and other infrastructure
├── charts/       # Helm charts for Keycloak, YugabyteDB, SCIM services, observability stack, and the ZTNA proxy
├── apps/         # Source code & Dockerfiles for SCIM sync, admin portal, integration webhooks, and tooling
├── keycloak/     # Realm templates, client registrations, policy JSON, script providers, themes for branding per-tenant
└── ops/          # Runbooks, incident response plans, and audit controls
```

This layout matches the original slide guidance and aligns with GitOps best practices, enabling infrastructure automation alongside application delivery.

### Runbooks & SRE Practices

* **Incident Response**: PagerDuty/Squadcast escalation, runbooks per component, and chaos drills for failover validation.
* **Backups & DR**: Continuous backup of YugabyteDB via xCluster replication, daily snapshots of Keycloak configuration, and quarterly restore exercises.
* **Capacity Planning**: Autoscaling keyed off login throughput, SCIM job volume, and API latency metrics with regional burst capacity.
* **Secrets Management**: HashiCorp Vault or cloud-native secret stores integrated with workload identity, short-lived credentials, and break-glass procedures.

## Customer & Developer Experience

* Tenant admin portal for domain verification, IdP federation (SAML/WS-Fed), policy configuration, and delegated administration.
* SDKs for major languages/frameworks (JavaScript/TypeScript, Python, Java, .NET, Go) with quickstarts and CLI tooling for automation.
* Marketplace of pre-built SaaS integrations (Salesforce, Google Workspace, Atlassian, ServiceNow) using SCIM and SAML/OIDC app catalogs.
* Advanced analytics dashboards for login trends, risk events, provisioning status, and compliance exports.

## MFA Authenticator App

This repository includes the source code for a mobile MFA authenticator app, located in the `apps/mfa-authenticator` directory. The app is built with Flutter and is compatible with the TOTP standard used by Keycloak.

### Features

*   **TOTP Generation:** The app can generate 6-digit TOTP codes from a secret key.
*   **QR Code Scanning:** New accounts can be added by scanning a QR code from Keycloak.

### Building the App

To build the app, you will need to have the Flutter SDK installed. From the `apps/mfa-authenticator` directory, run the following commands:

```bash
flutter pub get
flutter run
```

**Note:** The QR code scanner requires camera permissions. You will need to configure these permissions in the Android and iOS projects before building a release version.

## Getting Started

### Quick Start with Docker Compose

The fastest way to get the IDaaS Platform running locally:

```bash
# Clone the repository
git clone https://github.com/your-org/IDaaS2.git
cd IDaaS2

# Start all services
docker-compose up -d

# Access the applications
# - Keycloak Admin Console: http://localhost:8080 (admin/admin)
# - Webapp (via OAuth2 Proxy): http://localhost:4180
# - Webapp (direct): http://localhost:8081
```

### Development Setup

For local development with hot-reload:

```bash
# Use development compose file
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# Install Python dependencies
cd apps/webapp
pip install -r requirements.txt

# Run tests
pytest tests/ -v
```

## Application Architecture

The refactored Flask webapp follows modern best practices:

### Project Structure

```
apps/webapp/
├── app.py              # Application factory
├── config.py           # Configuration management
├── extensions.py       # Flask extensions and middleware
├── routes.py           # API routes and views
├── requirements.txt    # Python dependencies
├── Dockerfile          # Multi-stage production build
├── tests/              # Unit tests
│   ├── test_app.py
│   ├── test_config.py
│   └── test_routes.py
└── pytest.ini          # Test configuration
```

### Key Features

- **Application Factory Pattern**: Clean separation of concerns
- **Configuration Management**: Environment-based configuration
- **Comprehensive Logging**: Structured logging with configurable levels
- **Security Headers**: Automatic security header injection
- **Error Handling**: Graceful error handling with proper HTTP status codes
- **Health Checks**: Kubernetes-ready health, readiness, and liveness probes
- **Production Ready**: Uses Gunicorn WSGI server with proper worker configuration

### API Endpoints

| Endpoint | Description |
|----------|-------------|
| `GET /` | Main page with authentication status |
| `GET /health` | Health check endpoint |
| `GET /readiness` | Kubernetes readiness probe |
| `GET /liveness` | Kubernetes liveness probe |
| `GET /metrics` | Application metrics |
| `GET /api/user-info` | Authenticated user information |

## Testing

### Unit Tests

Comprehensive unit test suite with 80%+ code coverage:

```bash
cd apps/webapp

# Run tests with coverage
pytest tests/ -v --cov=. --cov-report=html

# View coverage report
open htmlcov/index.html
```

### End-to-End Tests

E2E tests verify the complete authentication flow:

```bash
# Start services
docker-compose up -d

# Run E2E tests
pip install -r tests/requirements.txt
E2E_BASE_URL=http://localhost:8081 pytest tests/e2e_test.py -v
```

Test coverage includes:
- Health endpoint verification
- Authentication flows (unauthenticated and authenticated)
- OAuth2 Proxy header forwarding
- API endpoint functionality
- Security header presence
- Performance benchmarks

## Security Scanning

The project includes comprehensive security scanning tools:

### Automated Security Scans

Run all security scans with a single command:

```bash
./scripts/run-all-scans.sh
```

This executes:
1. **Dependency Scanning** (Safety, pip-audit): Checks Python packages for known vulnerabilities
2. **SAST** (Bandit, Flake8): Static code analysis for security issues
3. **Container Scanning** (Trivy): Scans Docker images for OS and application vulnerabilities

### Individual Scans

```bash
# Dependency vulnerabilities
./scripts/dependency-scan.sh

# Static code analysis
./scripts/sast-scan.sh

# Container image scanning
./scripts/security-scan.sh
```

All reports are saved to `security-reports/` directory.

## CI/CD Pipelines

The platform supports two CI/CD options:

### Jenkins Pipeline

Comprehensive Jenkinsfile with stages for:
- Code linting (Helm, Python)
- Dependency vulnerability scanning
- SAST scanning
- Unit tests with coverage
- Multi-stage Docker builds
- Container security scanning
- Integration testing
- Automated deployment to staging/production

### Tekton Pipeline

Kubernetes-native CI/CD with:
- Reusable task definitions
- Git clone, build, test, and scan tasks
- Webhook-triggered automation
- GitOps-friendly architecture

See [tekton/README.md](tekton/README.md) for Tekton setup and usage.

## Docker Images

All components use production-hardened, multi-stage Docker builds:

### Webapp
- **Base**: Python 3.11-slim
- **Features**: Non-root user, health checks, Gunicorn WSGI server
- **Size**: Optimized with multi-stage build

### Keycloak
- **Base**: Official Keycloak 23.0
- **Features**: Production-optimized build, PostgreSQL support, health checks

### OAuth2 Proxy
- **Base**: Official OAuth2 Proxy 7.5.1-alpine
- **Features**: Minimal Alpine-based image, health checks

Build all images:
```bash
docker-compose build
```

## Deployment

### Kubernetes Deployment

Deploy using Helm charts:

```bash
# Create namespace
kubectl create namespace idaas-platform

# Deploy Keycloak
helm upgrade --install keycloak charts/keycloak \
  --namespace idaas-platform \
  --wait

# Deploy OAuth2 Proxy
helm upgrade --install oauth2-proxy charts/oauth2-proxy \
  --namespace idaas-platform \
  --wait

# Deploy Webapp
helm upgrade --install webapp charts/webapp \
  --namespace idaas-platform \
  --wait
```

### Configuration

Environment variables for webapp:
- `FLASK_ENV`: Environment (development/production)
- `LOG_LEVEL`: Logging level (DEBUG/INFO/WARNING/ERROR)
- `SECRET_KEY`: Application secret key (required in production)

See [docs/CICD_DEPLOYMENT.md](docs/CICD_DEPLOYMENT.md) for comprehensive deployment documentation.

## Documentation

- **[CI/CD and Deployment Guide](docs/CICD_DEPLOYMENT.md)**: Complete guide for CI/CD pipelines and deployment
- **[Tekton Setup](tekton/README.md)**: Kubernetes-native CI/CD with Tekton
- **[Architecture Documentation](docs/idaas-saas-platform.md)**: Platform architecture and design

## Development Guidelines

### Code Quality

- Follow PEP 8 style guide for Python code
- Maintain 80%+ test coverage
- Run security scans before committing
- Use type hints where applicable

### Security Best Practices

- Never commit secrets or credentials
- Use environment variables for configuration
- Run security scans in CI/CD
- Keep dependencies up to date
- Follow principle of least privilege

### Contributing

1. Create a feature branch
2. Make your changes
3. Run tests and security scans
4. Submit a pull request

## Monitoring and Observability

The platform includes built-in observability features:

- **Health Checks**: Multiple health endpoints for monitoring
- **Structured Logging**: JSON-formatted logs for easy parsing
- **Metrics Endpoint**: Application metrics for Prometheus
- **Request Logging**: Automatic logging of all requests with timing

## License

See LICENSE file for details.
