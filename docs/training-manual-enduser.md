# End User Training Manual — IDaaS
> Version: 1.0 | Last Updated: 2026-02-18 | Status: Draft
> Classification: Internal | Author: AIDD System

---

## 1. Training Overview

### 1.1 Audience

This training is for all end users who will authenticate to applications using the IDaaS
platform. No technical background is required.

### 1.2 Learning Objectives

After this training, you will be able to:
- Log in to your applications using Single Sign-On (SSO)
- Set up and use Multi-Factor Authentication (MFA)
- Reset your password if forgotten
- Manage your profile and active sessions
- Follow security best practices to protect your account

### 1.3 Training Duration

| Module | Duration |
|--------|----------|
| Module 1: What is IDaaS? | 15 minutes |
| Module 2: Logging In | 20 minutes |
| Module 3: Setting Up MFA | 20 minutes |
| Module 4: Account Self-Service | 15 minutes |
| Module 5: Security Awareness | 10 minutes |
| **Total** | **1 hour 20 minutes** |

---

## 2. Module 1: What is IDaaS?

### 2.1 What is Single Sign-On?

Single Sign-On (SSO) means you only need to log in once to access all your work
applications. Instead of remembering separate passwords for every application, you
use one set of credentials managed by IDaaS.

**Before IDaaS**: You had a different username and password for each application.
**With IDaaS**: You log in once, and all connected applications recognize you automatically.

### 2.2 What is Multi-Factor Authentication?

Multi-Factor Authentication (MFA) adds a second layer of protection:
- **Factor 1**: Something you know (your password)
- **Factor 2**: Something you have (a code from your phone)

Even if someone learns your password, they still cannot access your account without
your phone.

### 2.3 Why This Matters

- Protects your personal and work information from unauthorized access
- Meets security compliance requirements for your organization
- Reduces the risk of phishing and credential theft attacks

---

## 3. Module 2: Logging In

### 3.1 Exercise: Your First Login

**Step 1**: Open your web browser and go to your application URL
(e.g., `https://app.example.com`)

**Step 2**: You will see the IDaaS login page. Enter:
- **Username or Email**: (provided by your administrator)
- **Password**: (temporary password provided by your administrator)

**Step 3**: Click **Sign In**

**Step 4**: Since this is your first login, you must set a new password:
- Enter a new password with at least 12 characters
- Include uppercase letters, lowercase letters, numbers, and special characters
- Your password cannot contain your username

**Step 5**: Confirm your new password and click **Submit**

**Step 6**: You are now logged in to your application.

### 3.2 Exercise: Experiencing SSO

**Step 1**: While logged in to the first application, open a new browser tab

**Step 2**: Navigate to a second application URL that uses IDaaS

**Step 3**: Notice that you are automatically logged in -- no password prompt.

**Discussion**: This is Single Sign-On in action. Your session is shared across
all IDaaS-connected applications.

### 3.3 Exercise: Logging Out

**Step 1**: Click your name or avatar in the application

**Step 2**: Select **Logout** or **Sign Out**

**Step 3**: You are returned to the login page

**Important**: Logging out ends your SSO session. You will need to log in again
to access any IDaaS-connected application.

---

## 4. Module 3: Setting Up MFA

### 4.1 Preparation: Install the Authenticator App

Before this exercise, install one of these free authenticator apps on your phone:
- **IDaaS MFA Authenticator** (recommended)
- **Google Authenticator**
- **Microsoft Authenticator**
- **Authy**

All apps work the same way -- they generate time-based codes that change every 30 seconds.

### 4.2 Exercise: Enrolling MFA

**Step 1**: Log in to your application. If MFA is required, you will see a QR code page.

**Step 2**: Open the authenticator app on your phone

**Step 3**: Tap the **+** button (or "Add Account")

**Step 4**: Select **Scan QR Code**

**Step 5**: Point your phone camera at the QR code on your computer screen

**Step 6**: The app adds your account and shows a 6-digit code

**Step 7**: Type the 6-digit code into the field on screen

**Step 8**: Click **Submit**

**Step 9**: MFA is now set up. Your account is more secure.

### 4.3 Exercise: Logging In with MFA

**Step 1**: Log out and log back in

**Step 2**: Enter your username and password

**Step 3**: You now see a prompt asking for your authentication code

**Step 4**: Open the authenticator app and find the code for your account

**Step 5**: Enter the 6-digit code (type it quickly -- codes change every 30 seconds)

**Step 6**: Click **Submit**

**Step 7**: You are logged in

### 4.4 What If the Code Does Not Work?

- **Wait for a new code**: If the timer is almost at zero, wait for the next code
- **Check the time on your phone**: Go to Settings > Date & Time and set it to Automatic
- **Make sure you are using the right account**: If you have multiple accounts in the app, select the correct one

---

## 5. Module 4: Account Self-Service

### 5.1 Exercise: Accessing Your Account Page

**Step 1**: Navigate to your account page:
`https://auth.example.com/realms/{your-org}/account/`

**Step 2**: Log in if prompted

**Step 3**: You will see your account dashboard with options for:
- Personal Info
- Security (password and MFA)
- Sessions (active devices)

### 5.2 Exercise: Updating Your Profile

**Step 1**: Click **Personal Info**

**Step 2**: Update your first name, last name, or email

**Step 3**: Click **Save**

**Note**: If you change your email, you will receive a verification message at the
new address. Click the link to confirm.

### 5.3 Exercise: Changing Your Password

**Step 1**: Click **Security** or **Signing In**

**Step 2**: Click **Update Password**

**Step 3**: Enter your current password

**Step 4**: Enter and confirm your new password

**Step 5**: Click **Save**

**Remember**: You will be logged out of all other devices after changing your password.

### 5.4 Exercise: Reviewing Your Sessions

**Step 1**: Click **Sessions** or **Device Activity**

**Step 2**: Review the list of active sessions

**Step 3**: Look for:
- Devices you recognize (your laptop, phone)
- IP addresses that look familiar
- Any sessions you do not recognize

**Step 4**: If you see an unfamiliar session, click **Sign Out** next to it
and change your password immediately.

### 5.5 Exercise: Password Reset

**Step 1**: On the login page, click **Forgot Password?**

**Step 2**: Enter your email address

**Step 3**: Click **Submit**

**Step 4**: Check your email (including spam folder) for the reset link

**Step 5**: Click the link (it expires in 15 minutes)

**Step 6**: Enter and confirm your new password

---

## 6. Module 5: Security Awareness

### 6.1 Recognizing Phishing

Phishing attacks try to trick you into entering your credentials on a fake website.

**How to spot phishing**:
- Check the URL carefully: your login page should always be `https://auth.example.com/...`
- Look for the padlock icon in your browser (HTTPS)
- Be suspicious of urgent or threatening language in emails
- IDaaS will never ask for your password via email or phone

### 6.2 Password Best Practices

- Use a unique password for IDaaS -- do not reuse it on other websites
- Consider using a password manager (1Password, Bitwarden, etc.)
- Never share your password with anyone, including IT support
- If you suspect your password is compromised, change it immediately

### 6.3 Device Security

- Lock your computer when you step away (Ctrl+L on Windows, Cmd+Ctrl+Q on Mac)
- Keep your phone locked with PIN, fingerprint, or face recognition
- Do not leave your authenticator app visible on an unlocked phone
- Log out of applications on shared or public computers

### 6.4 Reporting Security Concerns

If you notice anything suspicious:
- Unfamiliar sessions in your account
- Login prompts you did not initiate
- Emails claiming to be from IDaaS asking for your password
- Any unauthorized access to your applications

**Contact your IT Help Desk immediately**.

---

## 7. Quick Reference Card

| Task | How To |
|------|--------|
| Log in | Go to app URL > Enter username + password > Enter MFA code |
| Reset password | Login page > Forgot Password > Check email > Set new password |
| Change password | Account page > Security > Update Password |
| Set up MFA | Login when prompted > Scan QR with authenticator app > Enter code |
| View sessions | Account page > Sessions > Review active devices |
| Log out | Click name/avatar > Sign Out |
| Report issue | Contact IT Help Desk |

---

## 8. Assessment Quiz

1. What does SSO stand for, and what does it do?
2. How many factors does MFA use, and what are they?
3. What should you do if your TOTP code is not accepted?
4. Where can you view your active sessions?
5. What should you do if you see an unfamiliar session in your account?
6. True or False: IT support may ask you for your password over email.

**Passing Score**: 5 out of 6 correct

---

*Document generated by the AIDD pipeline. Designed for non-technical audiences.*
