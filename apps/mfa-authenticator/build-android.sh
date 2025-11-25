#!/bin/bash
# Build script for Android APK

set -e  # Exit on error

echo "====================================="
echo "IDaaS Authenticator - Android Build"
echo "====================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}✗ Flutter is not installed${NC}"
    echo "Please install Flutter SDK: https://flutter.dev/docs/get-started/install"
    exit 1
fi

echo -e "${GREEN}✓ Flutter is installed${NC}"
flutter --version
echo ""

# Check if running in mfa-authenticator directory
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}✗ pubspec.yaml not found${NC}"
    echo "Please run this script from the mfa-authenticator directory"
    exit 1
fi

# Clean previous builds
echo -e "${YELLOW}Cleaning previous builds...${NC}"
flutter clean

# Get dependencies
echo -e "${YELLOW}Getting dependencies...${NC}"
flutter pub get

# Check for keystore configuration
if [ ! -f "android/keystore.properties" ]; then
    echo -e "${YELLOW}⚠ Warning: android/keystore.properties not found${NC}"
    echo "Building with debug signing. For production, create keystore.properties with:"
    echo "  storePassword=your-store-password"
    echo "  keyPassword=your-key-password"
    echo "  keyAlias=your-key-alias"
    echo "  storeFile=/path/to/keystore.jks"
    echo ""
    echo "Generate keystore with:"
    echo "  keytool -genkey -v -keystore ~/keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias mfa-authenticator"
    echo ""

    BUILD_TYPE="debug"
else
    echo -e "${GREEN}✓ Keystore configuration found${NC}"
    BUILD_TYPE="release"
fi

# Build APK
echo -e "${YELLOW}Building APK (${BUILD_TYPE})...${NC}"
if [ "$BUILD_TYPE" == "release" ]; then
    flutter build apk --release
else
    flutter build apk --debug
fi

# Check build result
if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}====================================="
    echo "✓ Build successful!"
    echo "=====================================${NC}"
    echo ""

    if [ "$BUILD_TYPE" == "release" ]; then
        APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
    else
        APK_PATH="build/app/outputs/flutter-apk/app-debug.apk"
    fi

    if [ -f "$APK_PATH" ]; then
        APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
        echo "APK Location: $APK_PATH"
        echo "APK Size: $APK_SIZE"
        echo ""

        # Get APK info
        echo "APK Details:"
        if command -v aapt &> /dev/null; then
            aapt dump badging "$APK_PATH" | grep -E "package:|application-label:|sdkVersion:|targetSdkVersion:"
        else
            echo "Install Android SDK build-tools for detailed APK info"
        fi

        echo ""
        echo "To install on device:"
        echo "  adb install $APK_PATH"
        echo ""
        echo "To build App Bundle for Google Play:"
        echo "  flutter build appbundle --release"
    else
        echo -e "${RED}✗ APK file not found at expected location${NC}"
        exit 1
    fi
else
    echo -e "${RED}✗ Build failed${NC}"
    exit 1
fi
