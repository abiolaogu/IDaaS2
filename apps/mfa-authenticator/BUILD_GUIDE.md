# IDaaS Authenticator Build Guide

Complete guide for building APK and IPA files for the IDaaS Authenticator app.

## Prerequisites

### For Android (APK) Build

**Required**:
- Flutter SDK 3.0.0 or higher
- Android SDK (comes with Android Studio)
- Java Development Kit (JDK) 11 or higher

**Optional** (for release builds):
- Keystore file for code signing

**Installation**:

1. Install Flutter:
```bash
# Linux/macOS
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

# Verify installation
flutter doctor
```

2. Install Android Studio:
   - Download from: https://developer.android.com/studio
   - Install Android SDK and command-line tools
   - Accept licenses: `flutter doctor --android-licenses`

### For iOS (IPA) Build

**Required**:
- macOS 12.0 or higher
- Xcode 14.0 or higher
- Flutter SDK 3.0.0 or higher
- CocoaPods
- Apple Developer account (for release builds)

**Installation**:

1. Install Xcode from App Store

2. Install Xcode command-line tools:
```bash
xcode-select --install
```

3. Install CocoaPods:
```bash
sudo gem install cocoapods
```

4. Install Flutter (if not already installed):
```bash
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"
flutter doctor
```

---

## Building for Android

### Option 1: Using Build Script (Recommended)

```bash
cd apps/mfa-authenticator
chmod +x build-android.sh
./build-android.sh
```

The script will:
- Check prerequisites
- Install dependencies
- Build APK (debug or release)
- Show APK location and size

### Option 2: Manual Build

#### Debug Build (for testing)

```bash
cd apps/mfa-authenticator

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build debug APK
flutter build apk --debug
```

**Output**: `build/app/outputs/flutter-apk/app-debug.apk`

#### Release Build (for production)

**Step 1: Generate Keystore**

```bash
keytool -genkey -v -keystore ~/mfa-authenticator-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias mfa-authenticator

# You'll be prompted for:
# - Keystore password
# - Key password
# - Your name, organization, etc.
```

**Step 2: Create keystore.properties**

```bash
cd apps/mfa-authenticator/android
nano keystore.properties
```

Add:
```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=mfa-authenticator
storeFile=/path/to/mfa-authenticator-keystore.jks
```

**Step 3: Build Release APK**

```bash
cd apps/mfa-authenticator

# Build release APK
flutter build apk --release

# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Building App Bundle for Google Play

```bash
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
```

### Installing APK on Device

**Via USB**:
```bash
# Enable USB debugging on device
# Connect device via USB

# Install APK
adb install build/app/outputs/flutter-apk/app-release.apk
```

**Via File Transfer**:
1. Copy APK to device
2. Open file manager on device
3. Tap APK file
4. Allow installation from unknown sources
5. Tap "Install"

---

## Building for iOS

### Option 1: Using Build Script (Recommended)

```bash
cd apps/mfa-authenticator
chmod +x build-ios.sh
./build-ios.sh
```

The script will:
- Check prerequisites (macOS, Xcode)
- Install dependencies
- Build IPA (debug or release)
- Show IPA location and size

### Option 2: Manual Build

#### Debug Build (for testing)

```bash
cd apps/mfa-authenticator

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Install iOS dependencies
cd ios
pod install
cd ..

# Build debug iOS app
flutter build ios --debug --no-codesign

# Run on simulator
flutter run
```

#### Release Build (for production)

**Step 1: Configure Code Signing**

1. Open Xcode:
```bash
open ios/Runner.xcworkspace
```

2. In Xcode:
   - Select "Runner" project in left sidebar
   - Select "Runner" target
   - Go to "Signing & Capabilities" tab
   - Check "Automatically manage signing"
   - Select your "Team" (Apple Developer account)
   - Bundle Identifier: `com.idaas.mfa_authenticator`

3. Ensure you have:
   - Valid Apple Developer account
   - Provisioning profile
   - Code signing certificate

**Step 2: Build Release IPA**

```bash
cd apps/mfa-authenticator

# Build release IPA
flutter build ipa --release

# Output: build/ios/ipa/mfa_authenticator.ipa
```

### Installing IPA on Device

**Option 1: Via Xcode**

1. Connect iOS device
2. Open Xcode: `open ios/Runner.xcworkspace`
3. Select your device from device list
4. Click Run button (or Cmd+R)

**Option 2: Via Xcode Organizer**

1. Open Xcode
2. Go to Window → Devices and Simulators
3. Select your device
4. Drag IPA file to "Installed Apps" section

**Option 3: Via TestFlight (for distribution)**

1. Open Xcode
2. Go to Window → Organizer
3. Select "Archives" tab
4. Select your build
5. Click "Distribute App"
6. Choose "App Store Connect"
7. Upload to TestFlight

### Uploading to App Store

1. Build release IPA
2. Open Xcode → Window → Organizer
3. Select your archive
4. Click "Distribute App"
5. Choose "App Store Connect"
6. Follow upload wizard
7. Go to App Store Connect
8. Submit for review

---

## Build Configurations

### Android Build Variants

**Debug**:
- No code signing required
- Includes debugging information
- Larger APK size (~25-30 MB)
- For development and testing

**Release**:
- Code signing required
- Optimized and minified
- Smaller APK size (~15-20 MB)
- For production distribution

**Profile**:
- Similar to release but with profiling enabled
- For performance testing

### iOS Build Variants

**Debug**:
- No code signing (or development signing)
- Includes debugging information
- For development and testing

**Release**:
- Requires Apple Developer account
- Requires provisioning profile
- Optimized for production
- For App Store or TestFlight

---

## Troubleshooting

### Android Issues

**Issue**: "Flutter not found"
```bash
# Add Flutter to PATH
export PATH="$PATH:/path/to/flutter/bin"

# Or add to ~/.bashrc or ~/.zshrc
echo 'export PATH="$PATH:/path/to/flutter/bin"' >> ~/.bashrc
```

**Issue**: "Android SDK not found"
```bash
# Run Flutter doctor to see what's missing
flutter doctor -v

# Accept Android licenses
flutter doctor --android-licenses
```

**Issue**: "Keystore not found"
```bash
# Verify keystore path in keystore.properties
ls -la /path/to/keystore.jks

# Or use absolute path
storeFile=/Users/username/mfa-authenticator-keystore.jks
```

**Issue**: "Gradle build failed"
```bash
# Clean and rebuild
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter build apk
```

### iOS Issues

**Issue**: "Xcode not found"
```bash
# Install Xcode command-line tools
xcode-select --install

# Set Xcode path
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

**Issue**: "CocoaPods not found"
```bash
# Install CocoaPods
sudo gem install cocoapods

# Or use Homebrew
brew install cocoapods
```

**Issue**: "No provisioning profiles found"
1. Open Xcode
2. Go to Preferences → Accounts
3. Sign in with Apple ID
4. Click "Download Manual Profiles"

**Issue**: "Code signing failed"
1. Open Xcode: `open ios/Runner.xcworkspace`
2. Select Runner target
3. Go to Signing & Capabilities
4. Ensure "Automatically manage signing" is checked
5. Select your team

**Issue**: "Pod install failed"
```bash
cd ios

# Update CocoaPods repo
pod repo update

# Clean and reinstall
rm -rf Pods Podfile.lock
pod install

cd ..
```

---

## Build Automation (CI/CD)

### GitHub Actions for Android

Create `.github/workflows/build-android.yml`:

```yaml
name: Build Android APK

on:
  push:
    branches: [ main ]
    paths:
      - 'apps/mfa-authenticator/**'

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v3

    - name: Setup Java
      uses: actions/setup-java@v3
      with:
        distribution: 'zulu'
        java-version: '11'

    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.16.0'
        channel: 'stable'

    - name: Install dependencies
      working-directory: apps/mfa-authenticator
      run: flutter pub get

    - name: Build APK
      working-directory: apps/mfa-authenticator
      run: flutter build apk --release

    - name: Upload APK
      uses: actions/upload-artifact@v3
      with:
        name: app-release.apk
        path: apps/mfa-authenticator/build/app/outputs/flutter-apk/app-release.apk
```

### GitHub Actions for iOS

Create `.github/workflows/build-ios.yml`:

```yaml
name: Build iOS IPA

on:
  push:
    branches: [ main ]
    paths:
      - 'apps/mfa-authenticator/**'

jobs:
  build:
    runs-on: macos-latest

    steps:
    - uses: actions/checkout@v3

    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.16.0'
        channel: 'stable'

    - name: Install dependencies
      working-directory: apps/mfa-authenticator
      run: |
        flutter pub get
        cd ios && pod install && cd ..

    - name: Build IPA
      working-directory: apps/mfa-authenticator
      run: flutter build ios --release --no-codesign

    - name: Upload IPA
      uses: actions/upload-artifact@v3
      with:
        name: Runner.app
        path: apps/mfa-authenticator/build/ios/iphoneos/Runner.app
```

---

## Distribution

### Android Distribution Options

1. **Google Play Store**:
   - Build App Bundle: `flutter build appbundle --release`
   - Upload to Google Play Console
   - Fill in app details and screenshots
   - Submit for review

2. **Direct Distribution**:
   - Build APK: `flutter build apk --release`
   - Host on website or file server
   - Users must enable "Unknown sources"

3. **Enterprise Distribution**:
   - Use Mobile Device Management (MDM)
   - Deploy via EMM/MAM solutions

### iOS Distribution Options

1. **App Store**:
   - Build IPA: `flutter build ipa --release`
   - Upload via Xcode Organizer
   - Submit to App Store Connect
   - Fill in app details
   - Submit for review

2. **TestFlight** (beta testing):
   - Upload via Xcode Organizer
   - Invite testers via email
   - No review required for internal testing

3. **Enterprise Distribution**:
   - Requires Apple Developer Enterprise Program
   - Sign with Enterprise certificate
   - Distribute via MDM or website

4. **Ad Hoc Distribution**:
   - For limited number of devices
   - Requires device UDIDs
   - Install via Xcode or configuration profile

---

## Build Checklist

### Before Building

- [ ] Update version in `pubspec.yaml`
- [ ] Update app name and display name
- [ ] Configure icons and splash screen
- [ ] Test on multiple devices/simulators
- [ ] Run `flutter analyze` to check for issues
- [ ] Run `flutter test` to verify tests pass
- [ ] Update CHANGELOG.md

### Android Release Checklist

- [ ] Generate keystore (first time only)
- [ ] Configure `keystore.properties`
- [ ] Update `versionCode` and `versionName` in `build.gradle`
- [ ] Test release build on physical device
- [ ] Verify ProGuard rules don't break functionality
- [ ] Check APK size (should be <20 MB)

### iOS Release Checklist

- [ ] Configure code signing in Xcode
- [ ] Update version and build number
- [ ] Test on physical iOS device
- [ ] Verify all required device permissions
- [ ] Check IPA size (should be <30 MB)
- [ ] Test on oldest supported iOS version

---

## Performance Optimization

### Reduce APK/IPA Size

**Android**:
```bash
# Use split APKs per ABI
flutter build apk --release --split-per-abi

# Results in:
# - app-armeabi-v7a-release.apk (~12 MB)
# - app-arm64-v8a-release.apk (~14 MB)
# - app-x86_64-release.apk (~15 MB)
```

**iOS**:
```bash
# Strip debug symbols
flutter build ios --release --split-debug-info=./debug-info --obfuscate
```

### Optimize Build Time

```bash
# Use Gradle cache
export GRADLE_USER_HOME=~/.gradle

# Use parallel builds
flutter build apk --release -j 4
```

---

## Summary

**Android**:
- Debug APK: `flutter build apk --debug` (~25 MB)
- Release APK: `flutter build apk --release` (~15 MB, requires keystore)
- App Bundle: `flutter build appbundle --release` (for Google Play)

**iOS**:
- Debug: `flutter build ios --debug --no-codesign` (testing only)
- Release IPA: `flutter build ipa --release` (~25 MB, requires signing)

**Distribution**:
- Android: Google Play Store, direct download, or MDM
- iOS: App Store, TestFlight, Enterprise, or Ad Hoc

**Build Time**:
- First build: 5-10 minutes
- Subsequent builds: 1-3 minutes (with cache)

**Output Files**:
- Android APK: `build/app/outputs/flutter-apk/app-release.apk`
- Android AAB: `build/app/outputs/bundle/release/app-release.aab`
- iOS IPA: `build/ios/ipa/mfa_authenticator.ipa`
