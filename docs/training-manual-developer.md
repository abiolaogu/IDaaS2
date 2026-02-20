# Developer Training Manual — IDaaS
> Version: 1.0 | Last Updated: 2026-02-18 | Status: Draft
> Classification: Internal | Author: AIDD System

---

## 1. Training Overview

### 1.1 Audience

This training is for software developers integrating applications with the IDaaS
platform. Prerequisites: proficiency in at least one programming language, understanding
of HTTP, REST APIs, and basic cryptography concepts (hashing, signing, encryption).

### 1.2 Learning Objectives

After this training, developers will be able to:
- Register and configure OIDC/OAuth 2.0 clients
- Implement Authorization Code flow with PKCE
- Validate JWT access tokens in backend services
- Implement RBAC using JWT claims
- Handle token refresh and session management
- Integrate with SCIM 2.0 provisioning APIs (when available)
- Debug authentication and authorization issues

### 1.3 Training Duration

| Module | Duration |
|--------|----------|
| Module 1: Identity Protocol Foundations | 1.5 hours |
| Module 2: OIDC Client Integration | 2 hours |
| Module 3: JWT Token Handling | 1.5 hours |
| Module 4: RBAC Implementation | 1 hour |
| Module 5: Advanced Patterns | 1.5 hours |
| Module 6: Debugging and Testing | 1.5 hours |
| **Total** | **9 hours** |

---

## 2. Module 1: Identity Protocol Foundations

### 2.1 OAuth 2.0 Core Concepts

**OAuth 2.0** is an authorization framework (RFC 6749) that enables applications to
obtain limited access to user accounts on an HTTP service.

**Key roles**:
- **Resource Owner**: The user who authorizes access
- **Client**: The application requesting access
- **Authorization Server**: Issues tokens (Keycloak in IDaaS)
- **Resource Server**: The API accepting tokens

**Grant types used in IDaaS**:
| Grant Type | Use Case | Client Type |
|-----------|----------|-------------|
| Authorization Code + PKCE | Web apps, SPAs, mobile apps | Confidential / Public |
| Client Credentials | Machine-to-machine, backend services | Confidential |
| Refresh Token | Extend sessions without re-authentication | Confidential / Public |
| Device Authorization | CLI tools, smart TVs, IoT | Public |

### 2.2 OpenID Connect (OIDC)

OIDC is an identity layer on top of OAuth 2.0 that adds:
- **ID Token**: JWT containing user identity claims
- **UserInfo Endpoint**: API returning user profile attributes
- **Discovery**: `.well-known/openid-configuration` for automatic endpoint discovery
- **Standard Scopes**: `openid`, `email`, `profile`, `address`, `phone`
- **Standard Claims**: `sub`, `name`, `email`, `preferred_username`, etc.

### 2.3 JWT Structure

A JWT consists of three Base64URL-encoded parts separated by dots:

```
Header.Payload.Signature

Header:  {"alg": "RS256", "typ": "JWT", "kid": "key-id"}
Payload: {"iss": "...", "sub": "...", "exp": ..., "roles": [...]}
Signature: RS256(base64url(header) + "." + base64url(payload), privateKey)
```

### 2.4 Exercise: Inspect a JWT

1. Obtain a token from the IDaaS token endpoint (client credentials flow)
2. Paste it into https://jwt.io
3. Identify: issuer, subject, audience, expiry, roles, scopes
4. Verify the signature using the JWKS endpoint public key

---

## 3. Module 2: OIDC Client Integration

### 3.1 Lab: Register a Confidential Client

1. Request your admin to create client `dev-training-app`
2. Settings: confidential, PKCE S256, redirect URI `http://localhost:5000/callback`
3. Record the client_id and client_secret

### 3.2 Lab: Implement Authorization Code Flow (Python/Flask)

```python
# Install: pip install Flask authlib requests
from flask import Flask, redirect, url_for, session
from authlib.integrations.flask_client import OAuth

app = Flask(__name__)
app.secret_key = 'training-secret-key'

oauth = OAuth(app)
keycloak = oauth.register('keycloak',
    client_id='dev-training-app',
    client_secret='YOUR_SECRET',
    server_metadata_url='https://auth.example.com/realms/training/.well-known/openid-configuration',
    client_kwargs={'scope': 'openid email profile', 'code_challenge_method': 'S256'}
)

@app.route('/')
def index():
    user = session.get('user')
    if user:
        return f"Hello, {user['preferred_username']}! Roles: {user.get('realm_access', {}).get('roles', [])}"
    return '<a href="/login">Login with IDaaS</a>'

@app.route('/login')
def login():
    return keycloak.authorize_redirect(url_for('callback', _external=True))

@app.route('/callback')
def callback():
    token = keycloak.authorize_access_token()
    session['user'] = token.get('userinfo', {})
    session['access_token'] = token['access_token']
    return redirect('/')

@app.route('/logout')
def logout():
    session.clear()
    return redirect('https://auth.example.com/realms/training/protocol/openid-connect/logout'
                    '?post_logout_redirect_uri=http://localhost:5000/')

if __name__ == '__main__':
    app.run(port=5000, debug=True)
```

### 3.3 Lab: Test the Integration

1. Run the Flask application: `python app.py`
2. Open `http://localhost:5000`
3. Click "Login with IDaaS"
4. Authenticate with your training credentials
5. Verify you see your username and roles on the page
6. Click logout and verify the session ends

### 3.4 Lab: JavaScript SPA Integration

```javascript
// Install: npm install oidc-client-ts
import { UserManager, WebStorageStateStore } from 'oidc-client-ts';

const settings = {
  authority: 'https://auth.example.com/realms/training',
  client_id: 'dev-training-spa',
  redirect_uri: 'http://localhost:3000/callback',
  post_logout_redirect_uri: 'http://localhost:3000/',
  response_type: 'code',
  scope: 'openid email profile',
  automaticSilentRenew: true,
  userStore: new WebStorageStateStore({ store: window.sessionStorage }),
};

const userManager = new UserManager(settings);

// Login
document.getElementById('login').addEventListener('click', () => {
  userManager.signinRedirect();
});

// Callback handler (on /callback page)
userManager.signinRedirectCallback().then(user => {
  document.getElementById('user').textContent =
    `Logged in as ${user.profile.preferred_username}`;
});
```

---

## 4. Module 3: JWT Token Handling

### 4.1 Lab: Token Validation in Python

```python
import jwt
from jwt import PyJWKClient

ISSUER = 'https://auth.example.com/realms/training'
JWKS_URL = f'{ISSUER}/protocol/openid-connect/certs'
AUDIENCE = 'dev-training-app'

jwks_client = PyJWKClient(JWKS_URL)

def validate_token(access_token):
    """Validate and decode a JWT access token."""
    signing_key = jwks_client.get_signing_key_from_jwt(access_token)
    decoded = jwt.decode(
        access_token,
        signing_key.key,
        algorithms=['RS256'],
        audience=AUDIENCE,
        issuer=ISSUER,
        options={'verify_exp': True}
    )
    return decoded

# Exercise: What happens if the token is expired? Modify options to test.
```

### 4.2 Lab: Token Validation in Node.js

```javascript
const jwt = require('jsonwebtoken');
const jwksClient = require('jwks-rsa');

const client = jwksClient({
  jwksUri: 'https://auth.example.com/realms/training/protocol/openid-connect/certs'
});

function getKey(header, callback) {
  client.getSigningKey(header.kid, (err, key) => {
    callback(null, key.getPublicKey());
  });
}

jwt.verify(accessToken, getKey, {
  issuer: 'https://auth.example.com/realms/training',
  audience: 'dev-training-app',
  algorithms: ['RS256']
}, (err, decoded) => {
  if (err) console.error('Token invalid:', err.message);
  else console.log('Token valid:', decoded);
});
```

### 4.3 Token Refresh Strategy

```python
import time, requests

def get_valid_token(token_data):
    """Return a valid access token, refreshing if necessary."""
    if time.time() < token_data['expires_at'] - 30:  # 30s buffer
        return token_data['access_token']

    # Refresh the token
    response = requests.post(TOKEN_URL, data={
        'grant_type': 'refresh_token',
        'refresh_token': token_data['refresh_token'],
        'client_id': CLIENT_ID,
        'client_secret': CLIENT_SECRET,
    })
    new_tokens = response.json()
    new_tokens['expires_at'] = time.time() + new_tokens['expires_in']
    return new_tokens['access_token']
```

---

## 5. Module 4: RBAC Implementation

### 5.1 Extracting Roles from JWT

```python
def get_user_roles(decoded_token):
    """Extract realm and client roles from decoded JWT."""
    realm_roles = decoded_token.get('realm_access', {}).get('roles', [])
    client_roles = decoded_token.get('resource_access', {}).get(CLIENT_ID, {}).get('roles', [])
    return {'realm': realm_roles, 'client': client_roles}
```

### 5.2 Lab: Role-Based Route Protection (Flask)

```python
from functools import wraps
from flask import request, jsonify

def require_role(role_name):
    """Decorator to enforce role-based access on Flask routes."""
    def decorator(f):
        @wraps(f)
        def wrapper(*args, **kwargs):
            token = request.headers.get('Authorization', '').replace('Bearer ', '')
            decoded = validate_token(token)
            roles = get_user_roles(decoded)
            if role_name not in roles['realm'] and role_name not in roles['client']:
                return jsonify({'error': 'Forbidden', 'required_role': role_name}), 403
            return f(*args, **kwargs)
        return wrapper
    return decorator

@app.route('/admin/users')
@require_role('user-manager')
def list_users():
    return jsonify({'users': [...]})
```

### 5.3 Exercise: Build a Protected API

Build a small Flask API with three endpoints:
- `GET /public` -- accessible without authentication
- `GET /protected` -- requires valid token (any role)
- `GET /admin` -- requires `admin` realm role

Test with tokens from users with different role assignments.

---

## 6. Module 5: Advanced Patterns

### 6.1 Backchannel Logout

```python
@app.route('/backchannel-logout', methods=['POST'])
def backchannel_logout():
    """Handle Keycloak backchannel logout notifications."""
    logout_token = request.form.get('logout_token')
    decoded = jwt.decode(logout_token, options={'verify_signature': False})
    session_id = decoded.get('sid')
    # Invalidate local session matching this session_id
    invalidate_session(session_id)
    return '', 200
```

### 6.2 Service-to-Service Authentication

```python
def get_service_token():
    """Obtain a service account token via client credentials."""
    response = requests.post(TOKEN_URL, data={
        'grant_type': 'client_credentials',
        'client_id': 'my-backend-service',
        'client_secret': SERVICE_SECRET,
        'scope': 'openid',
    })
    return response.json()['access_token']

# Use for internal API calls
headers = {'Authorization': f'Bearer {get_service_token()}'}
response = requests.get('https://internal-api.example.com/data', headers=headers)
```

---

## 7. Module 6: Debugging and Testing

### 7.1 Common Issues

| Issue | Diagnostic | Fix |
|-------|-----------|-----|
| `invalid_redirect_uri` | Redirect URI mismatch | Ensure exact match in client config |
| `invalid_grant` | Expired or reused auth code | Code is single-use, 60s TTL |
| JWT signature verification fails | Wrong JWKS URL or key rotation | Use JWKS client with caching |
| `access_denied` on protected endpoint | Missing role in token | Check realm/client role assignments |
| CORS error on SPA | Missing Web Origins | Add origin to client Web Origins |

### 7.2 Lab: Unit Testing Authentication

```python
import pytest
from unittest.mock import patch

def test_protected_route_with_valid_token(client):
    with patch('app.validate_token') as mock:
        mock.return_value = {
            'sub': 'user-123',
            'realm_access': {'roles': ['admin']},
            'resource_access': {}
        }
        response = client.get('/admin', headers={'Authorization': 'Bearer fake-token'})
        assert response.status_code == 200

def test_protected_route_without_role(client):
    with patch('app.validate_token') as mock:
        mock.return_value = {
            'sub': 'user-456',
            'realm_access': {'roles': ['viewer']},
            'resource_access': {}
        }
        response = client.get('/admin', headers={'Authorization': 'Bearer fake-token'})
        assert response.status_code == 403
```

---

## 8. Assessment

Build a complete web application that:
1. Authenticates users via OIDC Authorization Code flow with PKCE
2. Displays the logged-in user's name, email, and roles
3. Has at least one admin-only route protected by RBAC
4. Handles token refresh automatically
5. Implements logout with SSO session termination

**Evaluation Criteria**: Correct OIDC flow, proper token validation, RBAC enforcement,
clean error handling, secure secret management (no hardcoded secrets).

---

*Document generated by the AIDD pipeline. Code examples tested against Keycloak 24.x OIDC endpoints.*
