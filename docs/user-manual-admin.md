# Administrator User Manual — IDaaS
> Version: 1.0 | Last Updated: 2026-02-18 | Status: Draft
> Classification: Internal | Author: AIDD System

---

## 1. Introduction

This manual provides step-by-step instructions for tenant administrators and platform
administrators to manage the IDaaS platform. It covers realm management, user
administration, client registration, role configuration, MFA policies, and audit review.

---

## 2. Accessing the Admin Console

### 2.1 Keycloak Admin Console

1. Navigate to `https://auth.example.com/admin/`
2. Enter admin credentials (username and password)
3. Complete MFA challenge if enabled
4. Select your tenant realm from the realm dropdown (top-left)

### 2.2 Admin Roles

| Role | Permissions |
|------|------------|
| platform-admin | Full access to all realms and platform settings |
| tenant-admin | Full access within assigned realm |
| user-manager | Create, update, disable users within realm |
| auditor | Read-only access to audit logs and reports |

---

## 3. Realm Management

### 3.1 Viewing Realm Settings

1. Select your realm from the dropdown
2. Navigate to **Realm Settings** in the left sidebar
3. Review tabs: General, Login, Email, Themes, Sessions, Tokens, Security Defenses

### 3.2 Configuring Login Settings

1. Go to **Realm Settings > Login**
2. Configure the following options:
   - **User Registration**: Enable/disable self-service registration
   - **Email as Username**: Use email address as the login identifier
   - **Forgot Password**: Enable password reset via email
   - **Verify Email**: Require email verification for new accounts
   - **Login with Email**: Allow email-based login in addition to username

### 3.3 Configuring Password Policy

1. Go to **Realm Settings > Authentication > Password Policy**
2. Add policy rules:
   - **Length**: Minimum 12 characters
   - **Uppercase**: At least 1 uppercase letter
   - **Lowercase**: At least 1 lowercase letter
   - **Digits**: At least 1 number
   - **Special Characters**: At least 1 special character
   - **Not Username**: Password cannot contain username
   - **Password History**: Prevent reuse of last 5 passwords

### 3.4 Configuring Session Timeouts

1. Go to **Realm Settings > Sessions**
2. Set the following values:
   - **SSO Session Idle**: 30 minutes (session expires after inactivity)
   - **SSO Session Max**: 10 hours (maximum session lifetime)
   - **Offline Session Idle**: 30 days (offline token expiry)
   - **Access Token Lifespan**: 5 minutes

---

## 4. User Management

### 4.1 Creating a User

1. Navigate to **Users** in the left sidebar
2. Click **Add User**
3. Fill in required fields:
   - **Username**: Unique identifier (e.g., `jdoe`)
   - **Email**: User's email address
   - **First Name** and **Last Name**
   - **Enabled**: Toggle to activate the account
   - **Email Verified**: Toggle if email is pre-verified
4. Click **Save**
5. Go to the **Credentials** tab
6. Click **Set Password**, enter temporary password
7. Toggle **Temporary** to ON (forces password change on first login)

### 4.2 Searching for Users

1. Navigate to **Users**
2. Use the search bar to find users by username, email, first name, or last name
3. Click on a user to view/edit their profile

### 4.3 Disabling a User

1. Navigate to **Users** and find the target user
2. Click on the user to open their profile
3. Toggle **Enabled** to OFF
4. Click **Save**
5. Go to **Sessions** tab and click **Logout All Sessions** to immediately revoke access

### 4.4 Managing User Groups

1. Navigate to the user's profile
2. Click the **Groups** tab
3. Click **Join Group**
4. Select the target group from the list
5. Click **Join** to add the user to the group
6. The user inherits all roles mapped to that group

---

## 5. Client Application Management

### 5.1 Registering an OIDC Client

1. Navigate to **Clients** in the left sidebar
2. Click **Create Client**
3. Configure:
   - **Client ID**: Application identifier (e.g., `my-web-app`)
   - **Client Protocol**: `openid-connect`
   - **Root URL**: Application root URL
4. Click **Next**
5. Configure authentication:
   - **Client Authentication**: ON (for confidential clients) / OFF (for public/SPA clients)
   - **Authorization**: ON (if using fine-grained permissions)
6. Click **Next**
7. Configure URIs:
   - **Valid Redirect URIs**: `https://myapp.example.com/callback`
   - **Web Origins**: `https://myapp.example.com`
   - **Post Logout Redirect URIs**: `https://myapp.example.com/`
8. Click **Save**
9. Copy **Client Secret** from the Credentials tab (for confidential clients)

### 5.2 Configuring PKCE

1. Open client settings
2. Go to **Advanced** tab
3. Set **Proof Key for Code Exchange Code Challenge Method** to `S256`
4. Save

### 5.3 Viewing Client Scopes

1. Navigate to the client
2. Click **Client Scopes** tab
3. Default scopes (always included): `openid`, `email`, `profile`, `roles`
4. Optional scopes (requested explicitly): `offline_access`, `microprofile-jwt`

---

## 6. Role and Permission Management

### 6.1 Creating Realm Roles

1. Navigate to **Realm Roles** in the left sidebar
2. Click **Create Role**
3. Enter role name (e.g., `report-viewer`) and description
4. Click **Save**

### 6.2 Creating Composite Roles

1. Open a realm role
2. Toggle **Composite** to ON
3. Search and add sub-roles that this role should include
4. Users assigned the composite role inherit all sub-roles

### 6.3 Creating Client Roles

1. Navigate to **Clients** > select client > **Roles** tab
2. Click **Create Role**
3. Enter role name (e.g., `manage-users`)
4. Client roles scope permissions to a specific application

### 6.4 Managing Groups

1. Navigate to **Groups** in the left sidebar
2. Click **Create Group**
3. Name the group (e.g., `engineering-team`)
4. Open the group and go to **Role Mapping**
5. Assign realm roles or client roles to the group
6. All members of the group inherit these roles

---

## 7. MFA Administration

### 7.1 Enabling MFA for a Realm

1. Go to **Authentication** in the left sidebar
2. Select the **Browser** flow
3. Verify the flow includes:
   - Cookie (checks existing session)
   - Username/Password Form
   - Conditional OTP (or OTP Form)
4. Ensure OTP step is set to **Required** or **Conditional**

### 7.2 Configuring OTP Policy

1. Go to **Authentication > OTP Policy**
2. Configure:
   - **OTP Type**: Time-based (TOTP)
   - **Algorithm**: SHA1 (compatible with standard authenticator apps)
   - **Number of Digits**: 6
   - **Look Ahead Window**: 1
   - **Period**: 30 seconds

### 7.3 Resetting a User's MFA

1. Navigate to the user's profile
2. Go to **Credentials** tab
3. Find the OTP credential
4. Click **Delete** to remove the TOTP enrollment
5. On next login, the user will be prompted to re-enroll

---

## 8. Audit Log Review

### 8.1 Viewing Login Events

1. Navigate to **Events** in the left sidebar
2. Select **Login Events** tab
3. Filter by:
   - **Event Type**: LOGIN, LOGIN_ERROR, LOGOUT, REGISTER, etc.
   - **User**: Specific user ID
   - **Date Range**: Start and end dates
   - **Client**: Specific application
   - **IP Address**: Source IP
4. Review event details for security investigation

### 8.2 Viewing Admin Events

1. Navigate to **Events > Admin Events** tab
2. Filter by operation type, resource type, or date range
3. Admin events capture: user creation, role changes, client modifications, realm configuration updates

### 8.3 Enabling Event Logging

1. Go to **Events > Config**
2. Enable **Save Events**: ON
3. Set **Expiration**: Configure retention period
4. Select event types to capture

---

## 9. Session Management

### 9.1 Viewing Active Sessions

1. Navigate to **Sessions** in the left sidebar
2. View all active sessions across the realm
3. Sessions show: user, IP address, start time, last access, clients

### 9.2 Terminating Sessions

- **Single user**: Go to user profile > Sessions > Logout All Sessions
- **All sessions in realm**: Sessions > Logout All (use with caution)
- **Specific client sessions**: Clients > select client > Sessions > Logout All

---

## 10. Troubleshooting

| Issue | Resolution |
|-------|-----------|
| User locked out | Reset failed login count: User > Credentials > Reset Actions |
| OIDC redirect mismatch | Verify redirect URI in client settings matches exactly |
| Token expired errors | Check clock sync between client and Keycloak; verify token lifespan settings |
| MFA not prompting | Verify authentication flow has OTP step set to Required/Conditional |
| Session not persisting | Check DragonflyDB connectivity; verify cookie settings |

---

*Document generated by the AIDD pipeline. Based on Keycloak 24.x admin console interface.*
