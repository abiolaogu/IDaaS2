# Developer User Manual — IDaaS
> Version: 1.0 | Last Updated: 2026-02-18 | Status: Draft
> Classification: Internal | Author: AIDD System

---

## 1. Introduction

This manual provides developers with the information needed to integrate applications
with the IDaaS platform using OpenID Connect, OAuth 2.0, SAML 2.0, and SCIM 2.0.
It covers client registration, SDK integration, token handling, and API consumption.

---

## 2. Getting Started

### 2.1 Prerequisites

- Access to an IDaaS tenant realm (contact your tenant admin)
- A registered client application (see Section 3)
- OIDC discovery URL: `https://auth.example.com/realms/{realm}/.well-known/openid-configuration`

### 2.2 OIDC Discovery

All protocol endpoints are discoverable from the well-known configuration:

```bash
curl https://auth.example.com/realms/my-org/.well-known/openid-configuration | jq .
```

Key endpoints returned:
| Endpoint | URL Pattern |
|----------|-------------|
| Authorization | `/realms/{realm}/protocol/openid-connect/auth` |
| Token | `/realms/{realm}/protocol/openid-connect/token` |
| UserInfo | `/realms/{realm}/protocol/openid-connect/userinfo` |
| JWKS | `/realms/{realm}/protocol/openid-connect/certs` |
| End Session | `/realms/{realm}/protocol/openid-connect/logout` |
| Introspection | `/realms/{realm}/protocol/openid-connect/token/introspect` |

---

## 3. Client Registration

### 3.1 Registering a Web Application (Confidential Client)

Request your tenant admin to create a client with:
- **Client ID**: Your application identifier (e.g., `my-web-app`)
- **Client Type**: Confidential (server-side applications)
- **Valid Redirect URIs**: `https://yourapp.com/callback`
- **Web Origins**: `https://yourapp.com`
- **PKCE**: S256 (recommended even for confidential clients)

You will receive:
- `client_id`: Your application identifier
- `client_secret`: Your application secret (keep secure, never expose in client-side code)

### 3.2 Registering a Single-Page Application (Public Client)

- **Client Type**: Public (no client secret)
- **PKCE**: S256 (required for public clients)
- **Valid Redirect URIs**: `https://yourapp.com/callback`
- **Web Origins**: `https://yourapp.com` (for CORS)

### 3.3 Registering a Service Account (Machine-to-Machine)

- **Client Type**: Confidential
- **Service Accounts Enabled**: Yes
- **Direct Access Grants**: No
- Assign service account roles for API access

---

## 4. Authentication Flows

### 4.1 Authorization Code Flow with PKCE (Recommended)

**Step 1: Generate PKCE Code Verifier and Challenge**

```python
import secrets, hashlib, base64

code_verifier = secrets.token_urlsafe(64)
code_challenge = base64.urlsafe_b64encode(
    hashlib.sha256(code_verifier.encode()).digest()
).rstrip(b'=').decode()
```

**Step 2: Redirect to Authorization Endpoint**

```
GET https://auth.example.com/realms/my-org/protocol/openid-connect/auth
  ?response_type=code
  &client_id=my-web-app
  &redirect_uri=https://yourapp.com/callback
  &scope=openid email profile
  &state={random_state}
  &code_challenge={code_challenge}
  &code_challenge_method=S256
```

**Step 3: Exchange Authorization Code for Tokens**

```bash
curl -X POST https://auth.example.com/realms/my-org/protocol/openid-connect/token \
  -d "grant_type=authorization_code" \
  -d "code={authorization_code}" \
  -d "redirect_uri=https://yourapp.com/callback" \
  -d "client_id=my-web-app" \
  -d "client_secret={client_secret}" \
  -d "code_verifier={code_verifier}"
```

**Response**:
```json
{
  "access_token": "eyJhbGciOiJSUzI1NiIs...",
  "token_type": "Bearer",
  "expires_in": 300,
  "refresh_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_expires_in": 1800,
  "id_token": "eyJhbGciOiJSUzI1NiIs...",
  "scope": "openid email profile"
}
```

### 4.2 Client Credentials Flow (Machine-to-Machine)

```bash
curl -X POST https://auth.example.com/realms/my-org/protocol/openid-connect/token \
  -d "grant_type=client_credentials" \
  -d "client_id=my-service" \
  -d "client_secret={client_secret}" \
  -d "scope=openid"
```

### 4.3 Refresh Token Flow

```bash
curl -X POST https://auth.example.com/realms/my-org/protocol/openid-connect/token \
  -d "grant_type=refresh_token" \
  -d "refresh_token={refresh_token}" \
  -d "client_id=my-web-app" \
  -d "client_secret={client_secret}"
```

---

## 5. Token Handling

### 5.1 JWT Access Token Structure

```json
{
  "exp": 1708300000,
  "iat": 1708299700,
  "iss": "https://auth.example.com/realms/my-org",
  "aud": "account",
  "sub": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
  "azp": "my-web-app",
  "realm_access": {
    "roles": ["end-user", "report-viewer"]
  },
  "resource_access": {
    "my-web-app": {
      "roles": ["manage-own-profile"]
    }
  },
  "scope": "openid email profile",
  "email_verified": true,
  "preferred_username": "jdoe",
  "email": "jdoe@example.com"
}
```

### 5.2 Token Validation

When receiving a JWT access token, validate:

1. **Signature**: Verify RS256 signature using JWKS endpoint public keys
2. **Issuer (iss)**: Must match `https://auth.example.com/realms/{realm}`
3. **Audience (aud)**: Must include your client_id or `account`
4. **Expiry (exp)**: Token must not be expired
5. **Not Before (nbf)**: Token must be active (if present)

**Python example using PyJWT**:
```python
import jwt
from jwt import PyJWKClient

jwks_client = PyJWKClient("https://auth.example.com/realms/my-org/protocol/openid-connect/certs")
signing_key = jwks_client.get_signing_key_from_jwt(access_token)

decoded = jwt.decode(
    access_token,
    signing_key.key,
    algorithms=["RS256"],
    audience="my-web-app",
    issuer="https://auth.example.com/realms/my-org"
)
```

### 5.3 Extracting User Roles

```python
# Realm roles
realm_roles = decoded.get("realm_access", {}).get("roles", [])

# Client-specific roles
client_roles = decoded.get("resource_access", {}).get("my-web-app", {}).get("roles", [])

# Check authorization
if "admin" in realm_roles:
    grant_admin_access()
```

---

## 6. Calling Protected APIs

### 6.1 Bearer Token Authentication

Include the access token in the Authorization header:

```bash
curl -H "Authorization: Bearer {access_token}" https://api.example.com/resource
```

### 6.2 Token Refresh Strategy

- Access tokens expire in 5 minutes; refresh proactively before expiry
- Implement token refresh 30 seconds before access token `exp`
- Handle 401 responses by attempting refresh; if refresh fails, redirect to login

---

## 7. UserInfo Endpoint

Retrieve the authenticated user's profile attributes:

```bash
curl -H "Authorization: Bearer {access_token}" \
  https://auth.example.com/realms/my-org/protocol/openid-connect/userinfo
```

**Response**:
```json
{
  "sub": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
  "email_verified": true,
  "preferred_username": "jdoe",
  "email": "jdoe@example.com",
  "given_name": "John",
  "family_name": "Doe"
}
```

---

## 8. Logout

### 8.1 RP-Initiated Logout

Redirect the user to end their SSO session:

```
GET https://auth.example.com/realms/my-org/protocol/openid-connect/logout
  ?id_token_hint={id_token}
  &post_logout_redirect_uri=https://yourapp.com/
  &client_id=my-web-app
```

### 8.2 Backchannel Logout

Configure your client to receive backchannel logout notifications:
- Set **Backchannel Logout URL** in client settings: `https://yourapp.com/backchannel-logout`
- Your endpoint receives a `logout_token` JWT when sessions are terminated

---

## 9. SCIM 2.0 Integration (Planned)

### 9.1 Provisioning Users

```bash
curl -X POST https://api.example.com/scim/v2/Users \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/scim+json" \
  -d '{
    "schemas": ["urn:ietf:params:scim:schemas:core:2.0:User"],
    "userName": "jdoe@example.com",
    "name": { "givenName": "John", "familyName": "Doe" },
    "emails": [{ "value": "jdoe@example.com", "primary": true }],
    "active": true
  }'
```

---

## 10. Common Integration Patterns

### 10.1 Flask Integration

```python
from flask import Flask, redirect, session, request
from authlib.integrations.flask_client import OAuth

app = Flask(__name__)
oauth = OAuth(app)
oauth.register('keycloak',
    client_id='my-web-app',
    client_secret='secret',
    server_metadata_url='https://auth.example.com/realms/my-org/.well-known/openid-configuration',
    client_kwargs={'scope': 'openid email profile'}
)

@app.route('/login')
def login():
    return oauth.keycloak.authorize_redirect(url_for('callback', _external=True))

@app.route('/callback')
def callback():
    token = oauth.keycloak.authorize_access_token()
    session['user'] = token['userinfo']
    return redirect('/')
```

### 10.2 JavaScript SPA (using oidc-client-ts)

```javascript
import { UserManager } from 'oidc-client-ts';

const mgr = new UserManager({
  authority: 'https://auth.example.com/realms/my-org',
  client_id: 'my-spa',
  redirect_uri: 'https://myapp.com/callback',
  response_type: 'code',
  scope: 'openid email profile',
  automaticSilentRenew: true,
});

// Login
mgr.signinRedirect();

// Callback
mgr.signinRedirectCallback().then(user => {
  console.log('Logged in:', user.profile.preferred_username);
});
```

---

## 11. Error Reference

| Error | HTTP Code | Cause | Resolution |
|-------|-----------|-------|-----------|
| `invalid_grant` | 400 | Authorization code expired or reused | Restart authorization flow |
| `invalid_client` | 401 | Wrong client_id or client_secret | Verify credentials |
| `invalid_scope` | 400 | Requested scope not allowed for client | Check client scope configuration |
| `access_denied` | 403 | User lacks required roles | Verify role assignments |
| `token_expired` | 401 | Access token expired | Refresh the token |

---

*Document generated by the AIDD pipeline. API examples based on Keycloak 24.x OIDC implementation.*
