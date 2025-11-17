# Tekton CI/CD Pipeline for IDaaS Platform

This directory contains Tekton resources for building, testing, and deploying the IDaaS Platform.

## Overview

The Tekton pipeline provides a Kubernetes-native CI/CD solution with the following stages:

1. **Source Code Fetch**: Clone the Git repository
2. **Unit Testing**: Run Python tests with pytest
3. **Build Images**: Build Docker images for all components
4. **Security Scanning**: Scan images and code for vulnerabilities
5. **Deployment**: Deploy to Kubernetes (optional)

## Prerequisites

1. Kubernetes cluster (1.20+)
2. Tekton Pipelines installed:
   ```bash
   kubectl apply -f https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
   ```

3. Tekton Triggers (optional, for webhook automation):
   ```bash
   kubectl apply -f https://storage.googleapis.com/tekton-releases/triggers/latest/release.yaml
   ```

4. Docker registry credentials configured as a Kubernetes secret

## Installation

### 1. Create Namespace

```bash
kubectl create namespace tekton-pipelines
```

### 2. Create Docker Registry Secret

```bash
kubectl create secret docker-registry docker-credentials \
  --docker-server=docker.io \
  --docker-username=<your-username> \
  --docker-password=<your-password> \
  --docker-email=<your-email> \
  -n tekton-pipelines
```

### 3. Install Tasks

```bash
kubectl apply -f tasks/git-clone-task.yaml
kubectl apply -f tasks/build-docker-task.yaml
kubectl apply -f tasks/python-test-task.yaml
kubectl apply -f tasks/security-scan-task.yaml
```

### 4. Install Pipeline

```bash
kubectl apply -f pipeline.yaml
```

### 5. (Optional) Install Triggers

```bash
# Create webhook secret
kubectl create secret generic github-webhook-secret \
  --from-literal=secretToken=<your-webhook-secret> \
  -n tekton-pipelines

# Install triggers
kubectl apply -f trigger-template.yaml
```

## Usage

### Manual Pipeline Run

Edit `pipelinerun.yaml` with your repository and image details, then:

```bash
kubectl create -f pipelinerun.yaml
```

### Monitor Pipeline

```bash
# List all pipeline runs
kubectl get pipelinerun -n tekton-pipelines

# Watch a specific run
kubectl get pipelinerun <pipelinerun-name> -n tekton-pipelines -w

# View logs
tkn pipelinerun logs <pipelinerun-name> -f -n tekton-pipelines
```

### Webhook Automation

1. Expose the EventListener service:
   ```bash
   kubectl port-forward svc/el-idaas-platform-listener 8080:8080 -n tekton-pipelines
   ```

2. Configure GitHub webhook:
   - URL: `http://<your-domain>:8080`
   - Content type: `application/json`
   - Secret: Same as `github-webhook-secret`
   - Events: `push`

## Tasks Description

### git-clone
Clones the source repository to a workspace.

**Parameters:**
- `url`: Repository URL
- `revision`: Branch/tag/commit to checkout

### build-docker-image
Builds Docker images using Kaniko.

**Parameters:**
- `IMAGE`: Image name and tag
- `DOCKERFILE`: Path to Dockerfile
- `CONTEXT`: Build context path

### python-test
Runs Python unit tests with pytest.

**Parameters:**
- `REQUIREMENTS_FILE`: Path to requirements.txt
- `TEST_PATH`: Path to test directory
- `PYTHON_IMAGE`: Python Docker image to use

### security-scan
Performs security scanning with Trivy, Bandit, and Safety.

**Parameters:**
- `IMAGE`: Image to scan
- `SEVERITY`: Severity levels (HIGH,CRITICAL)

## Pipeline Architecture

```
┌──────────────┐
│ Fetch Source │
└──────┬───────┘
       │
┌──────▼───────┐
│  Run Tests   │
└──────┬───────┘
       │
       ├────────────┬────────────┐
       │            │            │
┌──────▼───────┐   │            │
│ Build Webapp │   │            │
└──────┬───────┘   │            │
       │            │            │
┌──────▼───────┐   │            │
│ Scan Webapp  │   │            │
└──────────────┘   │            │
                   │            │
            ┌──────▼───────┐   │
            │Build Keycloak│   │
            └──────┬───────┘   │
                   │            │
            ┌──────▼───────┐   │
            │Scan Keycloak │   │
            └──────────────┘   │
                                │
                         ┌──────▼───────┐
                         │Build OAuth2  │
                         └──────┬───────┘
                                │
                         ┌──────▼───────┐
                         │Scan OAuth2   │
                         └──────────────┘
```

## Troubleshooting

### View Task Logs
```bash
kubectl logs -n tekton-pipelines <pod-name>
```

### Debug Failed Tasks
```bash
tkn taskrun describe <taskrun-name> -n tekton-pipelines
```

### Clean Up
```bash
# Delete all pipeline runs
kubectl delete pipelinerun --all -n tekton-pipelines

# Delete specific pipeline run
kubectl delete pipelinerun <pipelinerun-name> -n tekton-pipelines
```

## Integration with Other Tools

### ArgoCD
Use Tekton to build and push images, then use ArgoCD for GitOps deployment.

### Harbor Registry
Configure Harbor as the image registry in pipeline parameters.

### SonarQube
Add a task for SonarQube code quality analysis.

## Best Practices

1. **Use Workspaces**: Share data between tasks efficiently
2. **Parameterize**: Make pipelines reusable with parameters
3. **Security**: Scan early and often in the pipeline
4. **Secrets Management**: Use Kubernetes secrets, never hardcode credentials
5. **Resource Limits**: Set appropriate CPU/memory limits for tasks
6. **Caching**: Enable image layer caching for faster builds

## References

- [Tekton Documentation](https://tekton.dev/docs/)
- [Tekton Catalog](https://hub.tekton.dev/)
- [Tekton Best Practices](https://tekton.dev/docs/pipelines/pipelines/#best-practices)
