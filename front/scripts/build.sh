#!/bin/bash

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build"

# Function to extract project info from pubspec.yaml
get_project_info() {
    local app_name=""
    local version=""
    
    # Get app name from pubspec.yaml
    if [ -f "$PROJECT_ROOT/pubspec.yaml" ]; then
        app_name=$(grep "^name:" "$PROJECT_ROOT/pubspec.yaml" | sed 's/name: *//' | tr -d "'\"")
        version=$(grep "^version:" "$PROJECT_ROOT/pubspec.yaml" | sed 's/version: *//' | tr -d "'\"")
    fi
    
    # Fallback values
    app_name=${app_name:-"flutter_app"}
    version=${version:-"1.0.0"}
    
    # Clean up the app name for display (remove underscores, capitalize)
    display_name=$(echo "$app_name" | sed 's/_/ /g' | sed 's/\b\(.\)/\u\1/g')
    
    echo "$app_name|$version|$display_name"
}

# Extract project information
PROJECT_INFO=$(get_project_info)
IFS='|' read -r APP_NAME VERSION DISPLAY_NAME <<< "$PROJECT_INFO"

echo -e "${BLUE}🚀 Universal Flutter Build Script${NC}"
echo -e "${BLUE}==================================${NC}"
echo -e "${YELLOW}Project: $DISPLAY_NAME${NC}"
echo -e "${YELLOW}Version: $VERSION${NC}"
echo -e "${YELLOW}Project root: $PROJECT_ROOT${NC}"
echo -e "${YELLOW}Build directory: $BUILD_DIR${NC}"

# Change to project directory
cd "$PROJECT_ROOT"

# Create build directory if it doesn't exist
mkdir -p "$BUILD_DIR"

# Clean previous builds
echo -e "${YELLOW}🧹 Cleaning previous builds...${NC}"
flutter clean
flutter pub get

# Generate app icons
echo -e "${YELLOW}🎨 Generating app icons...${NC}"
dart run flutter_launcher_icons

# Build parameters
BUILD_PARAMS="--release --obfuscate --split-debug-info=build --target-platform android-arm,android-arm64"

# Build APK
echo -e "${YELLOW}🔨 Building APK...${NC}"
flutter build apk $BUILD_PARAMS

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ APK build successful (files automatically copied by Gradle)${NC}"
else
    echo -e "${RED}❌ APK build failed${NC}"
    exit 1
fi

# Build AAB
echo -e "${YELLOW}🔨 Building AAB...${NC}"
flutter build appbundle $BUILD_PARAMS

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ AAB build successful (files automatically copied by Gradle)${NC}"
else
    echo -e "${RED}❌ AAB build failed${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}🎉 Build completed successfully!${NC}"
echo -e "${GREEN}📁 Output files in $BUILD_DIR/:${NC}"

# List all APK and AAB files in build directory
if [ -d "$BUILD_DIR" ]; then
    APK_FILES=$(find "$BUILD_DIR" -name "*.apk" 2>/dev/null)
    AAB_FILES=$(find "$BUILD_DIR" -name "*.aab" 2>/dev/null)
    
    if [ -n "$APK_FILES" ]; then
        echo -e "${GREEN}📦 APK files:${NC}"
        for apk in $APK_FILES; do
            SIZE=$(du -h "$apk" | cut -f1)
            echo -e "   $(basename "$apk") (${SIZE})"
        done
    fi
    
    if [ -n "$AAB_FILES" ]; then
        echo -e "${GREEN}📦 AAB files:${NC}"
        for aab in $AAB_FILES; do
            SIZE=$(du -h "$aab" | cut -f1)
            echo -e "   $(basename "$aab") (${SIZE})"
        done
    fi
fi

echo ""
echo -e "${YELLOW}💡 Usage:${NC}"
echo -e "   APK: For direct installation or testing"
echo -e "   AAB: For Google Play Store upload"