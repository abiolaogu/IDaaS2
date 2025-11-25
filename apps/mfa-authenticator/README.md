# IDaaS Authenticator

A secure TOTP (Time-based One-Time Password) authenticator app compatible with Google Authenticator and Microsoft Authenticator.

## Features

- **TOTP Support**: Generate 6-digit time-based one-time passwords (30-second intervals)
- **QR Code Scanning**: Easily add accounts by scanning QR codes
- **Manual Entry**: Add accounts manually using secret keys
- **Secure Storage**: All secrets are encrypted using platform-specific secure storage
- **Material Design**: Modern, clean UI following Material Design 3 guidelines
- **Cross-Platform**: Works on both Android and iOS

## Compatibility

This app implements the standard TOTP protocol (RFC 6238) and is compatible with:
- Google Authenticator
- Microsoft Authenticator
- Any service that supports standard TOTP authentication

## Building

### Prerequisites

- Flutter SDK 3.0.0 or higher
- For Android: Android SDK 21 or higher
- For iOS: iOS 12.0 or higher, Xcode 14 or higher

### Install Dependencies

```bash
flutter pub get
```

### Build for Android

```bash
# Build APK (for testing)
flutter build apk --release

# Build App Bundle (for Google Play Store)
flutter build appbundle --release
```

The APK will be located at: `build/app/outputs/flutter-apk/app-release.apk`

### Build for iOS

```bash
# Build IPA
flutter build ipa --release
```

The IPA will be located at: `build/ios/ipa/mfa_authenticator.ipa`

**Note**: For iOS builds, you need:
1. A valid Apple Developer account
2. Properly configured provisioning profile
3. Code signing certificate

## Release Signing

### Android

1. Create a keystore (if you don't have one):

```bash
keytool -genkey -v -keystore ~/keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias mfa-authenticator
```

2. Create `android/keystore.properties`:

```properties
storePassword=your-store-password
keyPassword=your-key-password
keyAlias=mfa-authenticator
storeFile=/path/to/keystore.jks
```

3. Build release APK:

```bash
flutter build apk --release
```

### iOS

1. Open `ios/Runner.xcworkspace` in Xcode
2. Configure signing in the "Signing & Capabilities" section
3. Select your development team
4. Build the IPA using Flutter or Xcode

## Security

- All TOTP secrets are stored using platform-specific secure storage:
  - **Android**: EncryptedSharedPreferences with AES-256 encryption
  - **iOS**: Keychain with first-unlock-this-device accessibility
- No data is transmitted over the network
- Camera permission is only used for QR code scanning
- App does not backup sensitive data to cloud services

## Architecture

The app follows clean architecture principles with:

- **BLoC Pattern**: State management using flutter_bloc
- **Repository Pattern**: Abstracted storage layer
- **Dependency Injection**: Services injected via BLoC providers
- **Immutable Models**: All data models are immutable

### Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/
│   └── account.dart          # Account model
├── services/
│   ├── totp_service.dart     # TOTP generation logic
│   └── storage_service.dart  # Secure storage abstraction
├── bloc/
│   └── account_bloc.dart     # State management
└── screens/
    ├── home_screen.dart      # Main screen with TOTP codes
    └── add_account_screen.dart # QR scanning and manual entry
```

## Testing

```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/

# Run with coverage
flutter test --coverage
```

## TOTP Specification

This app implements:
- **Algorithm**: HMAC-SHA1
- **Digits**: 6
- **Period**: 30 seconds
- **Encoding**: Base32 (standard)

Compatible with the OTP Auth URL format:
```
otpauth://totp/[Issuer]:[AccountName]?secret=[Base32Secret]&issuer=[Issuer]
```

## Permissions

### Android
- `CAMERA`: Required for QR code scanning
- `INTERNET`: Reserved for future features (currently not used)

### iOS
- `NSCameraUsageDescription`: Required for QR code scanning

## License

Copyright © 2025 IDaaS Platform

## Support

For issues or questions, please contact the IDaaS Platform support team.
