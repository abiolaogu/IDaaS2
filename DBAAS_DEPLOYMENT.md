# DBaaS Deployment Guide

This guide explains how to deploy the IDaaS platform using managed Database-as-a-Service (DBaaS) for YugabyteDB and DragonflyDB, significantly reducing hardware requirements and operational complexity.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Benefits of DBaaS](#benefits-of-dbaas)
3. [Hardware Requirements](#hardware-requirements)
4. [DBaaS Prerequisites](#dbaas-prerequisites)
5. [Configuration](#configuration)
6. [Deployment Steps](#deployment-steps)
7. [Monitoring and Management](#monitoring-and-management)
8. [Troubleshooting](#troubleshooting)
9. [Cost Optimization](#cost-optimization)

---

## Architecture Overview

### Simplified Architecture with DBaaS

```
                        ┌─────────────────┐
                        │   Internet/     │
                        │   Network       │
                        └────────┬────────┘
                                 │
                  Virtual IP (VIP): 192.168.1.100
                                 │
            ┌────────────────────┴────────────────────┐
            │    Load Balancer (HAProxy/Keepalived)   │
            └────────────────────┬────────────────────┘
                                 │
        ┌────────────────────────┼────────────────────────┐
        │                        │                        │
┌───────▼──────────┐    ┌────────▼────────┐    ┌────────▼────────┐
│   VM 1 (Node 1)  │    │  External DBaaS │    │  VM 2 (Node 2)  │
│ Physical Server 1│    │                 │    │Physical Server 2│
├──────────────────┤    ├─────────────────┤    ├─────────────────┤
│  Keycloak        │◄───┤ YugabyteDB      │───►│  Keycloak       │
│  WebApp          │    │  (Managed)      │    │  WebApp         │
│  OAuth2 Proxy    │    │                 │    │  OAuth2 Proxy   │
│  HAProxy         │    ├─────────────────┤    │  HAProxy        │
│  Keepalived      │◄───┤ DragonflyDB     │───►│  Keepalived     │
└──────────────────┘    │  (Managed)      │    └─────────────────┘
  IP: 192.168.1.101     └─────────────────┘      IP: 192.168.1.102
```

### Key Differences from Self-Hosted

**Before (Self-Hosted Databases)**:
- 2 VMs running application + databases
- Each VM: 8 CPU cores, 32 GB RAM, 500 GB storage
- Complex database replication setup
- Manual backups and disaster recovery
- Database administration overhead

**After (DBaaS)**:
- 2 VMs running applications only
- Each VM: 4 CPU cores, 8 GB RAM, 100 GB storage
- No database management needed
- Automatic backups and HA
- Simplified operations

**Resource Savings**: ~75% reduction in VM requirements

---

## Benefits of DBaaS

### 1. **Reduced Hardware Requirements**

| Resource | Self-Hosted (per VM) | DBaaS (per VM) | Savings |
|----------|---------------------|----------------|---------|
| CPU Cores | 8 cores | 4 cores | 50% |
| RAM | 32 GB | 8 GB | 75% |
| Storage | 500 GB | 100 GB | 80% |
| **Total VMs** | 2 | 2 | Same |
| **Total RAM** | 64 GB | 16 GB | **75%** |

### 2. **Operational Benefits**

✅ **Managed Backups**: Automatic daily backups with point-in-time recovery
✅ **High Availability**: Built-in replication and automatic failover
✅ **Automatic Updates**: Database patches and upgrades managed by provider
✅ **Monitoring**: Built-in metrics and alerting
✅ **Scaling**: Easy vertical and horizontal scaling
✅ **Professional Support**: 24/7 expert support and SLAs
✅ **Disaster Recovery**: Multi-region replication options

### 3. **Cost Benefits**

- **Lower Infrastructure Costs**: Smaller VMs required
- **No Database Licensing**: Included in DBaaS pricing
- **Reduced Personnel Costs**: No DBA team needed
- **Faster Time to Market**: No database setup or tuning

### 4. **Security Benefits**

✅ Automatic security patches
✅ Encryption at rest and in transit
✅ Network isolation and VPC support
✅ Compliance certifications (SOC 2, HIPAA, etc.)
✅ Audit logging

---

## Hardware Requirements

### Minimal Requirements (with DBaaS)

**Per VM** (2 VMs total):
- **CPU**: 4 cores
- **RAM**: 8 GB
- **Storage**: 100 GB SSD
- **Network**: 1 Gbps

**Total for 2-Node HA Deployment**:
- **Total CPU**: 8 cores
- **Total RAM**: 16 GB
- **Total Storage**: 200 GB

### Recommended Requirements (with DBaaS)

**Per VM** (2 VMs total):
- **CPU**: 8 cores
- **RAM**: 16 GB
- **Storage**: 200 GB SSD
- **Network**: 10 Gbps

**Total for 2-Node HA Deployment**:
- **Total CPU**: 16 cores
- **Total RAM**: 32 GB
- **Total Storage**: 400 GB

### Comparison: Self-Hosted vs DBaaS

| Deployment Type | VMs | Total CPUs | Total RAM | Total Storage |
|----------------|-----|------------|-----------|---------------|
| **Self-Hosted DBs** | 2 | 16 cores | 64 GB | 1 TB |
| **With DBaaS (Minimal)** | 2 | 8 cores | 16 GB | 200 GB |
| **With DBaaS (Recommended)** | 2 | 16 cores | 32 GB | 400 GB |
| **Savings (Minimal)** | Same | 50% | **75%** | 80% |

---

## DBaaS Prerequisites

### 1. YugabyteDB DBaaS Instance

You need a managed YugabyteDB instance with:

**Specifications**:
- **Instance Type**: PostgreSQL-compatible
- **Version**: 2.21.0 or later
- **Storage**: 100 GB minimum
- **Connections**: 400 max connections
- **HA**: Multi-AZ deployment enabled
- **Backups**: Daily automatic backups
- **SSL/TLS**: Enabled and enforced

**Connection Details Needed**:
```
Endpoint: your-yugabyte-dbaas-endpoint:5433
Database: keycloak
Username: keycloak_prod
Password: [strong password]
Connection String: jdbc:postgresql://your-yugabyte-dbaas-endpoint:5433/keycloak?ssl=true&sslmode=require
```

**Providers** (examples):
- YugabyteDB Managed (Yugabyte Cloud)
- AWS (if they support YugabyteDB)
- Google Cloud (if they support YugabyteDB)
- Azure (if they support YugabyteDB)
- Your internal DBaaS platform

### 2. DragonflyDB DBaaS Instance

You need a managed DragonflyDB instance with:

**Specifications**:
- **Instance Type**: Redis-compatible
- **Version**: 1.15.1 or later
- **Memory**: 2 GB minimum
- **Eviction Policy**: noeviction (for sessions)
- **HA**: Replication enabled
- **Backups**: Automatic persistence
- **SSL/TLS**: Enabled

**Connection Details Needed**:
```
Endpoint: your-dragonfly-dbaas-endpoint:6379
Password: [strong password]
Database 0: For webapp cache
Database 1: For OAuth2 sessions
Connection Strings:
  - redis://:password@your-dragonfly-dbaas-endpoint:6379/0?ssl=true (cache)
  - redis://:password@your-dragonfly-dbaas-endpoint:6379/1?ssl=true (sessions)
```

**Providers** (examples):
- DragonflyDB Cloud (if available)
- Redis Enterprise (compatible alternative)
- AWS ElastiCache (Redis-compatible)
- Your internal DBaaS platform

### 3. Network Requirements

**Connectivity**:
- VMs must be able to connect to DBaaS instances
- Firewall rules allowing outbound connections on ports:
  - 5433/TCP (YugabyteDB)
  - 6379/TCP (DragonflyDB)
- If DBaaS is in different VPC/network:
  - VPC peering or VPN connection
  - Private link/endpoint connections

**Security**:
- SSL/TLS certificates for database connections
- IP whitelisting (add VM IPs to DBaaS allowlist)
- Network isolation (private endpoints preferred)

---

## Configuration

### Step 1: Obtain DBaaS Connection Details

From your DBaaS provider, collect:

1. **YugabyteDB**:
   - JDBC connection string
   - Username and password
   - SSL certificate (if custom CA)

2. **DragonflyDB**:
   - Redis connection URL
   - Password
   - SSL certificate (if custom CA)

### Step 2: Configure Environment Variables

Copy `.env.example` to `.env`:

```bash
cp .env.example .env
nano .env
```

Update the DBaaS configuration:

```bash
# YugabyteDB DBaaS
YUGABYTE_DB_URL=jdbc:postgresql://your-yugabyte-instance.cloud.yugabyte.com:5433/keycloak?ssl=true&sslmode=require
YUGABYTE_USER=keycloak_prod
YUGABYTE_PASSWORD=your-strong-password-here

# DragonflyDB DBaaS
DRAGONFLY_URL=redis://:your-dragonfly-password@your-dragonfly-instance.cloud.provider.com:6379/0?ssl=true
DRAGONFLY_SESSION_URL=redis://:your-dragonfly-password@your-dragonfly-instance.cloud.provider.com:6379/1?ssl=true

# Keycloak
KEYCLOAK_HOSTNAME=auth.example.com
KEYCLOAK_ADMIN=admin
KEYCLOAK_ADMIN_PASSWORD=secure-admin-password

# WebApp
SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_hex(32))")
APP_HOSTNAME=app.example.com

# OAuth2 Proxy
OAUTH2_CLIENT_ID=webapp-client
OAUTH2_CLIENT_SECRET=secure-client-secret
OAUTH2_COOKIE_SECRET=$(python3 -c "import secrets; print(secrets.token_urlsafe(32)[:32])")
```

### Step 3: Verify DBaaS Connectivity

Test connectivity from your VMs:

**Test YugabyteDB**:
```bash
# Install PostgreSQL client
sudo apt install postgresql-client -y

# Test connection (replace with your details)
psql "postgresql://keycloak_prod:your-password@your-yugabyte-instance.cloud.yugabyte.com:5433/keycloak?sslmode=require"

# Should see: keycloak=>
```

**Test DragonflyDB**:
```bash
# Install Redis client
sudo apt install redis-tools -y

# Test connection (replace with your details)
redis-cli -h your-dragonfly-instance.cloud.provider.com -p 6379 -a your-dragonfly-password --tls

# Should see: (connected)
# Try: PING
# Should return: PONG
```

---

## Deployment Steps

### Phase 1: Prepare VMs

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

4. **Install HAProxy** (for load balancing):
```bash
sudo apt install haproxy -y
```

5. **Install Keepalived** (for VIP):
```bash
sudo apt install keepalived -y
```

### Phase 2: Configure and Test DBaaS

1. **Verify DBaaS instances are running**:
   - YugabyteDB: Check provider dashboard
   - DragonflyDB: Check provider dashboard

2. **Test connectivity** (from both VMs):
```bash
# Test YugabyteDB
psql "$YUGABYTE_DB_URL"

# Test DragonflyDB
redis-cli -u "$DRAGONFLY_URL" PING
```

3. **Initialize Keycloak database** (one-time, from either VM):
```bash
# Keycloak will auto-create tables on first start
# Ensure database exists and user has CREATE permissions
```

### Phase 3: Deploy Application Services

**On both VMs**:

1. **Clone repository**:
```bash
cd /opt
sudo git clone https://github.com/your-org/IDaaS2.git
cd IDaaS2
sudo chown -R $USER:$USER .
```

2. **Configure environment**:
```bash
cp .env.example .env
# Edit .env with your DBaaS connection details
nano .env
```

3. **Start services**:
```bash
# Production deployment
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Check status
docker-compose ps
```

4. **Verify health**:
```bash
# Keycloak
curl http://localhost:8080/health/ready

# WebApp
curl http://localhost:8081/health

# OAuth2 Proxy
curl http://localhost:4180/ping
```

### Phase 4: Configure Load Balancer

**On both VMs**, configure HAProxy and Keepalived as per `HA_DEPLOYMENT.md` (see the HA guide for detailed HAProxy and Keepalived configuration).

**Key changes for DBaaS**:
- No health checks for databases (managed externally)
- Focus on application-level health checks only

---

## Monitoring and Management

### Application Monitoring

**Health Checks**:
```bash
# Create health check script
cat > /opt/health-check.sh << 'EOF'
#!/bin/bash
echo "=== IDaaS Health Check (DBaaS) ==="
echo "Date: $(date)"

# Check Keycloak
curl -sf http://localhost:8080/health/ready > /dev/null && echo "✓ Keycloak: Healthy" || echo "✗ Keycloak: Unhealthy"

# Check WebApp
curl -sf http://localhost:8081/health > /dev/null && echo "✓ WebApp: Healthy" || echo "✗ WebApp: Unhealthy"

# Check OAuth2 Proxy
curl -sf http://localhost:4180/ping > /dev/null && echo "✓ OAuth2 Proxy: Healthy" || echo "✗ OAuth2 Proxy: Unhealthy"

echo "=== End Health Check ==="
EOF

chmod +x /opt/health-check.sh
```

**Set up cron job**:
```bash
crontab -e
# Add:
*/5 * * * * /opt/health-check.sh >> /var/log/idaas-health.log 2>&1
```

### Database Monitoring

**YugabyteDB**:
- Monitor via provider dashboard
- Check metrics: CPU, memory, connections, queries/sec
- Set up alerts for:
  - Connection pool exhaustion
  - Slow queries
  - Replication lag

**DragonflyDB**:
- Monitor via provider dashboard
- Check metrics: Memory usage, hit rate, evictions
- Set up alerts for:
  - Memory limit approaching
  - Connection errors
  - High latency

### Application Logs

**View logs**:
```bash
# Keycloak logs
docker logs -f idaas-keycloak

# WebApp logs
docker logs -f idaas-webapp

# OAuth2 Proxy logs
docker logs -f idaas-oauth2-proxy
```

---

## Troubleshooting

### Issue: Cannot connect to YugabyteDB

**Symptoms**:
- Keycloak fails to start
- Error: "Connection refused" or "Timeout"

**Solutions**:

1. **Check network connectivity**:
```bash
telnet your-yugabyte-instance.cloud.yugabyte.com 5433
# Should connect
```

2. **Verify IP whitelist**:
   - Add VM IPs to DBaaS firewall rules
   - Check provider security groups

3. **Test with PostgreSQL client**:
```bash
psql "$YUGABYTE_DB_URL"
```

4. **Check SSL/TLS**:
```bash
# Ensure sslmode=require in connection string
# Download CA certificate if needed
```

### Issue: Cannot connect to DragonflyDB

**Symptoms**:
- OAuth2 sessions not working
- WebApp cache errors

**Solutions**:

1. **Check connectivity**:
```bash
redis-cli -h your-dragonfly-instance.cloud.provider.com -p 6379 --tls PING
# Should return: PONG
```

2. **Verify password**:
```bash
# Check DRAGONFLY_URL has correct password
echo $DRAGONFLY_URL
```

3. **Test with redis-cli**:
```bash
redis-cli -u "$DRAGONFLY_URL" PING
```

### Issue: High latency to DBaaS

**Symptoms**:
- Slow page loads
- Timeout errors

**Solutions**:

1. **Check network latency**:
```bash
ping your-yugabyte-instance.cloud.yugabyte.com
# Should be < 10ms ideally
```

2. **Use private endpoints**:
   - Configure VPC peering
   - Use private links instead of public endpoints

3. **Optimize queries**:
   - Enable slow query logging in DBaaS
   - Add database indexes

4. **Scale DBaaS instance**:
   - Increase CPU/RAM via provider console
   - Enable read replicas for read-heavy workloads

### Issue: Database connection pool exhausted

**Symptoms**:
- "Too many connections" error
- Connection timeouts

**Solutions**:

1. **Increase max connections** in DBaaS:
   - YugabyteDB: Set max_connections to 400+
   - DragonflyDB: Increase maxclients

2. **Optimize application**:
   - Reduce connection pool size in Keycloak
   - Implement connection pooling

3. **Scale horizontally**:
   - Add more application VMs
   - Distribute load

---

## Cost Optimization

### 1. Right-Size DBaaS Instances

**YugabyteDB**:
- Start small (2 vCPU, 4 GB RAM)
- Monitor CPU and memory usage
- Scale up if consistently > 70% utilization

**DragonflyDB**:
- Start with 1-2 GB memory
- Monitor hit rate and evictions
- Increase memory if hit rate < 90%

### 2. Use Reserved Instances

- Commit to 1-year or 3-year terms
- Savings: 30-50% vs on-demand

### 3. Optimize Connections

- Use connection pooling
- Close idle connections
- Limit max connections per service

### 4. Use Read Replicas

- For read-heavy workloads
- Offload read traffic from primary
- Lower cost than scaling primary

### 5. Choose the Right Region

- Co-locate DBaaS in same region as VMs
- Reduce data transfer costs
- Lower latency

### 6. Monitor and Optimize

- Set up cost alerts
- Review usage monthly
- Downsize if over-provisioned

---

## Security Best Practices

### 1. Network Security

✅ Use private endpoints (VPC peering)
✅ Enable SSL/TLS for all connections
✅ Whitelist only VM IPs
✅ Use security groups/firewalls

### 2. Authentication

✅ Use strong passwords (32+ characters)
✅ Rotate credentials quarterly
✅ Use IAM authentication (if supported)
✅ Store secrets in secret manager (e.g., AWS Secrets Manager)

### 3. Encryption

✅ Enable encryption at rest
✅ Use SSL/TLS for connections
✅ Verify certificates (sslmode=verify-full)

### 4. Monitoring and Auditing

✅ Enable audit logging
✅ Monitor access logs
✅ Set up alerts for failed logins
✅ Review logs weekly

### 5. Backups and DR

✅ Verify automatic backups are enabled
✅ Test restore procedures monthly
✅ Enable point-in-time recovery
✅ Configure multi-region replication for DR

---

## Summary

### Key Benefits of DBaaS Deployment

✅ **75% reduction in VM hardware requirements**
✅ **Simplified operations** - no database management
✅ **Built-in HA and backups** - automatic failover and recovery
✅ **Professional support** - 24/7 expert assistance
✅ **Faster deployment** - no database setup needed
✅ **Cost effective** - lower infrastructure and personnel costs
✅ **Enterprise-ready** - compliance, security, and SLAs

### Deployment Checklist

- [ ] Provision YugabyteDB DBaaS instance
- [ ] Provision DragonflyDB DBaaS instance
- [ ] Configure network connectivity (VPC peering, firewall rules)
- [ ] Update .env with DBaaS connection strings
- [ ] Test connectivity from VMs
- [ ] Deploy application services with docker-compose
- [ ] Configure load balancer (HAProxy + Keepalived)
- [ ] Set up monitoring and alerts
- [ ] Test failover scenarios
- [ ] Document DBaaS credentials in secret manager

### Next Steps

1. Follow this guide to deploy with DBaaS
2. Refer to `HA_DEPLOYMENT.md` for load balancer setup
3. See `KEYCLOAK_MFA_SETUP.md` for MFA configuration
4. Review `PLATFORM_OVERVIEW.md` for architecture details

---

**Deployment Time with DBaaS**: 2-3 hours (vs 6-8 hours with self-hosted)
**Ongoing Maintenance**: Minimal (vs significant with self-hosted)
**Cost Savings**: 40-60% total cost of ownership over 3 years
