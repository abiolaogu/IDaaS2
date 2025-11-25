#!/bin/bash
# Build script for iOS IPA

set -e  # Exit on error

echo "==================================="
echo "IDaaS Authenticator - iOS Build"
echo "==================================="
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

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}✗ iOS builds require macOS${NC}"
    echo "You are running on: $OSTYPE"
    exit 1
fi

echo -e "${GREEN}✓ Running on macOS${NC}"

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}✗ Xcode is not installed${NC}"
    echo "Please install Xcode from the App Store"
    exit 1
fi

echo -e "${GREEN}✓ Xcode is installed${NC}"
xcodebuild -version
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

# Install iOS dependencies
echo -e "${YELLOW}Installing iOS dependencies (CocoaPods)...${NC}"
cd ios
if command -v pod &> /dev/null; then
    pod install
    cd ..
else
    echo -e "${YELLOW}⚠ CocoaPods not found, installing...${NC}"
    sudo gem install cocoapods
    pod install
    cd ..
fi

# Check for signing configuration
echo -e "${YELLOW}Checking signing configuration...${NC}"
if ! grep -q "DEVELOPMENT_TEAM" ios/Runner.xcodeproj/project.pbxproj; then
    echo -e "${YELLOW}⚠ Warning: Development team not configured${NC}"
    echo "To build for release, you need:"
    echo "  1. An Apple Developer account"
    echo "  2. A provisioning profile"
    echo "  3. A code signing certificate"
    echo ""
    echo "Configure signing in Xcode:"
    echo "  1. Open ios/Runner.xcworkspace in Xcode"
    echo "  2. Select Runner target"
    echo "  3. Go to Signing & Capabilities"
    echo "  4. Select your development team"
    echo ""
    echo "Building with debug configuration..."
    echo ""

    BUILD_TYPE="debug"
else
    echo -e "${GREEN}✓ Signing configuration found${NC}"
    BUILD_TYPE="release"
fi

# Build IPA
echo -e "${YELLOW}Building IPA (${BUILD_TYPE})...${NC}"

if [ "$BUILD_TYPE" == "release" ]; then
    # Build release IPA
    flutter build ipa --release

    # Check build result
    if [ $? -eq 0 ]; then
        echo ""
        echo -e "${GREEN}====================================="
        echo "✓ Build successful!"
        echo "=====================================${NC}"
        echo ""

        IPA_PATH="build/ios/ipa/mfa_authenticator.ipa"

        if [ -f "$IPA_PATH" ]; then
            IPA_SIZE=$(du -h "$IPA_PATH" | cut -f1)
            echo "IPA Location: $IPA_PATH"
            echo "IPA Size: $IPA_SIZE"
            echo ""

            # Show exportOptions
            if [ -f "build/ios/ipa/ExportOptions.plist" ]; then
                echo "Export Options:"
                cat build/ios/ipa/ExportOptions.plist
                echo ""
            fi

            echo "To install on device:"
            echo "  1. Connect your iOS device"
            echo "  2. Open Xcode"
            echo "  3. Go to Window > Devices and Simulators"
            echo "  4. Select your device"
            echo "  5. Drag the IPA file to the 'Installed Apps' section"
            echo ""
            echo "To upload to App Store:"
            echo "  1. Open Xcode"
            echo "  2. Go to Window > Organizer"
            echo "  3. Select Archives tab"
            echo "  4. Select your build"
            echo "  5. Click 'Distribute App'"
            echo ""
        else
            echo -e "${RED}✗ IPA file not found at expected location${NC}"
            echo "IPA may be in build/ios/archive/"
            exit 1
        fi
    else
        echo -e "${RED}✗ Build failed${NC}"
        exit 1
    fi
else
    # For debug, build iOS app without IPA creation
    echo "Building debug iOS app..."
    flutter build ios --debug --no-codesign

    if [ $? -eq 0 ]; then
        echo ""
        echo -e "${GREEN}====================================="
        echo "✓ Debug build successful!"
        echo "=====================================${NC}"
        echo ""
        echo "Debug app location: build/ios/iphoneos/Runner.app"
        echo ""
        echo "To test on simulator:"
        echo "  flutter run"
        echo ""
        echo "To build signed IPA for release:"
        echo "  1. Configure signing in Xcode"
        echo "  2. Run: flutter build ipa --release"
    else
        echo -e "${RED}✗ Build failed${NC}"
        exit 1
    fi
fi
