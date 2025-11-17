# CI/CD and Deployment Guide for IDaaS Platform

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [CI/CD Pipelines](#cicd-pipelines)
4. [Local Development](#local-development)
5. [Testing](#testing)
6. [Security Scanning](#security-scanning)
7. [Deployment](#deployment)
8. [Troubleshooting](#troubleshooting)

## Overview

The IDaaS Platform uses a comprehensive CI/CD approach with multiple pipeline options:

- **Jenkins**: Traditional CI/CD with Groovy-based pipeline
- **Tekton**: Kubernetes-native CI/CD with YAML-based resources

Both pipelines include:
- Code linting and quality checks
- Unit and integration testing
- Security vulnerability scanning (SAST, dependency scanning, container scanning)
- Multi-stage Docker builds
- Automated deployment to staging/production

## Architecture

### Application Components

```
┌─────────────────────────────────────────────────────────┐
│                    IDaaS Platform                        │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────┐ │
│  │   Keycloak   │    │ OAuth2 Proxy │    │  Webapp  │ │
│  │  (Identity)  │───▶│ (Auth Proxy) │───▶│ (Flask)  │ │
│  └──────────────┘    └──────────────┘    └──────────┘ │
│         │                                               │
│         ▼                                               │
│  ┌──────────────┐                                      │
│  │  PostgreSQL  │                                      │
│  └──────────────┘                                      │
└─────────────────────────────────────────────────────────┘
```

### CI/CD Pipeline Stages

```
┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐
│ Checkout │──▶│   Lint   │──▶│   Test   │──▶│  Build   │──▶│   Scan   │
└──────────┘   └──────────┘   └──────────┘   └──────────┘   └──────────┘
                                                                    │
                    ┌───────────────────────────────────────────────┘
                    ▼
              ┌──────────┐   ┌──────────┐   ┌──────────┐
              │   Push   │──▶│  Deploy  │──▶│  Verify  │
              └──────────┘   └──────────┘   └──────────┘
```

## CI/CD Pipelines

### Jenkins Pipeline

**Location**: `Jenkinsfile`

**Features**:
- Parallel execution of independent stages
- Security scanning with Trivy, Bandit, and Safety
- Multi-stage Docker builds
- Automated deployment to staging
- Manual approval for production deployment
- Comprehensive artifact archival

**Usage**:
```bash
# Configure Jenkins with this repository
# Pipeline will trigger on commits to main branch
# Or trigger manually from Jenkins UI
```

**Key Stages**:
1. **Checkout**: Clone repository and set build metadata
2. **Lint**: Helm and Python code linting
3. **Dependency Scan**: Check Python dependencies for vulnerabilities
4. **SAST Scan**: Static code analysis with Bandit
5. **Unit Tests**: Run pytest with coverage
6. **Build Images**: Build Docker images for all components
7. **Container Security Scan**: Scan images with Trivy
8. **Integration Tests**: Run E2E tests with docker-compose
9. **Tag & Push**: Tag and push images to registry (main branch only)
10. **Deploy**: Deploy to staging/production (main branch only)

### Tekton Pipeline

**Location**: `tekton/`

**Features**:
- Kubernetes-native execution
- Reusable task definitions
- Workspace-based data sharing
- Webhook-triggered automation
- GitOps-friendly

**Usage**:
```bash
# Install Tekton
kubectl apply -f https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml

# Install tasks
kubectl apply -f tekton/tasks/

# Install pipeline
kubectl apply -f tekton/pipeline.yaml

# Run pipeline
kubectl create -f tekton/pipelinerun.yaml

# Monitor
tkn pipelinerun logs -f -n tekton-pipelines
```

See [tekton/README.md](../tekton/README.md) for detailed Tekton documentation.

## Local Development

### Prerequisites

- Docker 20.10+
- Docker Compose 2.0+
- Python 3.11+
- Git

### Setup

1. **Clone Repository**:
   ```bash
   git clone https://github.com/your-org/IDaaS2.git
   cd IDaaS2
   ```

2. **Start Services**:
   ```bash
   # Start all services
   docker-compose up -d

   # Or use development override
   docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d
   ```

3. **Verify Services**:
   ```bash
   # Check service health
   docker-compose ps

   # View logs
   docker-compose logs -f webapp
   ```

4. **Access Applications**:
   - Keycloak: http://localhost:8080 (admin/admin)
   - Webapp (via OAuth2 Proxy): http://localhost:4180
   - Webapp (direct): http://localhost:8081

### Development Workflow

1. **Make Code Changes**: Edit files in `apps/webapp/`
2. **Test Locally**: Changes auto-reload in development mode
3. **Run Tests**:
   ```bash
   cd apps/webapp
   pytest tests/ -v
   ```
4. **Commit Changes**:
   ```bash
   git add .
   git commit -m "Your commit message"
   git push
   ```

## Testing

### Unit Tests

**Location**: `apps/webapp/tests/`

**Run Tests**:
```bash
cd apps/webapp
pip install -r requirements.txt
pytest tests/ -v --cov=. --cov-report=html
```

**View Coverage**:
```bash
open htmlcov/index.html
```

### End-to-End Tests

**Location**: `tests/e2e_test.py`

**Prerequisites**: Services must be running

**Run Tests**:
```bash
# Start services
docker-compose up -d

# Run E2E tests
pip install -r tests/requirements.txt
E2E_BASE_URL=http://localhost:8081 pytest tests/e2e_test.py -v

# Cleanup
docker-compose down
```

### Test Coverage

The project aims for:
- **Unit Tests**: 80%+ code coverage
- **Integration Tests**: All critical user flows
- **E2E Tests**: Key authentication scenarios

## Security Scanning

### Overview

Three types of security scanning are performed:

1. **Dependency Scanning**: Check Python packages for known vulnerabilities
2. **SAST (Static Analysis)**: Analyze source code for security issues
3. **Container Scanning**: Scan Docker images for vulnerabilities

### Run All Scans

```bash
# Make scripts executable
chmod +x scripts/*.sh

# Run all security scans
./scripts/run-all-scans.sh
```

### Individual Scans

**Dependency Scanning**:
```bash
./scripts/dependency-scan.sh
```

**SAST Scanning**:
```bash
./scripts/sast-scan.sh
```

**Container Scanning**:
```bash
# First build images
docker-compose build

# Then scan
./scripts/security-scan.sh
```

### Reports

All scan results are saved to `security-reports/` directory:
```
security-reports/
├── webapp-dependencies.json
├── webapp-bandit.json
├── webapp-trivy.json
├── keycloak-trivy.json
└── oauth2-trivy.json
```

### Security Standards

- **Severity Threshold**: HIGH and CRITICAL vulnerabilities must be addressed
- **SAST**: Bandit severity level set to MEDIUM
- **Container Scanning**: Trivy scans for OS and application vulnerabilities

## Deployment

### Deployment Environments

1. **Development**: Local docker-compose
2. **Staging**: Kubernetes staging namespace
3. **Production**: Kubernetes production namespace

### Kubernetes Deployment

**Prerequisites**:
- Kubernetes cluster (1.20+)
- Helm 3.0+
- kubectl configured

**Deploy with Helm**:

```bash
# Create namespace
kubectl create namespace idaas-staging

# Deploy Keycloak
helm upgrade --install keycloak charts/keycloak \
  --namespace idaas-staging \
  --set postgresql.auth.password=secure-password \
  --wait

# Deploy OAuth2 Proxy
helm upgrade --install oauth2-proxy charts/oauth2-proxy \
  --namespace idaas-staging \
  --set config.clientID=webapp-client \
  --set config.clientSecret=client-secret \
  --wait

# Deploy Webapp
helm upgrade --install webapp charts/webapp \
  --namespace idaas-staging \
  --set image.repository=your-registry/idaas-webapp \
  --set image.tag=latest \
  --wait
```

**Verify Deployment**:
```bash
# Check pods
kubectl get pods -n idaas-staging

# Check services
kubectl get svc -n idaas-staging

# Check ingress
kubectl get ingress -n idaas-staging

# View logs
kubectl logs -f deployment/webapp -n idaas-staging
```

### Configuration Management

**Environment Variables**:

Webapp configuration via environment variables:
```yaml
env:
  - name: FLASK_ENV
    value: "production"
  - name: LOG_LEVEL
    value: "INFO"
  - name: SECRET_KEY
    valueFrom:
      secretKeyRef:
        name: webapp-secrets
        key: secret-key
```

**Secrets Management**:
```bash
# Create secrets
kubectl create secret generic webapp-secrets \
  --from-literal=secret-key=$(openssl rand -base64 32) \
  -n idaas-staging

# Create docker registry secret
kubectl create secret docker-registry regcred \
  --docker-server=docker.io \
  --docker-username=username \
  --docker-password=password \
  -n idaas-staging
```

### Rollback

**Helm Rollback**:
```bash
# List releases
helm list -n idaas-staging

# View history
helm history webapp -n idaas-staging

# Rollback to previous version
helm rollback webapp -n idaas-staging

# Rollback to specific revision
helm rollback webapp 3 -n idaas-staging
```

**Kubernetes Rollback**:
```bash
# Rollback deployment
kubectl rollout undo deployment/webapp -n idaas-staging

# Check rollout status
kubectl rollout status deployment/webapp -n idaas-staging
```

## Troubleshooting

### Common Issues

#### 1. Build Failures

**Symptom**: Docker build fails

**Solutions**:
```bash
# Clear Docker cache
docker builder prune -a

# Rebuild without cache
docker-compose build --no-cache

# Check Dockerfile syntax
docker build -f apps/webapp/Dockerfile apps/webapp --progress=plain
```

#### 2. Test Failures

**Symptom**: Tests fail locally

**Solutions**:
```bash
# Ensure services are running
docker-compose ps

# Check service logs
docker-compose logs webapp

# Verify connectivity
curl http://localhost:8081/health
```

#### 3. Deployment Issues

**Symptom**: Pods not starting

**Solutions**:
```bash
# Describe pod
kubectl describe pod <pod-name> -n idaas-staging

# Check events
kubectl get events -n idaas-staging --sort-by='.lastTimestamp'

# Check pod logs
kubectl logs <pod-name> -n idaas-staging

# Check image pull
kubectl get pods -n idaas-staging -o yaml | grep -i image
```

#### 4. Security Scan Failures

**Symptom**: Security scans report vulnerabilities

**Solutions**:
```bash
# Update dependencies
cd apps/webapp
pip install --upgrade -r requirements.txt

# Review scan reports
cat security-reports/webapp-dependencies.json

# Update base images
# Edit Dockerfile and change python:3.11-slim to latest version
```

### Debug Mode

**Enable Debug Logging**:
```bash
# For local development
export FLASK_ENV=development
export LOG_LEVEL=DEBUG

# In Kubernetes
kubectl set env deployment/webapp LOG_LEVEL=DEBUG -n idaas-staging
```

**Access Application Logs**:
```bash
# Docker Compose
docker-compose logs -f --tail=100 webapp

# Kubernetes
kubectl logs -f deployment/webapp -n idaas-staging --tail=100
```

### Health Checks

**Application Health Endpoints**:
- `/health` - General health check
- `/readiness` - Kubernetes readiness probe
- `/liveness` - Kubernetes liveness probe
- `/metrics` - Application metrics

**Check Health**:
```bash
# Local
curl http://localhost:8081/health

# Kubernetes
kubectl exec -it <pod-name> -n idaas-staging -- curl localhost:8080/health
```

## Best Practices

### 1. Version Control
- Use semantic versioning for releases
- Tag Docker images with git commit SHA
- Maintain changelog

### 2. Security
- Rotate secrets regularly
- Use least privilege principles
- Scan dependencies before deployment
- Enable RBAC in Kubernetes

### 3. Monitoring
- Set up Prometheus metrics
- Configure alerting for critical issues
- Monitor application logs
- Track deployment success rate

### 4. Documentation
- Keep README up to date
- Document configuration changes
- Maintain runbooks for incidents
- Document architecture decisions

### 5. Testing
- Write tests for new features
- Maintain test coverage above 80%
- Run security scans in CI/CD
- Perform load testing before production

## References

- [Flask Documentation](https://flask.palletsprojects.com/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Helm Documentation](https://helm.sh/docs/)
- [Tekton Documentation](https://tekton.dev/docs/)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
