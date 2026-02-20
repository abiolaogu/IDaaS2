# Training Video Scripts — IDaaS
> Version: 1.0 | Last Updated: 2026-02-18 | Status: Draft
> Classification: Internal | Author: AIDD System

---

## 1. Introduction

This document contains scripts for training video production covering the IDaaS platform.
Each script includes narration text, on-screen actions, duration estimates, and visual
direction notes.

---

## 2. Video 1: IDaaS Platform Overview

**Duration**: 5 minutes
**Audience**: All users (administrators, developers, end users)

### Scene 1: Introduction (0:00 - 0:45)

**Narration**:
"Welcome to the IDaaS platform -- your organization's Identity-as-a-Service solution.
IDaaS provides a single, secure way to manage authentication and access across all
your applications. In this video, we will give you a high-level overview of what IDaaS
does, how it works, and why it matters for your organization."

**On-Screen**: Title card with IDaaS logo. Transition to animated architecture diagram.

### Scene 2: What is IDaaS? (0:45 - 2:00)

**Narration**:
"IDaaS stands for Identity as a Service. It is a platform that handles three critical
functions. First, Authentication -- proving who you are when you log in. Second,
Authorization -- controlling what you are allowed to access. Third, User Lifecycle
Management -- creating, updating, and disabling accounts across your applications.

Instead of each application managing its own login system, IDaaS provides a central
identity hub. You log in once, and every connected application recognizes you. This is
called Single Sign-On, or SSO."

**On-Screen**: Animated diagram showing user logging in once, then accessing multiple apps
without re-authentication. Highlight arrows showing SSO token flow.

### Scene 3: Key Components (2:00 - 3:30)

**Narration**:
"Under the hood, IDaaS is built on four main components. Keycloak is our identity
provider -- it handles login pages, password policies, multi-factor authentication,
and token issuance using industry-standard protocols like OpenID Connect and OAuth 2.0.

OAuth2 Proxy is our authentication gateway -- it sits in front of your application and
ensures every request is authenticated before it reaches your code.

The Flask web application is the main application layer, and our data is stored in
YugabyteDB for persistent data and DragonflyDB for fast session management."

**On-Screen**: Architecture diagram with each component highlighted as it is mentioned.
Arrows showing traffic flow from user through NGINX, OAuth2 Proxy, to Keycloak and Flask.

### Scene 4: Security Features (3:30 - 4:30)

**Narration**:
"Security is built into every layer of IDaaS. All connections use TLS encryption.
Multi-Factor Authentication adds a second layer beyond passwords. Rate limiting
protects against brute-force attacks. And every authentication event is logged for
audit and compliance purposes.

Your accounts are protected by strong password policies, session timeouts, and
the ability to remotely terminate sessions from any device."

**On-Screen**: Security checklist animation with checkmarks appearing: TLS, MFA,
Rate Limiting, Audit Logging, Password Policies, Session Management.

### Scene 5: Closing (4:30 - 5:00)

**Narration**:
"That is a quick overview of the IDaaS platform. In the following videos, we will
walk through specific tasks: logging in, setting up MFA, managing users, and
integrating your applications. Thank you for watching."

**On-Screen**: Summary slide with links to additional training videos.

---

## 3. Video 2: End User - Logging In and Setting Up MFA

**Duration**: 7 minutes
**Audience**: End users

### Scene 1: Introduction (0:00 - 0:30)

**Narration**:
"In this video, we will walk through logging in to your application using IDaaS and
setting up Multi-Factor Authentication to protect your account."

**On-Screen**: Title card. Transition to browser screen recording.

### Scene 2: First-Time Login (0:30 - 2:30)

**Narration**:
"Open your web browser and navigate to your application URL. You will be redirected
to the IDaaS login page. Enter the username and temporary password provided by your
administrator, then click Sign In.

Since this is your first login, you will be asked to set a new password. Your new
password must be at least 12 characters long and include uppercase letters, lowercase
letters, numbers, and special characters. Enter your new password, confirm it, and
click Submit."

**On-Screen**: Screen recording of full login flow: navigate to app URL, redirected
to Keycloak login page, enter credentials, password change form, new password entry.

### Scene 3: MFA Enrollment (2:30 - 4:30)

**Narration**:
"After setting your password, you may see a QR code on screen. This is the MFA
enrollment step. Open the IDaaS MFA Authenticator app on your phone -- or any
standard authenticator app like Google Authenticator.

Tap the plus button to add a new account, then select Scan QR Code. Point your
phone camera at the QR code on your computer screen. The app will add your account
and start showing a 6-digit code that changes every 30 seconds.

Enter the current 6-digit code into the field on your computer and click Submit.
MFA is now set up."

**On-Screen**: Split screen: computer showing QR code on left, phone camera
scanning QR on right. Code entry demonstration. Success confirmation.

### Scene 4: Regular Login with MFA (4:30 - 5:30)

**Narration**:
"From now on, when you log in, you will enter your username and password as
usual, and then you will see a prompt for your authentication code. Open your
authenticator app, find the code for your IDaaS account, and enter it. If the
code is about to expire -- watch the countdown timer -- wait for the next code.

After entering the code, click Submit, and you are in."

**On-Screen**: Full login flow with MFA step. Highlight the 30-second countdown timer.

### Scene 5: SSO in Action (5:30 - 6:15)

**Narration**:
"Now here is the power of Single Sign-On. While you are logged in, open a new
tab and navigate to another IDaaS-connected application. Notice that you are
automatically logged in -- no password, no MFA prompt. Your session is shared
across all connected applications."

**On-Screen**: Open new tab, navigate to second app, show automatic login.

### Scene 6: Closing (6:15 - 7:00)

**Narration**:
"That covers logging in and setting up MFA. Remember: never share your password
or MFA codes with anyone, and always log out when using shared computers. If you
have any issues, contact your IT help desk."

**On-Screen**: Summary slide with key reminders.

---

## 4. Video 3: Administrator - Managing Users and Roles

**Duration**: 10 minutes
**Audience**: Tenant administrators

### Scene 1: Introduction (0:00 - 0:30)

**Narration**:
"In this video, we will cover user management and role configuration in the IDaaS
admin console. You will learn how to create users, assign roles, manage groups, and
review audit logs."

### Scene 2: Accessing the Admin Console (0:30 - 1:30)

**Narration**:
"Navigate to the Keycloak admin console at auth.example.com/admin. Log in with
your administrator credentials and complete the MFA challenge. Once logged in,
select your tenant realm from the dropdown in the top-left corner."

**On-Screen**: Screen recording of admin console login and realm selection.

### Scene 3: Creating a User (1:30 - 3:30)

**Narration**:
"To create a new user, click Users in the left sidebar, then click Add User.
Enter the username, email address, first name, and last name. Toggle Enabled to
ON and Email Verified if the email is pre-confirmed. Click Save.

Now go to the Credentials tab and click Set Password. Enter a temporary password
and make sure the Temporary toggle is ON. This forces the user to change their
password on first login."

**On-Screen**: Step-by-step user creation with field highlights.

### Scene 4: Configuring Roles and Groups (3:30 - 6:00)

**Narration**:
"Navigate to Realm Roles and click Create Role. Let us create three roles: viewer,
editor, and admin. For the admin role, we will make it a composite role that includes
both viewer and editor.

Now go to Groups and create a group called engineering. Open the group, go to Role
Mapping, and assign the editor role. Create a subgroup called leads and assign the
admin composite role.

When you add users to the engineering group, they automatically inherit the editor
role. Users in the leads subgroup inherit the admin role, which includes both viewer
and editor."

**On-Screen**: Role creation, composite role setup, group creation, role mapping
demonstration.

### Scene 5: Reviewing Audit Logs (6:00 - 8:00)

**Narration**:
"For security monitoring, navigate to Events in the left sidebar. The Login Events
tab shows all authentication attempts -- both successful and failed. You can filter
by event type, user, date range, and IP address.

The Admin Events tab shows all administrative actions: user creation, role changes,
client modifications. This is critical for compliance auditing and security
investigations."

**On-Screen**: Event log browsing with filter demonstrations.

### Scene 6: Disabling a User (8:00 - 9:00)

**Narration**:
"To disable a user, find them in the Users list, open their profile, and toggle
Enabled to OFF. Then go to the Sessions tab and click Logout All Sessions to
immediately terminate their active sessions. The user can no longer authenticate
until re-enabled."

**On-Screen**: User disable and session termination demonstration.

### Scene 7: Closing (9:00 - 10:00)

**Narration**:
"That covers the core administrative tasks. Remember to regularly review audit
logs, enforce MFA across your realm, and promptly disable accounts for departing
employees. For more advanced topics, see the administrator training manual."

---

## 5. Video 4: Developer - Integrating with IDaaS

**Duration**: 12 minutes
**Audience**: Application developers

### Scene 1: Introduction (0:00 - 0:30)

**Narration**:
"In this video, we will walk through integrating a web application with IDaaS
using OpenID Connect. We will register a client, implement the authorization code
flow, validate tokens, and enforce role-based access control."

### Scene 2: OIDC Discovery (0:30 - 1:30)

**Narration**:
"Every IDaaS realm exposes an OIDC discovery endpoint at a well-known URL. This
returns all the endpoints you need: authorization, token, userinfo, and JWKS.
Most OIDC libraries can auto-configure from this single URL."

**On-Screen**: Terminal showing curl to discovery endpoint with JSON response.

### Scene 3: Client Registration (1:30 - 3:00)

**Narration**:
"Ask your tenant admin to register your application as an OIDC client. For a
server-side web app, use a confidential client with PKCE enabled. For a
single-page application, use a public client -- PKCE is mandatory in that case.
You will receive a client_id and, for confidential clients, a client_secret."

**On-Screen**: Admin console client registration walkthrough.

### Scene 4: Code Implementation (3:00 - 7:00)

**Narration**:
"Let us implement the full flow in Python with Flask and Authlib..."

**On-Screen**: Code editor showing step-by-step implementation of the Flask OIDC
integration. Code appears incrementally with highlights on key sections.

### Scene 5: Token Validation (7:00 - 9:00)

**Narration**:
"When your application receives an access token, you must validate it before
trusting its claims. Fetch the public key from the JWKS endpoint, verify the
RS256 signature, check the issuer, audience, and expiration. Never skip signature
verification in production."

**On-Screen**: Code showing PyJWT token validation with JWKS.

### Scene 6: RBAC Implementation (9:00 - 11:00)

**Narration**:
"To enforce role-based access control, extract roles from the JWT claims and
check them before granting access. The realm_access.roles array contains realm-wide
roles, and resource_access contains client-specific roles."

**On-Screen**: Code showing role extraction and `@require_role` decorator pattern.

### Scene 7: Closing (11:00 - 12:00)

**Narration**:
"You now have a fully integrated application with OIDC authentication and RBAC
authorization. For advanced patterns like backchannel logout, service-to-service
auth, and SCIM integration, refer to the developer training manual and API docs."

---

## 6. Production Notes

### Recording Requirements

| Element | Specification |
|---------|---------------|
| Resolution | 1920x1080 (1080p) minimum |
| Frame Rate | 30 FPS |
| Audio | Professional microphone, noise-free environment |
| Screen Recording | OBS Studio or similar |
| Browser | Chrome (latest) with default zoom |
| Code Editor | VS Code with high-contrast theme |
| Captions | Required (SRT format) |

### Post-Production

- Add intro/outro title cards with IDaaS branding
- Include chapter markers for each scene
- Generate closed captions in English
- Export in MP4 (H.264) and WebM formats
- Upload to internal training platform with topic tags

---

*Document generated by the AIDD pipeline. Scripts designed for professional video production.*
