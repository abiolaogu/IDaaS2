# End User Manual — IDaaS
> Version: 1.0 | Last Updated: 2026-02-18 | Status: Draft
> Classification: Internal | Author: AIDD System

---

## 1. Introduction

Welcome to the IDaaS platform. This manual guides you through logging in to your
applications, setting up multi-factor authentication, managing your profile, and
performing self-service account operations.

---

## 2. Logging In

### 2.1 First-Time Login

1. Open your application URL in a web browser (e.g., `https://app.example.com`)
2. You will be redirected to the IDaaS login page
3. Enter the **username** and **temporary password** provided by your administrator
4. Click **Sign In**
5. You will be prompted to set a new password
6. Enter a new password that meets the following requirements:
   - At least 12 characters long
   - Contains at least 1 uppercase letter (A-Z)
   - Contains at least 1 lowercase letter (a-z)
   - Contains at least 1 number (0-9)
   - Contains at least 1 special character (!@#$%^&*)
   - Cannot contain your username
7. Confirm the new password and click **Submit**
8. If MFA is required, you will be guided through MFA setup (see Section 3)

### 2.2 Regular Login

1. Open your application URL
2. Enter your **username** (or email) and **password**
3. Click **Sign In**
4. If MFA is enabled, enter your 6-digit code from the authenticator app
5. You are now logged in

### 2.3 Single Sign-On (SSO)

Once you are logged in to one IDaaS-connected application, you can access other
connected applications without entering your credentials again:

1. Open another application URL that uses IDaaS
2. The system automatically recognizes your existing session
3. You are logged in without re-entering credentials
4. SSO sessions last up to 10 hours (or 30 minutes of inactivity)

---

## 3. Setting Up Multi-Factor Authentication (MFA)

### 3.1 Why MFA?

Multi-Factor Authentication adds an extra layer of security beyond your password.
Even if someone obtains your password, they cannot access your account without the
second factor.

### 3.2 Installing the IDaaS MFA Authenticator App

1. Download the **IDaaS MFA Authenticator** app:
   - **iOS**: Available on the App Store
   - **Android**: Available on Google Play
2. Open the app and allow camera permissions (needed for QR code scanning)

> **Note**: You can also use any standard TOTP authenticator app such as Google
> Authenticator, Microsoft Authenticator, or Authy.

### 3.3 Enrolling MFA

1. During login (or when prompted by your administrator), you will see a QR code
2. Open the IDaaS MFA Authenticator app on your phone
3. Tap the **+** (Add Account) button
4. Point your phone camera at the QR code on screen
5. The app will add your account and begin generating 6-digit codes
6. Enter the current 6-digit code displayed in the app
7. Click **Submit**
8. MFA is now enrolled. You will need the authenticator app for future logins

### 3.4 Using MFA During Login

1. After entering your username and password, you will see the MFA prompt
2. Open the IDaaS MFA Authenticator app
3. Find your account in the list
4. Enter the current 6-digit code (codes change every 30 seconds)
5. Click **Submit**
6. If the code is about to expire (timer nearly at zero), wait for the next code

### 3.5 MFA Troubleshooting

| Problem | Solution |
|---------|----------|
| Code not accepted | Check that your phone's clock is set to automatic (Settings > Date & Time > Automatic). TOTP codes depend on accurate time. |
| Lost your phone | Contact your administrator to reset your MFA enrollment |
| App not generating codes | Ensure the account was added correctly. Try removing and re-adding via QR code |
| Multiple accounts | Make sure you are using the code for the correct account/organization |

---

## 4. Managing Your Profile

### 4.1 Accessing Your Account Page

1. Navigate to `https://auth.example.com/realms/{your-org}/account/`
2. Or click your name/avatar in any IDaaS-connected application and select **My Account**

### 4.2 Updating Your Name and Email

1. On the Account page, click **Personal Info**
2. Update your first name, last name, or email address
3. If you change your email, you will receive a verification email at the new address
4. Click the verification link to confirm the change

### 4.3 Changing Your Password

1. On the Account page, click **Security** (or **Signing In**)
2. Click **Update Password**
3. Enter your current password
4. Enter your new password (must meet complexity requirements)
5. Confirm the new password
6. Click **Save**

> **Note**: Changing your password will log you out of all other active sessions.
> You will need to log in again on all devices.

---

## 5. Managing Active Sessions

### 5.1 Viewing Your Sessions

1. On the Account page, click **Sessions** (or **Device Activity**)
2. You will see a list of all your active sessions, including:
   - Device/browser type
   - IP address
   - Session start time
   - Last activity time

### 5.2 Signing Out of a Session

1. On the Sessions page, find the session you want to end
2. Click **Sign Out** next to that session
3. The session is immediately terminated

### 5.3 Signing Out of All Sessions

1. On the Sessions page, click **Sign Out All Sessions**
2. All sessions except your current one will be terminated
3. This is recommended if you suspect unauthorized access

---

## 6. Password Reset (Forgot Password)

### 6.1 Steps to Reset Your Password

1. On the login page, click **Forgot Password?**
2. Enter your email address or username
3. Click **Submit**
4. Check your email for a password reset link
5. Click the link (valid for 15 minutes)
6. Enter your new password
7. Confirm the new password
8. Click **Submit**
9. Return to the login page and sign in with your new password

### 6.2 If You Don't Receive the Email

- Check your spam/junk folder
- Verify you entered the correct email address
- Wait 5 minutes and try again
- Contact your administrator if the issue persists

---

## 7. Federated Login (External Identity Provider)

If your organization uses an external identity provider (such as Google, Microsoft,
or another corporate system), you may see additional login options:

1. On the login page, look for buttons like "Sign in with Google" or "Sign in with Corporate SSO"
2. Click the appropriate button
3. You will be redirected to your organization's login page
4. Enter your corporate credentials
5. After authentication, you will be redirected back to the application
6. On first federated login, your IDaaS account may be automatically created

---

## 8. Security Best Practices

### 8.1 Password Security

- Use a unique password for IDaaS (do not reuse passwords from other services)
- Consider using a password manager to generate and store strong passwords
- Never share your password with anyone, including IT support
- Change your password immediately if you suspect it has been compromised

### 8.2 MFA Security

- Keep your phone locked with a PIN, fingerprint, or face recognition
- Do not share TOTP codes with anyone
- If you lose your phone, notify your administrator immediately
- Do not screenshot QR codes during MFA enrollment

### 8.3 Session Security

- Always log out when using shared or public computers
- Review your active sessions periodically
- Report any sessions you do not recognize to your administrator
- Close your browser or lock your screen when stepping away

---

## 9. Getting Help

| Channel | Details |
|---------|---------|
| Self-Service | Account page at `https://auth.example.com/realms/{org}/account/` |
| IT Help Desk | Contact your organization's IT support team |
| Email Support | support@example.com |
| Emergency | For account compromise, contact IT immediately |

---

*Document generated by the AIDD pipeline. Instructions apply to Keycloak 24.x account console.*
