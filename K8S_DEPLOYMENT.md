# Kubernetes Deployment Guide

Complete guide for deploying the IDaaS platform to Kubernetes clusters with CI/CD automation.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Architecture Overview](#architecture-overview)
3. [Quick Start](#quick-start)
4. [Kubernetes Manifests](#kubernetes-manifests)
5. [CI/CD Pipelines](#cicd-pipelines)
6. [Configuration](#configuration)
7. [Deployment](#deployment)
8. [Monitoring](#monitoring)
9. [Scaling](#scaling)
10. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Kubernetes Cluster

**Minimum Requirements**:
- Kubernetes 1.24+
- 3 worker nodes (for HA)
- Each node: 4 CPU, 8 GB RAM
- Storage: 100 GB per node

**Recommended**:
- Kubernetes 1.28+
- 5 worker nodes
- Each node: 8 CPU, 16 GB RAM
- Storage: 200 GB per node

### Required Components

- **Ingress Controller**: NGINX Ingress Controller
- **Cert Manager**: For TLS certificates (Let's Encrypt)
- **Metrics Server**: For HPA (Horizontal Pod Autoscaler)
- **Container Registry**: Docker Hub, GHCR, or private registry

### DBaaS Prerequisites

- YugabyteDB DBaaS instance (PostgreSQL-compatible)
- DragonflyDB DBaaS instance (Redis-compatible)
- Network connectivity from K8s cluster to DBaaS

---

## Architecture Overview

### Deployment Topology

```
┌─────────────────────────────────────────────────────┐
│            Internet / Load Balancer                  │
└───────────────────┬─────────────────────────────────┘
                    │
┌───────────────────▼─────────────────────────────────┐
│         Kubernetes Ingress (NGINX)                   │
│  - SSL/TLS Termination                               │
│  - Rate Limiting                                     │
│  - Session Affinity                                  │
└───────────────────┬─────────────────────────────────┘
                    │
        ┌───────────┴───────────┐
        │                       │
┌───────▼──────────┐  ┌────────▼──────────┐
│  OAuth2 Proxy    │  │   Keycloak        │
│  (2 replicas)    │  │   (2 replicas)    │
│  Port: 4180      │  │   Port: 8080      │
└───────┬──────────┘  └───────────────────┘
        │
┌───────▼──────────┐
│    WebApp        │
│  (3 replicas,    │
│   auto-scaling)  │
│  Port: 8080      │
└───────┬──────────┘
        │
┌───────▼───────────────────────────────────┐
│     External DBaaS (Managed)               │
│  - YugabyteDB (PostgreSQL-compatible)      │
│  - DragonflyDB (Redis-compatible)          │
└────────────────────────────────────────────┘
```

### High Availability Features

- ✅ **Multiple Replicas**: 2-3 replicas per service
- ✅ **Pod Disruption Budgets**: Ensure minimum availability during updates
- ✅ **Rolling Updates**: Zero-downtime deployments
- ✅ **Auto-scaling**: HPA for WebApp (3-10 replicas)
- ✅ **Health Checks**: Liveness and readiness probes
- ✅ **Resource Limits**: Prevent resource exhaustion

---

## Quick Start

### 1. Clone Repository

```bash
git clone https://github.com/your-org/IDaaS2.git
cd IDaaS2
```

### 2. Configure Secrets

Create secrets file with your DBaaS credentials:

```bash
# Copy example
cp k8s/01-secrets-configmap.yaml k8s/secrets-prod.yaml

# Edit with your credentials
nano k8s/secrets-prod.yaml

# Update:
# - yugabyte-db-url
# - yugabyte-user
# - yugabyte-password
# - dragonfly-url
# - dragonfly-session-url
# - All other secrets
```

**Important**: Never commit secrets to git!

### 3. Deploy to Kubernetes

```bash
# Set your registry and image tag
export CONTAINER_REGISTRY=ghcr.io/your-org/idaas
export IMAGE_TAG=v1.0.0

# Apply manifests
kubectl apply -f k8s/00-namespace.yaml
kubectl apply -f k8s/secrets-prod.yaml  # Your customized secrets
kubectl apply -f k8s/02-keycloak-deployment.yaml
kubectl apply -f k8s/03-webapp-deployment.yaml
kubectl apply -f k8s/04-oauth2-proxy-deployment.yaml
kubectl apply -f k8s/05-ingress.yaml
kubectl apply -f k8s/06-rbac-network-policy.yaml
```

### 4. Verify Deployment

```bash
# Check pods
kubectl get pods -n idaas

# Check services
kubectl get svc -n idaas

# Check ingress
kubectl get ingress -n idaas

# Check logs
kubectl logs -f deployment/webapp -n idaas
```

---

## Kubernetes Manifests

### File Structure

```
k8s/
├── 00-namespace.yaml              # Namespace, quotas, limits
├── 01-secrets-configmap.yaml      # Secrets and config (template)
├── 02-keycloak-deployment.yaml    # Keycloak deployment
├── 03-webapp-deployment.yaml      # WebApp with HPA
├── 04-oauth2-proxy-deployment.yaml # OAuth2 Proxy
├── 05-ingress.yaml                # Ingress with TLS
└── 06-rbac-network-policy.yaml    # RBAC and network policies
```

### Manifest Details

**00-namespace.yaml**:
- Creates `idaas` namespace
- Sets resource quotas (16 CPU, 32 GB RAM limits)
- Defines default resource limits per container

**01-secrets-configmap.yaml**:
- Kubernetes Secrets for sensitive data
- ConfigMap for non-sensitive configuration
- **IMPORTANT**: Customize before deploying!

**02-keycloak-deployment.yaml**:
- 2 replicas for HA
- 500m CPU / 1Gi RAM requests
- 2 CPU / 2Gi RAM limits
- Health checks on `/health/ready`
- PodDisruptionBudget (min 1 available)

**03-webapp-deployment.yaml**:
- 3 replicas (auto-scales 3-10)
- HorizontalPodAutoscaler at 70% CPU / 80% memory
- 250m CPU / 512Mi RAM requests
- PodDisruptionBudget (min 2 available)

**04-oauth2-proxy-deployment.yaml**:
- 2 replicas for HA
- 100m CPU / 256Mi RAM requests
- Connects to Keycloak and DragonflyDB

**05-ingress.yaml**:
- NGINX Ingress with TLS
- SSL redirect enabled
- Rate limiting (100 req/s, 1000 req/min)
- Session affinity via cookies
- Security headers

**06-rbac-network-policy.yaml**:
- ServiceAccount for pods
- Role with minimal permissions
- NetworkPolicy for pod-to-pod traffic

---

## CI/CD Pipelines

### GitHub Actions

**Workflow**: `.github/workflows/deploy.yaml`

**Features**:
- Build and push Docker images to GHCR
- Deploy to staging on `main` branch
- Deploy to production on tags (`v*.*.*`)
- Manual deployment via workflow_dispatch
- Automatic rollback on failure

**Secrets Required**:
```bash
KUBECONFIG_STAGING      # Base64-encoded kubeconfig for staging
KUBECONFIG_PRODUCTION   # Base64-encoded kubeconfig for production
```

**Usage**:
```bash
# Automatic deployment on push to main
git push origin main

# Deploy specific tag to production
git tag -a v1.0.0 -m "Release 1.0.0"
git push origin v1.0.0

# Manual deployment via GitHub UI
# Go to Actions → Deploy to Kubernetes → Run workflow
```

### Jenkins Pipeline

**File**: `Jenkinsfile`

**Features**:
- Parallel test execution (unit + security)
- Build Docker images
- Deploy to staging/production
- Manual approval for production
- Automatic rollback on failure

**Credentials Required**:
- `kubeconfig-credentials-id`: Kubeconfig file
- `docker-registry-credentials`: Docker registry auth

**Usage**:
```bash
# Configure Jenkins pipeline
# 1. Create new Pipeline job
# 2. Point to Jenkinsfile in repo
# 3. Configure credentials
# 4. Build with parameters
```

---

## Configuration

### Environment Variables

**Production ConfigMap** (k8s/01-secrets-configmap.yaml):

```yaml
data:
  KEYCLOAK_HOSTNAME: "auth.example.com"      # Your Keycloak domain
  FLASK_ENV: "production"
  LOG_LEVEL: "INFO"
  OAUTH2_PROXY_REDIRECT_URL: "https://app.example.com/oauth2/callback"
```

**Production Secrets**:

```yaml
stringData:
  yugabyte-db-url: "jdbc:postgresql://..."   # Your DBaaS endpoint
  dragonfly-url: "redis://..."               # Your DBaaS endpoint
  secret-key: "..."                          # Generate with Python secrets
```

### Ingress Domains

Update `k8s/05-ingress.yaml`:

```yaml
spec:
  tls:
  - hosts:
    - app.example.com          # Your application domain
    - auth.example.com         # Your Keycloak domain
  rules:
  - host: app.example.com
    # ...
  - host: auth.example.com
    # ...
```

---

## Deployment

### Initial Deployment

```bash
# 1. Create namespace
kubectl apply -f k8s/00-namespace.yaml

# 2. Create secrets (use your customized file)
kubectl create secret generic idaas-secrets \
  --from-literal=yugabyte-db-url="jdbc:postgresql://..." \
  --from-literal=yugabyte-user="keycloak_prod" \
  --from-literal=yugabyte-password="YOUR_PASSWORD" \
  --from-literal=dragonfly-url="redis://..." \
  --from-literal=dragonfly-session-url="redis://..." \
  --from-literal=secret-key="$(python3 -c 'import secrets; print(secrets.token_hex(32))')" \
  --from-literal=oauth2-client-secret="YOUR_SECRET" \
  --from-literal=oauth2-cookie-secret="$(python3 -c 'import secrets; print(secrets.token_urlsafe(32)[:32])')" \
  -n idaas

# 3. Create ConfigMap
kubectl apply -f k8s/01-secrets-configmap.yaml

# 4. Deploy services
export CONTAINER_REGISTRY=ghcr.io/your-org/idaas
export IMAGE_TAG=v1.0.0

for file in k8s/0{2..6}-*.yaml; do
  envsubst < $file | kubectl apply -f -
done

# 5. Verify
kubectl get all -n idaas
```

### Update Deployment

```bash
# Update image tag
kubectl set image deployment/webapp \
  webapp=${CONTAINER_REGISTRY}-webapp:v1.0.1 \
  -n idaas

# Or apply updated manifests
kubectl apply -f k8s/03-webapp-deployment.yaml
```

### Rollback

```bash
# Rollback to previous version
kubectl rollout undo deployment/webapp -n idaas

# Rollback to specific revision
kubectl rollout undo deployment/webapp --to-revision=2 -n idaas

# View rollout history
kubectl rollout history deployment/webapp -n idaas
```

---

## Monitoring

### Check Pod Status

```bash
# List all pods
kubectl get pods -n idaas

# Describe pod
kubectl describe pod <pod-name> -n idaas

# View logs
kubectl logs -f deployment/webapp -n idaas

# Stream logs from all replicas
kubectl logs -f -l app=webapp -n idaas
```

### Resource Usage

```bash
# CPU and memory usage
kubectl top pods -n idaas
kubectl top nodes

# HPA status
kubectl get hpa -n idaas
```

### Events

```bash
# Recent events in namespace
kubectl get events -n idaas --sort-by='.lastTimestamp'
```

---

## Scaling

### Manual Scaling

```bash
# Scale WebApp to 5 replicas
kubectl scale deployment/webapp --replicas=5 -n idaas

# Scale Keycloak to 3 replicas
kubectl scale deployment/keycloak --replicas=3 -n idaas
```

### Auto-scaling (HPA)

WebApp has HorizontalPodAutoscaler configured:

```yaml
minReplicas: 3
maxReplicas: 10
targetCPUUtilizationPercentage: 70
targetMemoryUtilizationPercentage: 80
```

**Adjust HPA**:

```bash
kubectl edit hpa webapp-hpa -n idaas
```

---

## Troubleshooting

### Pods Not Starting

```bash
# Check pod events
kubectl describe pod <pod-name> -n idaas

# Common issues:
# - ImagePullBackOff: Wrong image name or registry auth
# - CrashLoopBackOff: Application error, check logs
# - Pending: Insufficient resources
```

### Database Connection Errors

```bash
# Verify secrets
kubectl get secret idaas-secrets -n idaas -o yaml

# Test connection from pod
kubectl run -it --rm debug --image=postgres:15 --restart=Never -n idaas -- \
  psql "${YUGABYTE_DB_URL}"
```

### Ingress Not Working

```bash
# Check ingress
kubectl describe ingress idaas-ingress -n idaas

# Check ingress controller
kubectl get pods -n ingress-nginx

# Verify DNS
dig app.example.com
```

### High Memory Usage

```bash
# Identify high-memory pods
kubectl top pods -n idaas --sort-by=memory

# Increase memory limits
kubectl edit deployment/webapp -n idaas
# Update resources.limits.memory
```

---

## Security Best Practices

✅ **Secrets Management**:
- Use Kubernetes Secrets or external secret managers
- Never commit secrets to git
- Rotate secrets regularly

✅ **Network Policies**:
- Restrict pod-to-pod communication
- Allow only necessary ingress/egress

✅ **RBAC**:
- Use ServiceAccounts with minimal permissions
- Regular audit of RBAC rules

✅ **Image Security**:
- Scan images for vulnerabilities
- Use specific image tags, not `latest`
- Pull from trusted registries

✅ **Resource Limits**:
- Set CPU and memory limits
- Prevent resource exhaustion

---

## Production Checklist

Before deploying to production:

- [ ] DBaaS instances provisioned and tested
- [ ] Secrets configured (not committed to git)
- [ ] Domain names configured (DNS)
- [ ] TLS certificates configured (cert-manager or manual)
- [ ] Ingress controller installed
- [ ] Metrics server installed (for HPA)
- [ ] Resource quotas appropriate for load
- [ ] Backup strategy in place
- [ ] Monitoring and alerting configured
- [ ] CI/CD pipeline tested in staging
- [ ] Rollback procedure documented
- [ ] Team trained on kubectl commands

---

## Related Documentation

- `DBAAS_DEPLOYMENT.md` - DBaaS configuration
- `HA_DEPLOYMENT.md` - High availability setup
- `CI_CD.md` - CI/CD pipeline details
- `KEYCLOAK_MFA_SETUP.md` - MFA configuration

---

## Support

For issues:
1. Check pod logs: `kubectl logs -f <pod> -n idaas`
2. Check events: `kubectl get events -n idaas`
3. Review troubleshooting section above
4. Open GitHub issue with logs
