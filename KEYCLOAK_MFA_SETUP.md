# Keycloak MFA Setup Guide

This guide explains how to configure Keycloak to support Multi-Factor Authentication (MFA) using standard TOTP (Time-based One-Time Password), which is compatible with Google Authenticator, Microsoft Authenticator, and the IDaaS Authenticator app.

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Enable TOTP in Keycloak](#enable-totp-in-keycloak)
4. [Configure Authentication Flow](#configure-authentication-flow)
5. [User Enrollment](#user-enrollment)
6. [Testing MFA](#testing-mfa)
7. [Advanced Configuration](#advanced-configuration)
8. [Troubleshooting](#troubleshooting)

---

## Overview

Keycloak has built-in support for TOTP-based MFA that works out-of-the-box with standard authenticator apps:

- **Google Authenticator** (Android, iOS)
- **Microsoft Authenticator** (Android, iOS)
- **IDaaS Authenticator** (Android, iOS)
- **Authy** (Android, iOS, Desktop)
- Any other RFC 6238 compliant TOTP app

### How It Works

1. User logs in with username and password
2. Keycloak requires MFA setup (first time) or validation (subsequent logins)
3. User scans QR code with their authenticator app
4. User enters the 6-digit code from the app
5. Access is granted

---

## Prerequisites

Before configuring MFA:

1. Keycloak instance is running (see [DEPLOYMENT.md](DEPLOYMENT.md))
2. Admin access to Keycloak admin console
3. At least one realm configured (default: `master`)
4. At least one client configured (e.g., `webapp-client`)

Access Keycloak admin console:
- **Development**: http://localhost:8080
- **Production**: https://your-keycloak-domain.com

Default credentials (development only):
- Username: `admin`
- Password: `admin`

**IMPORTANT**: Change default credentials for production!

---

## Enable TOTP in Keycloak

### Step 1: Access Authentication Settings

1. Log in to Keycloak Admin Console
2. Select your realm (e.g., `master` or your custom realm)
3. Navigate to **Authentication** → **Required Actions**

### Step 2: Enable Configure OTP

1. Find "Configure OTP" in the list
2. Check the following boxes:
   - ✅ **Enabled** - Allows users to configure OTP
   - ✅ **Default Action** - Forces users to set up OTP on first login

3. Click **Save**

### Step 3: Configure OTP Policy

1. Navigate to **Authentication** → **Policies** → **OTP Policy**
2. Configure the following settings:

| Setting | Recommended Value | Description |
|---------|-------------------|-------------|
| **OTP Type** | Time Based | Time-based (TOTP) vs Counter-based (HOTP) |
| **OTP Hash Algorithm** | SHA1 | Standard algorithm (SHA1, SHA256, SHA512) |
| **Number of Digits** | 6 | Code length (6 or 8 digits) |
| **Look Ahead Window** | 1 | Tolerance for clock skew |
| **OTP Token Period** | 30 | Code validity in seconds |
| **Supported Applications** | totpAppGoogleName, totpAppMicrosoftAuthenticatorName | Displayed app names |

3. Click **Save**

**Recommended Settings for Maximum Compatibility**:
```yaml
OTP Type: Time Based
OTP Hash Algorithm: SHA1
Number of Digits: 6
Look Ahead Window: 1
OTP Token Period: 30 seconds
```

These settings ensure compatibility with Google Authenticator, Microsoft Authenticator, and IDaaS Authenticator.

---

## Configure Authentication Flow

### Option 1: Browser Flow with Mandatory OTP (Recommended)

This configuration requires all users to use MFA.

1. Navigate to **Authentication** → **Flows**
2. Select **Browser** flow
3. Click **Copy** to create a new flow (e.g., "Browser with MFA")
4. Find **Browser with MFA Forms**
5. Add **OTP Form** execution:
   - Click **Add execution**
   - Select **OTP Form**
   - Set requirement to **REQUIRED**
6. Order should be:
   ```
   Browser with MFA Forms [ALTERNATIVE]
   ├── Username Password Form [REQUIRED]
   └── OTP Form [REQUIRED]
   ```
7. Click **Bindings** tab
8. Set **Browser Flow** to your new "Browser with MFA" flow
9. Click **Save**

### Option 2: Browser Flow with Optional OTP

This configuration makes MFA optional (user can choose).

1. Follow steps 1-5 from Option 1
2. Set **OTP Form** requirement to **ALTERNATIVE** instead of **REQUIRED**
3. Complete steps 6-9

### Option 3: Conditional OTP Based on User Role

Require MFA only for specific roles (e.g., administrators).

1. Navigate to **Authentication** → **Flows**
2. Create new flow: "Browser with Conditional MFA"
3. Add **Condition - User Role**:
   - Click **Add execution**
   - Select **Condition - User Role**
   - Configure to match role (e.g., `admin`)
   - Set to **REQUIRED**
4. Add **OTP Form** as sub-flow
5. Set requirement to **REQUIRED**
6. Bind to Browser Flow

---

## User Enrollment

### First-Time Setup

When a user logs in for the first time with MFA enabled:

1. User enters username and password
2. Keycloak displays QR code and manual entry key
3. User scans QR code with authenticator app:
   - Open Google Authenticator / Microsoft Authenticator / IDaaS Authenticator
   - Tap "+" or "Add account"
   - Scan the QR code
4. Authenticator app displays 6-digit code
5. User enters code in Keycloak
6. MFA is now configured

### Manual Entry (If QR Code Fails)

If the user cannot scan the QR code:

1. Click "Unable to scan?" on Keycloak MFA setup page
2. Keycloak displays the secret key (Base32 encoded)
3. In authenticator app:
   - Select "Enter a setup key" or "Manual entry"
   - Enter account name (e.g., "My Company - user@example.com")
   - Enter the secret key
   - Select "Time based"
   - Save
4. Enter the 6-digit code to verify

---

## Testing MFA

### Test User Login with MFA

1. Create a test user:
   - Navigate to **Users** → **Add user**
   - Username: `testuser`
   - Email: `testuser@example.com`
   - Email Verified: **ON**
   - Click **Save**

2. Set password:
   - Go to **Credentials** tab
   - Click **Set Password**
   - Enter password
   - Temporary: **OFF**
   - Click **Save**

3. Test login:
   ```bash
   # Access the application
   curl http://localhost:4180
   ```

4. Follow OAuth2 redirect to Keycloak
5. Enter username and password
6. Scan QR code with authenticator app
7. Enter 6-digit code
8. Verify successful login

### Verify TOTP Configuration

Check user's MFA status in admin console:

1. Navigate to **Users** → Select user
2. Go to **Credentials** tab
3. Verify **OTP** credential is listed
4. User can remove/reset OTP from their account page

---

## Advanced Configuration

### Customize OTP Issuer Name

The issuer name appears in authenticator apps. Customize it:

1. Navigate to **Realm Settings** → **General**
2. Set **Display name** (e.g., "My Company IDaaS")
3. This name will appear in authenticator apps

### Backup Codes

Enable recovery codes for users who lose their device:

1. Navigate to **Authentication** → **Required Actions**
2. Enable **Update TOTP** action
3. Users can regenerate TOTP from account settings

### Remember Device

Allow users to skip MFA for trusted devices:

1. Install **keycloak-remember-me** extension
2. Configure cookie-based device tracking
3. Users can check "Remember this device for 30 days"

**Note**: This feature requires additional Keycloak extensions.

### Account Console Customization

Allow users to manage MFA from account console:

1. Navigate to **Clients** → **account**
2. Ensure **Enabled** is **ON**
3. Users can access: https://your-keycloak-domain/realms/master/account
4. Users can:
   - View configured authenticators
   - Add new authenticator devices
   - Remove lost devices
   - Regenerate backup codes

---

## Troubleshooting

### Issue: "Invalid authenticator code" error

**Possible Causes**:
1. Clock skew between server and client device
2. User entering expired code (>30 seconds old)
3. Wrong OTP configuration

**Solutions**:

1. **Check Server Time**:
   ```bash
   # On Docker host
   docker exec idaas-keycloak date

   # Should match current time
   date
   ```

2. **Sync Device Clock**:
   - Android: Settings → Date & time → Use network-provided time
   - iOS: Settings → General → Date & Time → Set Automatically

3. **Increase Look Ahead Window**:
   - Navigate to **Authentication** → **Policies** → **OTP Policy**
   - Increase **Look Ahead Window** to 2 or 3
   - This allows ±1-2 time windows (±30-60 seconds)

### Issue: QR code not scanning

**Solutions**:

1. Use manual entry instead
2. Increase QR code size (zoom browser)
3. Ensure good lighting for camera
4. Try different authenticator app

### Issue: User locked out (lost device)

**Solutions**:

**Option 1: Admin Reset**:
1. Log in to Keycloak Admin Console
2. Navigate to **Users** → Select user
3. Go to **Credentials** tab
4. Delete the OTP credential
5. User will be prompted to set up new OTP on next login

**Option 2: Disable MFA Temporarily**:
1. Navigate to **Authentication** → **Required Actions**
2. Uncheck **Default Action** for "Configure OTP"
3. User can log in without MFA
4. Re-enable after user sets up new device

### Issue: MFA not required despite configuration

**Checklist**:

1. ✅ "Configure OTP" is enabled in Required Actions
2. ✅ "Configure OTP" has **Default Action** checked
3. ✅ Browser flow has OTP Form set to **REQUIRED**
4. ✅ Client is using the correct authentication flow
5. ✅ User has completed password change (if required)

**Force MFA for Specific Client**:

1. Navigate to **Clients** → Select client (e.g., `webapp-client`)
2. Go to **Authentication Flow Overrides**
3. Set **Browser Flow** to your MFA-enabled flow
4. Click **Save**

### Issue: "Setup key" not working in authenticator app

**Verify Format**:

The setup key must be:
- Base32 encoded (A-Z, 2-7)
- No spaces or special characters
- At least 16 characters long

**Common Issues**:
- User copying QR code URL instead of secret key
- Including spaces or line breaks in manual entry
- Using lowercase letters (convert to uppercase)

### Issue: TOTP codes expire too quickly

**Adjust Period**:

1. Navigate to **Authentication** → **Policies** → **OTP Policy**
2. Increase **OTP Token Period** to 60 seconds (for slower users)
3. **Note**: This reduces security slightly

---

## Security Best Practices

### Recommended Settings for Production

1. **Enforce MFA for All Users**:
   - Set OTP Form to **REQUIRED** in authentication flow
   - Enable "Configure OTP" as **Default Action**

2. **Strong Password Policy**:
   - Navigate to **Authentication** → **Policies** → **Password Policy**
   - Add: Minimum Length (12), Uppercase, Lowercase, Digit, Special Char

3. **Session Management**:
   - Navigate to **Realm Settings** → **Sessions**
   - SSO Session Idle: 30 minutes
   - SSO Session Max: 10 hours
   - Require Action Lifespan: 5 minutes

4. **Brute Force Protection**:
   - Navigate to **Realm Settings** → **Security Defenses**
   - Enable **Brute Force Detection**
   - Max Login Failures: 5
   - Wait Increment: 60 seconds
   - Max Wait: 900 seconds (15 minutes)

5. **Audit Logging**:
   - Navigate to **Realm Settings** → **Events**
   - Enable **Login Events** and **Admin Events**
   - Save Events: ON
   - Expiration: 90 days

---

## Integration with OAuth2 Proxy

The IDaaS platform uses OAuth2 Proxy as an authentication gateway. MFA is enforced at the Keycloak level, so no changes are needed to OAuth2 Proxy configuration.

**Flow**:
1. User accesses app → OAuth2 Proxy
2. OAuth2 Proxy redirects → Keycloak
3. Keycloak requires password + TOTP
4. User completes MFA
5. Keycloak returns tokens → OAuth2 Proxy
6. OAuth2 Proxy grants access → App

---

## Compatibility Matrix

| Authenticator App | Compatibility | Notes |
|-------------------|---------------|-------|
| **Google Authenticator** | ✅ Full | Works with default settings |
| **Microsoft Authenticator** | ✅ Full | Works with default settings |
| **IDaaS Authenticator** | ✅ Full | Custom app (this project) |
| **Authy** | ✅ Full | Supports cloud backup |
| **1Password** | ✅ Full | Requires 1Password subscription |
| **Bitwarden** | ✅ Full | Built-in authenticator |
| **LastPass Authenticator** | ✅ Full | Cloud backup available |
| **FreeOTP** | ✅ Full | Open source |
| **andOTP** | ✅ Full | Open source, Android only |

All listed apps support standard TOTP with:
- SHA1 algorithm
- 6 digits
- 30-second period

---

## API Integration

For programmatic TOTP validation (e.g., in custom applications):

### Validate TOTP Code

```bash
# Get access token
ACCESS_TOKEN=$(curl -X POST \
  http://localhost:8080/realms/master/protocol/openid-connect/token \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d 'grant_type=password' \
  -d 'client_id=admin-cli' \
  -d 'username=testuser' \
  -d 'password=password' \
  -d 'totp=123456' \
  | jq -r '.access_token')
```

If TOTP code is invalid, you'll receive:
```json
{
  "error": "invalid_grant",
  "error_description": "Invalid user credentials"
}
```

---

## References

- **RFC 6238**: TOTP Algorithm Specification
  - https://tools.ietf.org/html/rfc6238

- **Keycloak Documentation**: OTP Policies
  - https://www.keycloak.org/docs/latest/server_admin/#otp-policies

- **Google Authenticator**:
  - Android: https://play.google.com/store/apps/details?id=com.google.android.apps.authenticator2
  - iOS: https://apps.apple.com/app/google-authenticator/id388497605

- **Microsoft Authenticator**:
  - Android: https://play.google.com/store/apps/details?id=com.azure.authenticator
  - iOS: https://apps.apple.com/app/microsoft-authenticator/id983156458

---

## Summary

✅ **Keycloak has built-in TOTP support** - No plugins needed
✅ **Compatible with all major authenticator apps** - Google, Microsoft, IDaaS, etc.
✅ **Easy to configure** - Enable in 5 minutes
✅ **Flexible authentication flows** - Required, optional, or conditional
✅ **User-friendly** - QR code scanning or manual entry
✅ **Secure** - Industry-standard RFC 6238 implementation

**Setup Time**: 5-10 minutes
**User Enrollment Time**: 1-2 minutes per user
**Maintenance**: Minimal (handle lost device requests)
