# Hardware Requirements — IDaaS
> Version: 1.0 | Last Updated: 2026-02-18 | Status: Draft
> Classification: Internal | Author: AIDD System

---

## 1. Introduction

This document specifies the hardware and infrastructure resource requirements for the
IDaaS platform across development, staging, and production environments. All production
workloads run on Kubernetes; database services are consumed as managed DBaaS.

---

## 2. Production Environment

### 2.1 Kubernetes Cluster Requirements

| Specification | Minimum | Recommended |
|---------------|---------|-------------|
| Kubernetes Version | 1.28+ | 1.30+ |
| Worker Nodes | 3 | 5 |
| CPU per Node | 8 vCPU | 16 vCPU |
| Memory per Node | 32 GiB | 64 GiB |
| Disk per Node | 100 GiB SSD | 200 GiB NVMe SSD |
| Network | 1 Gbps | 10 Gbps |
| Total Cluster CPU | 24 vCPU | 80 vCPU |
| Total Cluster Memory | 96 GiB | 320 GiB |

### 2.2 Namespace Resource Quota

From Kubernetes manifest `k8s/00-namespace.yaml`:

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 16 cores | 32 cores |
| Memory | 32 GiB | 64 GiB |

### 2.3 Per-Component Resource Allocation

| Component | Replicas | CPU Request | CPU Limit | Memory Request | Memory Limit |
|-----------|----------|-------------|-----------|----------------|-------------|
| Keycloak | 2 | 500m | 2000m | 1 GiB | 2 GiB |
| Flask Webapp | 3-10 (HPA) | 200m | 1000m | 256 MiB | 1 GiB |
| OAuth2 Proxy | 2 | 100m | 500m | 128 MiB | 512 MiB |
| NGINX Ingress | 2 | 100m | 500m | 128 MiB | 256 MiB |
| cert-manager | 1 | 50m | 200m | 64 MiB | 128 MiB |

### 2.4 Per-Container Limits (LimitRange)

| Resource | Minimum | Maximum |
|----------|---------|---------|
| CPU | 100m | 4 cores |
| Memory | 128 MiB | 8 GiB |

### 2.5 Storage Requirements

| Component | Type | Size | IOPS | Purpose |
|-----------|------|------|------|---------|
| NGINX Ingress | emptyDir | 1 GiB | - | Temporary logs and cache |
| Keycloak | PVC (optional) | 10 GiB | 3000 | Theme customization, provider JARs |
| Monitoring (Prometheus) | PVC | 50 GiB | 3000 | Metrics retention (15 days) |
| Logging (if self-hosted) | PVC | 100 GiB | 5000 | Log aggregation storage |

---

## 3. Managed Database Services (DBaaS)

### 3.1 YugabyteDB

| Specification | Minimum | Recommended |
|---------------|---------|-------------|
| Instance Type | 2 vCPU, 8 GiB RAM | 4 vCPU, 16 GiB RAM |
| Nodes | 3 (RF=3) | 3-5 (RF=3) |
| Storage per Node | 100 GiB SSD | 250 GiB SSD |
| IOPS per Node | 3,000 | 10,000 |
| Total Storage | 300 GiB | 750 GiB - 1.25 TiB |
| Network | Private VPC peering | Private VPC peering |
| Backup | Daily automated | Continuous WAL + daily snapshot |
| Multi-Region | Single region | xCluster replication (2 regions) |

**Sizing Rationale**: Keycloak schema with 100K users, 500 clients, 1M sessions/month,
10M audit events/year requires approximately 50 GiB base + 200 GiB for audit retention.

### 3.2 DragonflyDB

| Specification | Minimum | Recommended |
|---------------|---------|-------------|
| Instance Type | 2 vCPU, 4 GiB RAM | 4 vCPU, 8 GiB RAM |
| Nodes | 1 | 2 (primary + replica) |
| Memory | 4 GiB | 8 GiB |
| Connections | 1,000 | 10,000 |
| Network | Private VPC peering | Private VPC peering |
| Persistence | RDB snapshots | AOF + RDB |

**Sizing Rationale**: 10,000 concurrent sessions at ~2 KiB each = ~20 MiB session data.
Cache layer adds ~500 MiB. Total active memory < 1 GiB with headroom for peaks.

---

## 4. Staging Environment

Staging mirrors production topology at reduced scale:

| Component | Replicas | CPU Request | Memory Request |
|-----------|----------|-------------|----------------|
| Keycloak | 1 | 250m | 512 MiB |
| Flask Webapp | 2 | 100m | 128 MiB |
| OAuth2 Proxy | 1 | 50m | 64 MiB |
| YugabyteDB | 1 node (RF=1) | 2 vCPU | 4 GiB |
| DragonflyDB | 1 node | 1 vCPU | 2 GiB |

**Kubernetes Cluster**: 2 worker nodes, 4 vCPU / 16 GiB each

---

## 5. Development Environment

### 5.1 Docker Compose (Local Development)

| Specification | Minimum | Recommended |
|---------------|---------|-------------|
| CPU | 4 cores | 8 cores |
| Memory | 8 GiB | 16 GiB |
| Disk | 20 GiB free | 50 GiB free (SSD) |
| Docker Desktop | 4 GiB allocation | 8 GiB allocation |
| OS | macOS 13+ / Ubuntu 22.04+ / Windows 11 WSL2 | macOS 14+ / Ubuntu 24.04+ |

### 5.2 Minikube / Kind (Local Kubernetes)

| Specification | Minimum | Recommended |
|---------------|---------|-------------|
| CPU | 4 cores | 8 cores |
| Memory | 12 GiB | 24 GiB |
| Disk | 40 GiB free | 80 GiB free (SSD) |
| Kubernetes | minikube 1.32+ or kind 0.22+ | minikube with 3 nodes |

---

## 6. Network Requirements

### 6.1 Production Network

| Requirement | Specification |
|-------------|---------------|
| Load Balancer | Layer 7 (HTTP/HTTPS) with TLS termination |
| Public IP | 1 static IP for ingress |
| DNS | Wildcard or per-service DNS records |
| Firewall Rules | HTTPS (443) inbound; DB ports (5433, 6379) internal only |
| VPC Peering | Kubernetes cluster to DBaaS VPCs |
| Bandwidth | 1 Gbps minimum; 10 Gbps recommended |
| Latency | < 5ms between Kubernetes and DBaaS (same region) |

### 6.2 Ports and Protocols

| Service | Port | Protocol | Exposure |
|---------|------|----------|----------|
| NGINX Ingress | 443 | HTTPS | Public |
| NGINX Ingress | 80 | HTTP (redirect) | Public |
| Keycloak | 8080 | HTTP | ClusterIP only |
| Flask Webapp | 8080 | HTTP | ClusterIP only |
| OAuth2 Proxy | 4180 | HTTP | ClusterIP only |
| YugabyteDB | 5433 | PostgreSQL/TLS | VPC peering |
| DragonflyDB | 6379 | Redis/TLS | VPC peering |

---

## 7. Capacity Planning

### 7.1 Scaling Triggers

| Metric | Threshold | Action |
|--------|-----------|--------|
| Webapp CPU utilization | > 70% average | HPA scales up (max 10 replicas) |
| Webapp memory utilization | > 80% average | HPA scales up (max 10 replicas) |
| Keycloak session count | > 5,000 concurrent | Evaluate adding replicas |
| YugabyteDB storage | > 70% capacity | Expand disk or add node |
| DragonflyDB memory | > 70% capacity | Upgrade instance tier |
| Authentication latency P95 | > 200ms | Investigate bottleneck; scale as needed |

### 7.2 Growth Projections

| Metric | Year 1 | Year 2 | Year 3 |
|--------|--------|--------|--------|
| Tenant Organizations | 50 | 200 | 500 |
| Total Users | 10,000 | 50,000 | 200,000 |
| Peak Concurrent Sessions | 2,000 | 8,000 | 30,000 |
| Monthly Auth Events | 500,000 | 2,000,000 | 10,000,000 |
| Storage (YugabyteDB) | 100 GiB | 400 GiB | 1.5 TiB |

---

*Document generated by the AIDD pipeline. Resource specifications from k8s/ manifests and prd.md.*
