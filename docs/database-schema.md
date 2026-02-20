# Database Schema Document — IDaaS
> Version: 1.0 | Last Updated: 2026-02-18 | Status: Draft
> Classification: Internal | Author: AIDD System

---

## 1. Overview

The IDaaS platform uses YugabyteDB (PostgreSQL-compatible distributed SQL) as the primary
persistence layer and DragonflyDB (Redis-compatible) for caching and session storage.
This document details the schema design, entity relationships, indexing strategy, and
data lifecycle management for both stores.

---

## 2. Database Topology

| Store | Technology | Port | Purpose | Protocol |
|-------|-----------|------|---------|----------|
| Primary SQL | YugabyteDB (DBaaS) | 5433 | Identity, sessions, policies, audit | PostgreSQL wire |
| Cache/Sessions | DragonflyDB (DBaaS) | 6379 | App cache (db0), OAuth2 Proxy sessions (db1) | Redis protocol |

**Connection String (YugabyteDB)**:
```
jdbc:postgresql://<endpoint>:5433/keycloak?ssl=true&sslmode=verify-full
```

**Connection String (DragonflyDB)**:
```
rediss://<endpoint>:6379/0  (webapp cache)
rediss://<endpoint>:6379/1  (OAuth2 Proxy sessions)
```

---

## 3. Keycloak Core Schema (YugabyteDB)

### 3.1 Realm Management

```sql
CREATE TABLE realm (
    id              VARCHAR(36)  PRIMARY KEY,
    name            VARCHAR(255) UNIQUE NOT NULL,
    display_name    VARCHAR(255),
    enabled         BOOLEAN      DEFAULT TRUE,
    ssl_required    VARCHAR(20)  DEFAULT 'external',
    registration_allowed BOOLEAN DEFAULT FALSE,
    verify_email    BOOLEAN      DEFAULT TRUE,
    login_theme     VARCHAR(255),
    account_theme   VARCHAR(255),
    admin_theme     VARCHAR(255),
    default_locale  VARCHAR(10)  DEFAULT 'en',
    access_token_lifespan   INTEGER DEFAULT 300,
    sso_session_idle_timeout INTEGER DEFAULT 1800,
    sso_session_max_lifespan INTEGER DEFAULT 36000,
    created_at      TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP    DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_realm_name ON realm(name);
```

### 3.2 User Entity

```sql
CREATE TABLE user_entity (
    id              VARCHAR(36)  PRIMARY KEY,
    realm_id        VARCHAR(36)  NOT NULL REFERENCES realm(id),
    username        VARCHAR(255) NOT NULL,
    email           VARCHAR(255),
    email_verified  BOOLEAN      DEFAULT FALSE,
    first_name      VARCHAR(255),
    last_name       VARCHAR(255),
    enabled         BOOLEAN      DEFAULT TRUE,
    created_at      TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    totp_enabled    BOOLEAN      DEFAULT FALSE,
    federation_link VARCHAR(255),
    service_account_client_link VARCHAR(36),
    not_before      INTEGER      DEFAULT 0,
    UNIQUE(realm_id, username),
    UNIQUE(realm_id, email)
);

CREATE INDEX idx_user_realm ON user_entity(realm_id);
CREATE INDEX idx_user_email ON user_entity(realm_id, email);
CREATE INDEX idx_user_federation ON user_entity(federation_link);
```

### 3.3 Credentials

```sql
CREATE TABLE credential (
    id              VARCHAR(36)  PRIMARY KEY,
    user_id         VARCHAR(36)  NOT NULL REFERENCES user_entity(id) ON DELETE CASCADE,
    type            VARCHAR(50)  NOT NULL,  -- 'password', 'otp', 'webauthn'
    credential_data TEXT         NOT NULL,   -- JSON: algorithm, hash, iterations
    secret_data     TEXT,                    -- Encrypted secret material
    priority        INTEGER      DEFAULT 10,
    created_at      TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    salt            BYTEA
);

CREATE INDEX idx_credential_user ON credential(user_id);
CREATE INDEX idx_credential_type ON credential(user_id, type);
```

### 3.4 Client Registration

```sql
CREATE TABLE client (
    id                  VARCHAR(36)  PRIMARY KEY,
    realm_id            VARCHAR(36)  NOT NULL REFERENCES realm(id),
    client_id           VARCHAR(255) NOT NULL,  -- OAuth2 client_id
    name                VARCHAR(255),
    description         TEXT,
    enabled             BOOLEAN      DEFAULT TRUE,
    protocol            VARCHAR(20)  DEFAULT 'openid-connect', -- 'openid-connect', 'saml'
    public_client       BOOLEAN      DEFAULT FALSE,
    bearer_only         BOOLEAN      DEFAULT FALSE,
    consent_required    BOOLEAN      DEFAULT FALSE,
    direct_access_grants_enabled BOOLEAN DEFAULT FALSE,
    service_accounts_enabled     BOOLEAN DEFAULT FALSE,
    root_url            VARCHAR(512),
    base_url            VARCHAR(512),
    secret              VARCHAR(255),
    registration_token  VARCHAR(255),
    created_at          TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(realm_id, client_id)
);

CREATE INDEX idx_client_realm ON client(realm_id);
```

### 3.5 Roles and Permissions

```sql
CREATE TABLE keycloak_role (
    id              VARCHAR(36)  PRIMARY KEY,
    realm_id        VARCHAR(36)  REFERENCES realm(id),
    client_id       VARCHAR(36)  REFERENCES client(id),
    name            VARCHAR(255) NOT NULL,
    description     TEXT,
    composite       BOOLEAN      DEFAULT FALSE,
    client_role     BOOLEAN      DEFAULT FALSE
);

CREATE TABLE user_role_mapping (
    user_id         VARCHAR(36)  NOT NULL REFERENCES user_entity(id) ON DELETE CASCADE,
    role_id         VARCHAR(36)  NOT NULL REFERENCES keycloak_role(id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, role_id)
);

CREATE TABLE keycloak_group (
    id              VARCHAR(36)  PRIMARY KEY,
    realm_id        VARCHAR(36)  NOT NULL REFERENCES realm(id),
    name            VARCHAR(255) NOT NULL,
    parent_group    VARCHAR(36)  REFERENCES keycloak_group(id)
);

CREATE TABLE user_group_membership (
    user_id         VARCHAR(36)  NOT NULL REFERENCES user_entity(id) ON DELETE CASCADE,
    group_id        VARCHAR(36)  NOT NULL REFERENCES keycloak_group(id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, group_id)
);

CREATE TABLE group_role_mapping (
    group_id        VARCHAR(36)  NOT NULL REFERENCES keycloak_group(id) ON DELETE CASCADE,
    role_id         VARCHAR(36)  NOT NULL REFERENCES keycloak_role(id) ON DELETE CASCADE,
    PRIMARY KEY (group_id, role_id)
);
```

### 3.6 Sessions

```sql
CREATE TABLE user_session (
    id              VARCHAR(36)  PRIMARY KEY,
    user_id         VARCHAR(36)  NOT NULL REFERENCES user_entity(id) ON DELETE CASCADE,
    realm_id        VARCHAR(36)  NOT NULL REFERENCES realm(id),
    ip_address      VARCHAR(45),
    auth_method     VARCHAR(50),
    broker_session_id VARCHAR(255),
    started         TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    last_session_refresh TIMESTAMP,
    remember_me     BOOLEAN      DEFAULT FALSE,
    state           VARCHAR(20)  DEFAULT 'ACTIVE'
);

CREATE INDEX idx_session_user ON user_session(user_id);
CREATE INDEX idx_session_realm ON user_session(realm_id);
CREATE INDEX idx_session_started ON user_session(started);
```

### 3.7 Audit Events

```sql
CREATE TABLE event_entity (
    id              VARCHAR(36)  PRIMARY KEY,
    realm_id        VARCHAR(36)  NOT NULL,
    type            VARCHAR(100) NOT NULL,  -- LOGIN, LOGIN_ERROR, REGISTER, CODE_TO_TOKEN, etc.
    user_id         VARCHAR(36),
    client_id       VARCHAR(255),
    ip_address      VARCHAR(45),
    details_json    JSONB,
    error           VARCHAR(255),
    event_time      TIMESTAMP    DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_event_realm_time ON event_entity(realm_id, event_time DESC);
CREATE INDEX idx_event_user ON event_entity(user_id, event_time DESC);
CREATE INDEX idx_event_type ON event_entity(type, event_time DESC);
-- Partition by month for audit retention
```

---

## 4. SCIM Provisioning Schema (Planned)

```sql
CREATE TABLE scim_resource (
    id              VARCHAR(36)  PRIMARY KEY,
    realm_id        VARCHAR(36)  NOT NULL REFERENCES realm(id),
    resource_type   VARCHAR(20)  NOT NULL,  -- 'User', 'Group'
    external_id     VARCHAR(255),
    display_name    VARCHAR(255),
    active          BOOLEAN      DEFAULT TRUE,
    scim_data       JSONB        NOT NULL,
    meta_created    TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    meta_modified   TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    meta_version    VARCHAR(50)
);

CREATE TABLE scim_sync_log (
    id              SERIAL       PRIMARY KEY,
    realm_id        VARCHAR(36)  NOT NULL,
    connector_id    VARCHAR(100) NOT NULL,
    direction       VARCHAR(10)  NOT NULL,  -- 'inbound', 'outbound'
    operation       VARCHAR(20)  NOT NULL,  -- 'create', 'update', 'delete', 'reconcile'
    resource_type   VARCHAR(20)  NOT NULL,
    resource_id     VARCHAR(36),
    status          VARCHAR(20)  NOT NULL,  -- 'success', 'failure', 'conflict'
    error_message   TEXT,
    executed_at     TIMESTAMP    DEFAULT CURRENT_TIMESTAMP
);
```

---

## 5. DragonflyDB Key Schema

### 5.1 Database 0 - Webapp Cache

| Key Pattern | Type | TTL | Description |
|-------------|------|-----|-------------|
| `cache:page:{path}` | STRING | 300s | Rendered page fragment cache |
| `cache:api:{endpoint}:{hash}` | STRING | 60s | API response cache |
| `cache:user:{user_id}:profile` | HASH | 600s | User profile attributes |
| `cache:realm:{realm_id}:config` | HASH | 3600s | Realm configuration cache |
| `rate_limit:{ip}:{endpoint}` | STRING (counter) | 60s | Rate limiting counter |

### 5.2 Database 1 - OAuth2 Proxy Sessions

| Key Pattern | Type | TTL | Description |
|-------------|------|-----|-------------|
| `session:{session_id}` | STRING | 28800s | Encrypted OAuth2 Proxy session data |
| `ticket:{ticket_id}` | STRING | 300s | Session ticket for cookie validation |

---

## 6. Data Retention and Lifecycle

| Data Category | Retention | Purge Strategy |
|---------------|-----------|----------------|
| User Accounts | Account lifetime + 90 days post-deletion | Soft delete, then hard purge |
| Session Data | 8 hours (active) / 30 days (offline) | TTL-based expiry in DragonflyDB |
| Audit Events | 7 years (compliance) | Monthly partition archival to cold storage |
| Credentials | Account lifetime | Cascade delete with user_entity |
| Cache Entries | 60s - 3600s | TTL-based automatic expiry |
| SCIM Sync Logs | 1 year | Monthly archival and purge |

---

## 7. Indexing Strategy

All indexes follow the principle of covering the most common query patterns:
- **User lookup**: By realm + username, realm + email, federation link
- **Session queries**: By user_id, realm_id, and timestamp for session management
- **Audit queries**: By realm + time (descending), user, and event type
- **Role resolution**: By user_id and group_id for RBAC evaluation

---

## 8. Migration Strategy

Database migrations are managed through Keycloak's built-in Liquibase changelog system.
Custom application tables use versioned SQL migration scripts stored in `db/migrations/`.

```
db/migrations/
├── V001__initial_schema.sql
├── V002__scim_tables.sql
├── V003__audit_partitioning.sql
└── V004__performance_indexes.sql
```

---

*Document generated by the AIDD pipeline. Schema derived from Keycloak 24.x data model adapted for YugabyteDB.*
