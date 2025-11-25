# High Availability Deployment Guide

This guide explains how to deploy the IDaaS platform in an active-active high availability configuration across two virtual machines on different physical servers, with a load balancer providing a single Virtual IP (VIP) for access.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Prerequisites](#prerequisites)
3. [Load Balancer Options](#load-balancer-options)
4. [Network Configuration](#network-configuration)
5. [Server Setup](#server-setup)
6. [Load Balancer Configuration](#load-balancer-configuration)
7. [Session Persistence](#session-persistence)
8. [Health Checks](#health-checks)
9. [Deployment Steps](#deployment-steps)
10. [Testing](#testing)
11. [Monitoring](#monitoring)
12. [Failover Procedures](#failover-procedures)
13. [Troubleshooting](#troubleshooting)

---

## Architecture Overview

### Deployment Topology

```
                                    ┌─────────────────┐
                                    │   Internet/     │
                                    │   Internal      │
                                    │   Network       │
                                    └────────┬────────┘
                                             │
                              Virtual IP (VIP): 192.168.1.100
                                             │
                        ┌────────────────────┴────────────────────┐
                        │      Load Balancer (HAProxy/NGINX)       │
                        │    with Keepalived for VIP Management    │
                        │                                           │
                        │  ┌──────────────┐    ┌──────────────┐  │
                        │  │   Node 1     │    │   Node 2     │  │
                        │  │  (Master)    │    │   (Backup)   │  │
                        │  │ Priority 101 │    │ Priority 100 │  │
                        │  └──────────────┘    └──────────────┘  │
                        └────────────────────┬────────────────────┘
                                             │
                    ┌────────────────────────┼────────────────────────┐
                    │                        │                        │
          ┌─────────▼─────────┐    ┌────────▼────────┐    ┌─────────▼─────────┐
          │   VM 1 (Node 1)   │    │  DragonflyDB    │    │   VM 2 (Node 2)   │
          │ Physical Server 1 │    │   (Replicated)  │    │ Physical Server 2 │
          ├───────────────────┤    └─────────────────┘    ├───────────────────┤
          │  Keycloak         │                           │  Keycloak         │
          │  YugabyteDB Node  │◄─────────────────────────►│  YugabyteDB Node  │
          │  WebApp           │         Replication       │  WebApp           │
          │  OAuth2 Proxy     │                           │  OAuth2 Proxy     │
          │  HAProxy/NGINX    │                           │  HAProxy/NGINX    │
          │  Keepalived       │                           │  Keepalived       │
          └───────────────────┘                           └───────────────────┘
                  IP: 192.168.1.101                           IP: 192.168.1.102
```

### Key Features

- **Active-Active**: Both nodes serve traffic simultaneously
- **Automatic Failover**: VIP moves to healthy node within seconds
- **Load Distribution**: Traffic distributed across both nodes
- **Session Persistence**: Sticky sessions ensure user experience
- **Database Replication**: YugabyteDB provides distributed SQL with automatic replication
- **Stateless Applications**: WebApp and OAuth2 Proxy are stateless
- **Shared State**: DragonflyDB replicates sessions across nodes

---

## Prerequisites

### Hardware Requirements

**Minimum per VM**:
- 4 CPU cores
- 16 GB RAM
- 200 GB SSD storage
- 1 Gbps network interface

**Recommended per VM**:
- 8 CPU cores
- 32 GB RAM
- 500 GB SSD storage
- 10 Gbps network interface

### Physical Server Requirements

- Two physical servers in different racks (for redundancy)
- Separate power circuits
- Network connectivity between servers
- Same subnet or routable network

### Software Requirements

- Ubuntu 22.04 LTS or later (both VMs)
- Docker 24.0 or later
- Docker Compose 2.20 or later
- HAProxy 2.8 or NGINX 1.24
- Keepalived 2.2 or later

### Network Requirements

- **Static IPs** for both VMs
- **Virtual IP (VIP)** in the same subnet
- **Firewall rules** allowing traffic between nodes
- **Multicast** support for VRRP (Keepalived)
- **Port access** for load balancer health checks

---

## Load Balancer Options

We recommend **HAProxy with Keepalived** for this deployment due to superior performance, flexibility, and built-in health checking.

### Option 1: HAProxy + Keepalived (Recommended)

**Advantages**:
- Industry-standard load balancer
- Excellent performance (100k+ concurrent connections)
- Advanced health checks
- SSL/TLS termination
- Detailed statistics and monitoring
- Active-active support with session affinity

**Use Case**: Production deployments requiring high performance and reliability

### Option 2: NGINX + Keepalived

**Advantages**:
- Web server + load balancer in one
- Simpler configuration
- Built-in caching
- SSL/TLS termination

**Use Case**: Simpler deployments or when NGINX is already in use

### Option 3: Dedicated Hardware Load Balancer

**Advantages**:
- Highest performance
- Enterprise support
- Advanced features (DDoS protection, WAF)

**Examples**: F5 BIG-IP, Citrix ADC, A10 Networks

**Use Case**: Large enterprise deployments with dedicated network team

---

## Network Configuration

### IP Address Planning

| Component | IP Address | Notes |
|-----------|------------|-------|
| **Virtual IP (VIP)** | 192.168.1.100 | Floating IP managed by Keepalived |
| **VM 1 (Node 1)** | 192.168.1.101 | Physical Server 1 |
| **VM 2 (Node 2)** | 192.168.1.102 | Physical Server 2 |
| **Default Gateway** | 192.168.1.1 | Network gateway |

**Adjust these IPs to match your network subnet.**

### Port Requirements

#### External Ports (accessible via VIP)

| Port | Service | Protocol | Description |
|------|---------|----------|-------------|
| 80 | HTTP | TCP | Redirects to HTTPS |
| 443 | HTTPS | TCP | Primary application access |
| 8080 | Keycloak | TCP | Identity provider (dev mode) |

#### Internal Ports (between nodes)

| Port | Service | Protocol | Description |
|------|---------|----------|-------------|
| 5433 | YugabyteDB YSQL | TCP | PostgreSQL-compatible SQL |
| 7000 | YugabyteDB Master | TCP | Cluster management |
| 9100 | YugabyteDB TServer | TCP | Tablet server |
| 6379 | DragonflyDB | TCP | Redis-compatible cache |
| 8081 | WebApp | TCP | Flask application |
| 4180 | OAuth2 Proxy | TCP | Authentication gateway |
| 224.0.0.18 | VRRP (Keepalived) | Multicast | VIP management |

#### Health Check Ports

| Port | Service | Protocol | Description |
|------|---------|----------|-------------|
| 8080 | Keycloak Health | TCP | /health/ready endpoint |
| 8081 | WebApp Health | TCP | /health endpoint |
| 4180 | OAuth2 Proxy Health | TCP | /ping endpoint |

### Firewall Rules

**On both VMs**:

```bash
# Allow traffic from other node
sudo ufw allow from 192.168.1.101
sudo ufw allow from 192.168.1.102

# Allow VRRP multicast for Keepalived
sudo ufw allow proto vrrp

# Allow external HTTPS traffic
sudo ufw allow 443/tcp
sudo ufw allow 80/tcp

# Enable firewall
sudo ufw enable
```

---

## Server Setup

### Step 1: Prepare VMs

**On both VM 1 and VM 2**:

1. **Update system**:
```bash
sudo apt update && sudo apt upgrade -y
```

2. **Install Docker**:
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
```

3. **Install Docker Compose**:
```bash
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

4. **Install HAProxy**:
```bash
sudo apt install haproxy -y
```

5. **Install Keepalived**:
```bash
sudo apt install keepalived -y
```

6. **Enable IP forwarding** (required for VIP):
```bash
sudo sysctl -w net.ipv4.ip_forward=1
sudo sysctl -w net.ipv4.ip_nonlocal_bind=1
echo "net.ipv4.ip_forward = 1" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.ip_nonlocal_bind = 1" | sudo tee -a /etc/sysctl.conf
```

### Step 2: Clone Repository

**On both VMs**:

```bash
cd /opt
sudo git clone https://github.com/your-org/IDaaS2.git
cd IDaaS2
sudo chown -R $USER:$USER .
```

### Step 3: Configure Environment Variables

**On both VMs**, create `.env` file:

```bash
cp .env.example .env
nano .env
```

**Update the following** (use same values on both VMs):

```bash
# Deployment mode
DEPLOYMENT_MODE=production

# YugabyteDB (same credentials on both nodes)
YUGABYTE_DB=keycloak_prod
YUGABYTE_USER=keycloak_prod
YUGABYTE_PASSWORD=STRONG_PASSWORD_HERE

# DragonflyDB (same password on both nodes)
DRAGONFLY_PASSWORD=STRONG_DRAGONFLY_PASSWORD

# Keycloak (use VIP as hostname)
KEYCLOAK_HOSTNAME=idaas.example.com  # Points to VIP
KEYCLOAK_ADMIN=admin
KEYCLOAK_ADMIN_PASSWORD=STRONG_ADMIN_PASSWORD

# WebApp
SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_hex(32))")
APP_HOSTNAME=app.example.com  # Points to VIP

# OAuth2 Proxy
OAUTH2_CLIENT_ID=webapp-client
OAUTH2_CLIENT_SECRET=STRONG_CLIENT_SECRET
OAUTH2_COOKIE_SECRET=$(python3 -c "import secrets; print(secrets.token_urlsafe(32)[:32])")
OAUTH2_EMAIL_DOMAINS=*

# Build info
BUILD_DATE=$(date +%Y-%m-%d)
VCS_REF=$(git rev-parse --short HEAD)
APP_VERSION=1.0.0
```

**IMPORTANT**: Use the same `.env` file on both VMs to ensure consistent configuration.

---

## Load Balancer Configuration

### HAProxy Configuration

**On both VMs**, create `/etc/haproxy/haproxy.cfg`:

```bash
sudo nano /etc/haproxy/haproxy.cfg
```

```haproxy
#---------------------------------------------------------------------
# Global settings
#---------------------------------------------------------------------
global
    log /dev/log local0
    log /dev/log local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin
    stats timeout 30s
    user haproxy
    group haproxy
    daemon

    # Default SSL material locations
    ca-base /etc/ssl/certs
    crt-base /etc/ssl/private

    # Modern SSL configuration
    ssl-default-bind-ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384
    ssl-default-bind-options ssl-min-ver TLSv1.2 no-tls-tickets

#---------------------------------------------------------------------
# Common defaults
#---------------------------------------------------------------------
defaults
    log     global
    mode    http
    option  httplog
    option  dontlognull
    option  http-server-close
    option  forwardfor except 127.0.0.0/8
    option  redispatch
    retries 3
    timeout connect 5000
    timeout client  50000
    timeout server  50000
    errorfile 400 /etc/haproxy/errors/400.http
    errorfile 403 /etc/haproxy/errors/403.http
    errorfile 408 /etc/haproxy/errors/408.http
    errorfile 500 /etc/haproxy/errors/500.http
    errorfile 502 /etc/haproxy/errors/502.http
    errorfile 503 /etc/haproxy/errors/503.http
    errorfile 504 /etc/haproxy/errors/504.http

#---------------------------------------------------------------------
# Statistics page
#---------------------------------------------------------------------
listen stats
    bind *:8404
    stats enable
    stats uri /stats
    stats refresh 30s
    stats show-legends
    stats admin if TRUE

#---------------------------------------------------------------------
# Frontend - HTTP (redirect to HTTPS)
#---------------------------------------------------------------------
frontend http_front
    bind 192.168.1.100:80  # Bind to VIP
    mode http
    redirect scheme https code 301 if !{ ssl_fc }

#---------------------------------------------------------------------
# Frontend - HTTPS
#---------------------------------------------------------------------
frontend https_front
    bind 192.168.1.100:443 ssl crt /etc/ssl/private/idaas.pem  # Bind to VIP
    mode http
    option forwardfor

    # ACL rules
    acl is_keycloak hdr(host) -i auth.example.com
    acl is_app hdr(host) -i app.example.com

    # Route to backends
    use_backend keycloak_back if is_keycloak
    use_backend app_back if is_app
    default_backend app_back

#---------------------------------------------------------------------
# Backend - Keycloak
#---------------------------------------------------------------------
backend keycloak_back
    mode http
    balance roundrobin
    option httpchk GET /health/ready
    http-check expect status 200

    # Sticky sessions based on cookie
    cookie SERVERID insert indirect nocache

    # Backend servers
    server node1 192.168.1.101:8080 check cookie node1 inter 2s rise 2 fall 3
    server node2 192.168.1.102:8080 check cookie node2 inter 2s rise 2 fall 3

#---------------------------------------------------------------------
# Backend - Application (OAuth2 Proxy)
#---------------------------------------------------------------------
backend app_back
    mode http
    balance roundrobin
    option httpchk GET /ping
    http-check expect status 200

    # Sticky sessions based on cookie
    cookie SERVERID insert indirect nocache

    # Backend servers
    server node1 192.168.1.101:4180 check cookie node1 inter 2s rise 2 fall 3
    server node2 192.168.1.102:4180 check cookie node2 inter 2s rise 2 fall 3
```

**Test configuration**:
```bash
sudo haproxy -c -f /etc/haproxy/haproxy.cfg
```

### Keepalived Configuration

**On VM 1 (Master)**, create `/etc/keepalived/keepalived.conf`:

```bash
sudo nano /etc/keepalived/keepalived.conf
```

```conf
vrrp_script check_haproxy {
    script "/usr/bin/killall -0 haproxy"
    interval 2
    weight 2
    fall 2
    rise 2
}

vrrp_instance VI_1 {
    state MASTER
    interface ens18  # Change to your network interface name
    virtual_router_id 51
    priority 101  # Higher priority = master
    advert_int 1

    authentication {
        auth_type PASS
        auth_pass STRONG_PASSWORD_HERE
    }

    virtual_ipaddress {
        192.168.1.100/24  # VIP
    }

    track_script {
        check_haproxy
    }

    # Email notifications (optional)
    # notification_email {
    #     admin@example.com
    # }
    # notification_email_from keepalived@node1
    # smtp_server localhost
    # smtp_connect_timeout 30
}
```

**On VM 2 (Backup)**, create `/etc/keepalived/keepalived.conf`:

```bash
sudo nano /etc/keepalived/keepalived.conf
```

```conf
vrrp_script check_haproxy {
    script "/usr/bin/killall -0 haproxy"
    interval 2
    weight 2
    fall 2
    rise 2
}

vrrp_instance VI_1 {
    state BACKUP
    interface ens18  # Change to your network interface name
    virtual_router_id 51
    priority 100  # Lower priority = backup
    advert_int 1

    authentication {
        auth_type PASS
        auth_pass STRONG_PASSWORD_HERE  # Same as VM 1
    }

    virtual_ipaddress {
        192.168.1.100/24  # VIP (same as VM 1)
    }

    track_script {
        check_haproxy
    }
}
```

**Note**: Change `ens18` to your actual network interface name. Find it with:
```bash
ip addr show
```

---

## Session Persistence

### Session Storage Strategy

The IDaaS platform uses **DragonflyDB (Redis-compatible)** for session storage, which provides:

1. **OAuth2 Proxy Sessions**: Stored in DragonflyDB database 1
2. **Application Sessions**: Stored in DragonflyDB database 0

### DragonflyDB Replication

**Option 1: Master-Replica (Recommended for 2 nodes)**

Configure DragonflyDB on VM 1 as master and VM 2 as replica.

**On VM 1** (`docker-compose.prod.yml`):
```yaml
dragonflydb:
  image: docker.dragonflydb.io/dragonflydb/dragonfly:v1.15.1
  command:
    - "--requirepass"
    - "${DRAGONFLY_PASSWORD}"
    - "--maxmemory"
    - "2gb"
    - "--cache_mode"
    - "--logtostderr"
```

**On VM 2** (`docker-compose.prod.yml`):
```yaml
dragonflydb:
  image: docker.dragonflydb.io/dragonflydb/dragonfly:v1.15.1
  command:
    - "--requirepass"
    - "${DRAGONFLY_PASSWORD}"
    - "--maxmemory"
    - "2gb"
    - "--cache_mode"
    - "--logtostderr"
    - "--replicaof"
    - "192.168.1.101:6379"  # Master IP
```

**Option 2: Redis Sentinel (For 3+ nodes)**

For larger deployments, use Redis Sentinel for automatic failover.

---

## Health Checks

### Application Health Endpoints

| Service | Health Endpoint | Expected Response |
|---------|----------------|-------------------|
| Keycloak | `http://localhost:8080/health/ready` | HTTP 200 |
| WebApp | `http://localhost:8081/health` | HTTP 200 |
| OAuth2 Proxy | `http://localhost:4180/ping` | HTTP 200 |
| YugabyteDB | `postgres/bin/pg_isready -h localhost -p 5433` | `accepting connections` |
| DragonflyDB | `redis-cli -a <password> ping` | `PONG` |

### HAProxy Health Checks

HAProxy performs health checks every 2 seconds:
- **Rise**: 2 successful checks → mark server as UP
- **Fall**: 3 failed checks → mark server as DOWN

View backend status:
```bash
echo "show stat" | sudo socat stdio /run/haproxy/admin.sock
```

---

## Deployment Steps

### Phase 1: Deploy Database Layer

**On both VMs**:

1. **Start YugabyteDB**:
```bash
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d yugabytedb
```

2. **Verify YugabyteDB cluster**:
```bash
# On VM 1
docker exec idaas-yugabytedb yb-admin -master_addresses 192.168.1.101:7000,192.168.1.102:7000 list_all_masters

# Should show both nodes
```

3. **Start DragonflyDB**:
```bash
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d dragonflydb
```

4. **Verify replication** (on VM 2):
```bash
docker exec idaas-dragonflydb redis-cli -a $DRAGONFLY_PASSWORD INFO replication
# Should show: role:slave
```

### Phase 2: Deploy Application Layer

**On both VMs**:

1. **Start Keycloak**:
```bash
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d keycloak
```

2. **Wait for Keycloak to be healthy**:
```bash
timeout 120 bash -c 'until curl -f http://localhost:8080/health/ready; do sleep 2; done'
```

3. **Start WebApp**:
```bash
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d webapp
```

4. **Start OAuth2 Proxy**:
```bash
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d oauth2-proxy
```

### Phase 3: Deploy Load Balancer

**On both VMs**:

1. **Start HAProxy**:
```bash
sudo systemctl start haproxy
sudo systemctl enable haproxy
```

2. **Start Keepalived**:
```bash
sudo systemctl start keepalived
sudo systemctl enable keepalived
```

3. **Verify VIP is active** (on VM 1):
```bash
ip addr show | grep 192.168.1.100
# Should show VIP on VM 1 (master)
```

---

## Testing

### Test 1: VIP Accessibility

```bash
# From external machine
ping 192.168.1.100

# Test HTTP redirect
curl -I http://192.168.1.100
# Should return: HTTP/1.1 301 Moved Permanently

# Test HTTPS (after SSL setup)
curl -k https://192.168.1.100
```

### Test 2: Load Distribution

```bash
# Monitor HAProxy stats
curl http://192.168.1.100:8404/stats

# Send multiple requests
for i in {1..100}; do
  curl -s http://192.168.1.100:8080/health/ready > /dev/null
done

# Check distribution in HAProxy stats
# Both node1 and node2 should show requests
```

### Test 3: Failover

**Simulate node failure**:

```bash
# On VM 1, stop HAProxy
sudo systemctl stop haproxy

# VIP should move to VM 2 within 3 seconds
# On VM 2
ip addr show | grep 192.168.1.100
# Should now show VIP on VM 2

# Test connectivity
curl http://192.168.1.100:8404/stats
# Should still work (now served by VM 2)

# Restart HAProxy on VM 1
sudo systemctl start haproxy
# VIP moves back to VM 1 (higher priority)
```

### Test 4: Session Persistence

```bash
# Login to application
# Restart one node
# User should remain logged in (session in DragonflyDB)
```

---

## Monitoring

### HAProxy Statistics

Access HAProxy stats:
- URL: http://192.168.1.100:8404/stats
- Shows real-time backend status, request counts, response times

### Health Check Scripts

**On both VMs**, create `/opt/health-check.sh`:

```bash
#!/bin/bash

echo "=== IDaaS Health Check ==="
echo "Date: $(date)"
echo ""

# Check VIP
echo "VIP Status:"
ip addr show | grep -q 192.168.1.100 && echo "✓ VIP is active on this node" || echo "✗ VIP is not on this node"
echo ""

# Check Docker containers
echo "Container Status:"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep idaas
echo ""

# Check Keycloak
echo "Keycloak Health:"
curl -sf http://localhost:8080/health/ready > /dev/null && echo "✓ Healthy" || echo "✗ Unhealthy"

# Check WebApp
echo "WebApp Health:"
curl -sf http://localhost:8081/health > /dev/null && echo "✓ Healthy" || echo "✗ Unhealthy"

# Check OAuth2 Proxy
echo "OAuth2 Proxy Health:"
curl -sf http://localhost:4180/ping > /dev/null && echo "✓ Healthy" || echo "✗ Unhealthy"

# Check YugabyteDB
echo "YugabyteDB Health:"
docker exec idaas-yugabytedb postgres/bin/pg_isready -h localhost -p 5433 -U keycloak_prod > /dev/null 2>&1 && echo "✓ Healthy" || echo "✗ Unhealthy"

# Check DragonflyDB
echo "DragonflyDB Health:"
docker exec idaas-dragonflydb redis-cli -a $DRAGONFLY_PASSWORD ping > /dev/null 2>&1 && echo "✓ Healthy" || echo "✗ Unhealthy"

echo ""
echo "=== End Health Check ==="
```

Make executable:
```bash
chmod +x /opt/health-check.sh
```

Run health check:
```bash
/opt/health-check.sh
```

### Automated Monitoring

Set up cron job for regular health checks:

```bash
crontab -e
```

Add:
```bash
*/5 * * * * /opt/health-check.sh >> /var/log/idaas-health.log 2>&1
```

---

## Failover Procedures

### Automatic Failover

Keepalived automatically handles failover:

1. **Master node fails** → VIP moves to backup node
2. **HAProxy fails on master** → VIP moves to backup node
3. **Network partition** → Both nodes may claim VIP (split-brain)

### Manual Failover

**Force failover to VM 2**:

```bash
# On VM 1
sudo systemctl stop keepalived

# VIP moves to VM 2
# Restart after maintenance
sudo systemctl start keepalived
```

### Planned Maintenance

**Take VM 1 offline for maintenance**:

```bash
# On VM 1
# 1. Lower Keepalived priority
sudo systemctl stop keepalived

# 2. Drain connections (wait 30 seconds)
sleep 30

# 3. Stop services
docker-compose down

# 4. Perform maintenance

# 5. Restart services
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# 6. Start Keepalived
sudo systemctl start keepalived
```

---

## Troubleshooting

### Issue: VIP not accessible

**Check Keepalived status**:
```bash
sudo systemctl status keepalived
sudo journalctl -u keepalived -f
```

**Verify VRRP packets**:
```bash
sudo tcpdump -i ens18 vrrp
# Should see VRRP advertisements
```

**Check firewall**:
```bash
sudo ufw status
sudo iptables -L -n | grep vrrp
```

### Issue: VIP on both nodes (split-brain)

**Cause**: Network partition or misconfiguration

**Resolution**:
```bash
# On both nodes
sudo systemctl stop keepalived

# Fix network issues

# Restart on backup first, then master
# VM 2
sudo systemctl start keepalived

# Wait 5 seconds

# VM 1
sudo systemctl start keepalived
```

### Issue: Backend shows DOWN in HAProxy

**Check health endpoint**:
```bash
curl http://localhost:8080/health/ready
curl http://localhost:8081/health
curl http://localhost:4180/ping
```

**Check HAProxy logs**:
```bash
sudo tail -f /var/log/haproxy.log
```

**Check backend status**:
```bash
echo "show servers state" | sudo socat stdio /run/haproxy/admin.sock
```

### Issue: Sessions not persisting

**Check DragonflyDB replication**:
```bash
# On VM 2
docker exec idaas-dragonflydb redis-cli -a $DRAGONFLY_PASSWORD INFO replication
# Should show: role:slave, master_link_status:up
```

**Check OAuth2 cookie**:
```bash
curl -v http://192.168.1.100:4180
# Should show Set-Cookie with SERVERID
```

---

## Backup and Disaster Recovery

### Backup Strategy

1. **YugabyteDB**:
   ```bash
   # On VM 1
   docker exec idaas-yugabytedb ysqlsh -h localhost -p 5433 -U keycloak_prod -d keycloak_prod -c "SELECT pg_start_backup('daily_backup');"
   # Backup yb_data volume
   tar -czf /backup/yugabyte-$(date +%Y%m%d).tar.gz /var/lib/docker/volumes/idaas2_yugabytedb_data
   docker exec idaas-yugabytedb ysqlsh -h localhost -p 5433 -U keycloak_prod -d keycloak_prod -c "SELECT pg_stop_backup();"
   ```

2. **Configuration**:
   ```bash
   tar -czf /backup/idaas-config-$(date +%Y%m%d).tar.gz /opt/IDaaS2/.env /etc/haproxy /etc/keepalived
   ```

3. **Automate backups**:
   ```bash
   crontab -e
   ```
   Add:
   ```bash
   0 2 * * * /opt/backup-idaas.sh
   ```

### Disaster Recovery

**Complete site failure**:

1. Restore VMs from backup
2. Deploy Docker containers
3. Restore YugabyteDB data
4. Start services

**Single node failure**:

1. Replace failed hardware
2. Clone repository
3. Copy `.env` from working node
4. Deploy with docker-compose
5. Services automatically rejoin cluster

---

## Performance Tuning

### HAProxy Tuning

**For high concurrency**:

```haproxy
global
    maxconn 100000
    nbproc 4  # Use 4 processes
    cpu-map 1 0
    cpu-map 2 1
    cpu-map 3 2
    cpu-map 4 3

defaults
    timeout connect 3000
    timeout client  30000
    timeout server  30000
```

### Keepalived Tuning

**For faster failover**:

```conf
vrrp_instance VI_1 {
    advert_int 1  # 1 second advertisements
    # Failover time = advert_int * (3 missed adverts) = 3 seconds
}
```

### YugabyteDB Tuning

**For high throughput**:

```yaml
yugabytedb:
  command: >
    bin/yugabyted start
    --tserver_flags="ysql_max_connections=400,shared_buffers=2GB"
```

---

## Security Best Practices

1. **SSL/TLS Certificates**:
   - Use Let's Encrypt or commercial certificates
   - Configure in HAProxy

2. **Firewall Rules**:
   - Only allow necessary ports
   - Restrict admin interfaces

3. **Strong Passwords**:
   - Use 32+ character passwords
   - Store in environment variables

4. **Regular Updates**:
   - Update Docker images monthly
   - Patch OS weekly

5. **Monitoring**:
   - Set up alerts for failures
   - Monitor logs for security events

---

## Summary

✅ **Active-Active HA** - Both nodes serve traffic
✅ **Automatic Failover** - VIP moves in 2-3 seconds
✅ **Load Balancing** - Traffic distributed evenly
✅ **Session Persistence** - Users stay logged in during failover
✅ **Database Replication** - YugabyteDB provides distributed SQL
✅ **Monitoring** - HAProxy stats and health checks
✅ **Disaster Recovery** - Backup and restore procedures

**Availability**: 99.9% (3 outages per year, <9 hours downtime)
**Failover Time**: 2-3 seconds
**RTO (Recovery Time Objective)**: <5 minutes
**RPO (Recovery Point Objective)**: <1 minute (database replication)
