# Administrator Training Manual — IDaaS
> Version: 1.0 | Last Updated: 2026-02-18 | Status: Draft
> Classification: Internal | Author: AIDD System

---

## 1. Training Overview

### 1.1 Audience

This training manual is designed for Tenant Administrators and Platform Administrators
who manage the IDaaS platform. Prerequisite knowledge: basic understanding of identity
management concepts, web application administration, and Kubernetes operations.

### 1.2 Learning Objectives

Upon completing this training, administrators will be able to:
- Configure and manage Keycloak realms for multi-tenant environments
- Create and manage users, roles, groups, and client applications
- Configure authentication flows including MFA enforcement
- Monitor audit logs and respond to security events
- Troubleshoot common authentication and authorization issues
- Manage CI/CD pipeline operations for platform updates

### 1.3 Training Duration

| Module | Duration | Format |
|--------|----------|--------|
| Module 1: Platform Overview | 1 hour | Lecture + Demo |
| Module 2: Realm and Tenant Management | 2 hours | Hands-on Lab |
| Module 3: User and Role Administration | 2 hours | Hands-on Lab |
| Module 4: Client Application Setup | 1.5 hours | Hands-on Lab |
| Module 5: MFA and Security Policies | 1.5 hours | Hands-on Lab |
| Module 6: Monitoring and Audit | 1 hour | Demo + Lab |
| Module 7: Troubleshooting | 1 hour | Scenario-based |
| **Total** | **10 hours** | |

---

## 2. Module 1: Platform Overview

### 2.1 Architecture Review

The IDaaS platform consists of:
- **Keycloak**: Central identity provider handling OIDC, OAuth 2.0, SAML, LDAP, MFA
- **OAuth2 Proxy**: Authentication enforcement gateway
- **Flask Web Application**: Application UI and business logic
- **YugabyteDB**: Distributed SQL database (managed DBaaS)
- **DragonflyDB**: In-memory session and cache store (managed DBaaS)
- **Kubernetes**: Container orchestration runtime

### 2.2 Admin Access Points

| Console | URL | Purpose |
|---------|-----|---------|
| Keycloak Admin | `https://auth.example.com/admin/` | Realm, user, client management |
| Application | `https://app.example.com` | End-user application |
| Kubernetes | `kubectl` CLI | Infrastructure management |
| CI/CD | GitHub Actions / Jenkins / Tekton | Deployment pipelines |

### 2.3 Key Concepts

- **Realm**: An isolated identity domain for a tenant organization
- **Client**: An application registered to authenticate users via OIDC/SAML
- **Role**: A permission that can be assigned to users or groups
- **Group**: A collection of users sharing common role assignments
- **Authentication Flow**: The sequence of steps a user completes to authenticate

---

## 3. Module 2: Realm and Tenant Management

### 3.1 Lab: Creating a New Tenant Realm

**Objective**: Create a fully configured realm for a new tenant organization.

**Steps**:
1. Log into Keycloak Admin Console as `platform-admin`
2. Click the realm dropdown (top-left) > **Create Realm**
3. Enter realm name: `training-tenant-01`
4. Click **Create**

**Configure Login Settings**:
1. Go to **Realm Settings > Login**
2. Enable: User Registration, Forgot Password, Verify Email
3. Set Login with Email: ON

**Configure Email Provider**:
1. Go to **Realm Settings > Email**
2. Enter SMTP settings (host, port, from address, authentication)
3. Click **Test Connection** to verify

**Configure Themes**:
1. Go to **Realm Settings > Themes**
2. Set Login Theme, Account Theme, Admin Theme, Email Theme

**Exercise**: Create a second realm `training-tenant-02` and configure different
password policies for each realm.

### 3.2 Lab: Session and Token Configuration

1. Go to **Realm Settings > Tokens**
2. Set Access Token Lifespan: 300 seconds (5 minutes)
3. Set SSO Session Idle: 1800 seconds (30 minutes)
4. Set SSO Session Max: 36000 seconds (10 hours)
5. **Discussion**: Why are short-lived access tokens important for security?

---

## 4. Module 3: User and Role Administration

### 4.1 Lab: User Lifecycle Management

**Create a User**:
1. Navigate to **Users > Add User**
2. Enter: username `trainee01`, email `trainee01@example.com`, first/last name
3. Enable the account and set email as verified
4. Set a temporary password on the Credentials tab

**Verify Login**:
1. Open an incognito browser window
2. Navigate to `https://app.example.com`
3. Log in as `trainee01` with the temporary password
4. Complete the password change flow

**Disable and Re-enable**:
1. Return to admin console
2. Disable the user (toggle Enabled OFF)
3. Attempt login in incognito -- verify access is denied
4. Re-enable the user and verify login succeeds

### 4.2 Lab: RBAC Configuration

**Create Roles**:
1. Go to **Realm Roles > Create Role**
2. Create: `viewer`, `editor`, `admin`
3. Make `admin` a composite role containing `viewer` and `editor`

**Create Groups**:
1. Go to **Groups > Create Group**: `engineering`
2. Open group > **Role Mapping** > Assign `editor` role
3. Create subgroup: `engineering/leads`
4. Assign `admin` role to `engineering/leads`

**Assign Users**:
1. Add `trainee01` to `engineering` group
2. Verify inherited roles on user's Role Mapping tab
3. Move user to `engineering/leads` and verify composite role inheritance

**Exercise**: Inspect the JWT access token (use jwt.io) and locate the realm_access.roles
claim. Verify the roles match the group assignments.

---

## 5. Module 4: Client Application Setup

### 5.1 Lab: Register an OIDC Client

1. Go to **Clients > Create Client**
2. Client ID: `training-app`
3. Client Protocol: `openid-connect`
4. Client Authentication: ON (confidential)
5. Click **Next**, then set:
   - Valid Redirect URIs: `http://localhost:8080/callback`
   - Web Origins: `http://localhost:8080`
6. Save and copy the Client Secret from the Credentials tab

### 5.2 Lab: Test the OIDC Flow

Use `curl` to test the client credentials flow:
```bash
curl -X POST https://auth.example.com/realms/training-tenant-01/protocol/openid-connect/token \
  -d "grant_type=client_credentials" \
  -d "client_id=training-app" \
  -d "client_secret={your_secret}"
```

Decode the returned access_token at https://jwt.io and inspect claims.

### 5.3 Lab: Configure PKCE

1. Open `training-app` client settings
2. Go to **Advanced** tab
3. Set Proof Key for Code Exchange: `S256`
4. **Discussion**: When is PKCE required vs. recommended?

---

## 6. Module 5: MFA and Security Policies

### 6.1 Lab: Enable TOTP MFA

1. Go to **Authentication > Browser Flow**
2. Verify the flow includes: Cookie > Identity Provider Redirector > Forms
3. Under Forms, ensure **OTP Form** is set to **Required** (or **Conditional**)
4. Go to **Authentication > OTP Policy**
5. Configure: TOTP, SHA1, 6 digits, 30-second period

### 6.2 Lab: Enroll and Test MFA

1. Log in as `trainee01` in an incognito window
2. The system prompts for TOTP enrollment
3. Scan the QR code with an authenticator app
4. Enter the 6-digit code
5. Log out and log back in to verify MFA is prompted

### 6.3 Lab: Brute-Force Protection

1. Go to **Realm Settings > Security Defenses > Brute Force Detection**
2. Enable with: Max Login Failures: 5, Wait Increment: 60s, Max Wait: 900s
3. **Test**: Attempt 6 failed logins and verify lockout behavior
4. As admin, unlock the user via **Users > Credentials > Reset Actions**

### 6.4 Lab: Security Headers Review

Verify security headers on the application using browser developer tools:
- `Strict-Transport-Security`
- `Content-Security-Policy`
- `X-Frame-Options`
- `X-Content-Type-Options`

---

## 7. Module 6: Monitoring and Audit

### 7.1 Lab: Audit Log Analysis

1. Navigate to **Events > Login Events**
2. Filter for LOGIN_ERROR events in the last 24 hours
3. Identify the user, IP address, and error details
4. **Scenario**: An executive reports unauthorized access. Walk through the event
   log investigation process to determine if the account was compromised.

### 7.2 Lab: Admin Event Review

1. Navigate to **Events > Admin Events**
2. Filter for events in the last 7 days
3. Identify who made changes to client configurations
4. Review the operation type and resource details

### 7.3 Health Check Monitoring

Verify service health endpoints:
```bash
curl https://auth.example.com/health/live    # Keycloak liveness
curl https://auth.example.com/health/ready   # Keycloak readiness
curl https://app.example.com/health          # Flask health
curl https://app.example.com/metrics         # Flask metrics
```

---

## 8. Module 7: Troubleshooting

### 8.1 Common Scenarios

| Scenario | Diagnostic Steps | Resolution |
|----------|------------------|-----------|
| User cannot log in | Check Events for LOGIN_ERROR; verify account enabled; check brute-force lockout | Unlock account; reset password; verify MFA |
| OIDC redirect error | Verify redirect URI matches client configuration exactly | Update client redirect URIs |
| Token validation fails | Check clock synchronization; verify JWKS endpoint accessible | Fix clock skew; check network connectivity |
| Session expires unexpectedly | Review session timeout settings; check DragonflyDB connectivity | Adjust timeouts; verify DragonflyDB health |
| MFA prompt not appearing | Verify authentication flow has OTP step; check user OTP enrollment | Set OTP to Required in flow |

### 8.2 Lab: Troubleshooting Exercise

Given a set of error scenarios, diagnose and resolve each issue:
1. User `trainee01` reports "Invalid redirect URI" when logging in
2. API consumer reports 401 errors with valid-looking tokens
3. Admin reports that new users are not receiving verification emails

---

## 9. Assessment

### 9.1 Knowledge Check

After completing all modules, administrators should complete the assessment quiz
covering realm management, user administration, OIDC concepts, MFA configuration,
and troubleshooting procedures.

**Passing Score**: 80%

---

*Document generated by the AIDD pipeline. Training content aligned with Keycloak 24.x admin procedures.*
