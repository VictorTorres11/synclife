#!/bin/bash

# SyncLife Production Build Script
# This script automates the production build process for Android, iOS, and Web

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
VERSION=$(grep 'version:' pubspec.yaml | sed 's/version: //')
BUILD_DIR="build/production"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}SyncLife Production Build${NC}"
echo -e "${GREEN}Version: $VERSION${NC}"
echo -e "${GREEN}Timestamp: $TIMESTAMP${NC}"
echo -e "${GREEN}========================================${NC}"

# Function to print section headers
print_section() {
    echo -e "\n${YELLOW}>>> $1${NC}\n"
}

# Function to check prerequisites
check_prerequisites() {
    print_section "Checking Prerequisites"
    
    # Check Flutter
    if ! command -v flutter &> /dev/null; then
        echo -e "${RED}Error: Flutter not found. Please install Flutter.${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ Flutter found: $(flutter --version | head -n 1)${NC}"
    
    # Check Java (for Android)
    if ! command -v java &> /dev/null; then
        echo -e "${YELLOW}Warning: Java not found. Android builds may fail.${NC}"
    else
        echo -e "${GREEN}✓ Java found: $(java -version 2>&1 | head -n 1)${NC}"
    fi
    
    # Check Xcode (for iOS, macOS only)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if ! command -v xcodebuild &> /dev/null; then
            echo -e "${YELLOW}Warning: Xcode not found. iOS builds will be skipped.${NC}"
        else
            echo -e "${GREEN}✓ Xcode found: $(xcodebuild -version | head -n 1)${NC}"
        fi
    fi
}

# Function to clean previous builds
clean_builds() {
    print_section "Cleaning Previous Builds"
    
    flutter clean
    rm -rf build/
    
    echo -e "${GREEN}✓ Clean complete${NC}"
}

# Function to get dependencies
get_dependencies() {
    print_section "Getting Dependencies"
    
    flutter pub get
    
    echo -e "${GREEN}✓ Dependencies fetched${NC}"
}

# Function to run tests
run_tests() {
    print_section "Running Tests"
    
    echo "Running unit tests..."
    flutter test || {
        echo -e "${RED}Error: Tests failed. Fix tests before building production.${NC}"
        exit 1
    }
    
    echo -e "${GREEN}✓ All tests passed${NC}"
}

# Function to build Android
build_android() {
    print_section "Building Android Release"
    
    # Check for keystore
    if [ ! -f "android/key.properties" ]; then
        echo -e "${YELLOW}Warning: android/key.properties not found.${NC}"
        echo -e "${YELLOW}Using debug signing. For production, create key.properties.${NC}"
    fi
    
    # Build App Bundle (recommended for Play Store)
    echo "Building App Bundle (AAB)..."
    flutter build appbundle --release \
        --obfuscate \
        --split-debug-info=build/app/outputs/symbols
    
    # Build APK (for testing)
    echo "Building APK..."
    flutter build apk --release \
        --obfuscate \
        --split-debug-info=build/app/outputs/symbols
    
    # Create output directory
    mkdir -p "$BUILD_DIR/android"
    
    # Copy outputs
    cp build/app/outputs/bundle/release/app-release.aab \
        "$BUILD_DIR/android/synclife-$VERSION-$TIMESTAMP.aab"
    cp build/app/outputs/flutter-apk/app-release.apk \
        "$BUILD_DIR/android/synclife-$VERSION-$TIMESTAMP.apk"
    
    # Get file sizes
    AAB_SIZE=$(du -h "$BUILD_DIR/android/synclife-$VERSION-$TIMESTAMP.aab" | cut -f1)
    APK_SIZE=$(du -h "$BUILD_DIR/android/synclife-$VERSION-$TIMESTAMP.apk" | cut -f1)
    
    echo -e "${GREEN}✓ Android build complete${NC}"
    echo -e "  AAB: $AAB_SIZE"
    echo -e "  APK: $APK_SIZE"
}

# Function to build iOS
build_ios() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        echo -e "${YELLOW}Skipping iOS build (macOS required)${NC}"
        return
    fi
    
    print_section "Building iOS Release"
    
    # Build IPA
    echo "Building IPA..."
    flutter build ipa --release \
        --obfuscate \
        --split-debug-info=build/ios/outputs/symbols
    
    # Create output directory
    mkdir -p "$BUILD_DIR/ios"
    
    # Copy output
    if [ -f "build/ios/ipa/synclife_app.ipa" ]; then
        cp build/ios/ipa/synclife_app.ipa \
            "$BUILD_DIR/ios/synclife-$VERSION-$TIMESTAMP.ipa"
        
        IPA_SIZE=$(du -h "$BUILD_DIR/ios/synclife-$VERSION-$TIMESTAMP.ipa" | cut -f1)
        
        echo -e "${GREEN}✓ iOS build complete${NC}"
        echo -e "  IPA: $IPA_SIZE"
    else
        echo -e "${YELLOW}Warning: IPA not found. Check Xcode configuration.${NC}"
    fi
}

# Function to build Web
build_web() {
    print_section "Building Web Release"
    
    # Build web app
    echo "Building web app..."
    flutter build web --release --web-renderer canvaskit
    
    # Create output directory
    mkdir -p "$BUILD_DIR/web"
    
    # Copy output
    cp -r build/web/* "$BUILD_DIR/web/"
    
    # Get size
    WEB_SIZE=$(du -sh "$BUILD_DIR/web" | cut -f1)
    
    echo -e "${GREEN}✓ Web build complete${NC}"
    echo -e "  Size: $WEB_SIZE"
}

# Function to generate build report
generate_report() {
    print_section "Generating Build Report"
    
    REPORT_FILE="$BUILD_DIR/build_report_$TIMESTAMP.txt"
    
    cat > "$REPORT_FILE" << EOF
SyncLife Production Build Report
================================

Build Information:
- Version: $VERSION
- Timestamp: $TIMESTAMP
- Flutter Version: $(flutter --version | head -n 1)
- Dart Version: $(dart --version 2>&1)

Build Outputs:
EOF
    
    if [ -d "$BUILD_DIR/android" ]; then
        echo "" >> "$REPORT_FILE"
        echo "Android:" >> "$REPORT_FILE"
        ls -lh "$BUILD_DIR/android" >> "$REPORT_FILE"
    fi
    
    if [ -d "$BUILD_DIR/ios" ]; then
        echo "" >> "$REPORT_FILE"
        echo "iOS:" >> "$REPORT_FILE"
        ls -lh "$BUILD_DIR/ios" >> "$REPORT_FILE"
    fi
    
    if [ -d "$BUILD_DIR/web" ]; then
        echo "" >> "$REPORT_FILE"
        echo "Web:" >> "$REPORT_FILE"
        du -sh "$BUILD_DIR/web" >> "$REPORT_FILE"
    fi
    
    echo -e "${GREEN}✓ Build report generated: $REPORT_FILE${NC}"
}

# Function to display summary
display_summary() {
    print_section "Build Summary"
    
    echo -e "${GREEN}Build completed successfully!${NC}"
    echo ""
    echo "Output directory: $BUILD_DIR"
    echo ""
    
    if [ -d "$BUILD_DIR/android" ]; then
        echo "Android builds:"
        ls -1 "$BUILD_DIR/android"
    fi
    
    if [ -d "$BUILD_DIR/ios" ]; then
        echo ""
        echo "iOS builds:"
        ls -1 "$BUILD_DIR/ios"
    fi
    
    if [ -d "$BUILD_DIR/web" ]; then
        echo ""
        echo "Web build: $BUILD_DIR/web"
    fi
    
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Test builds on real devices"
    echo "2. Upload to respective stores"
    echo "3. Monitor crash reports and analytics"
}

# Main execution
main() {
    # Parse arguments
    SKIP_TESTS=false
    BUILD_ANDROID=true
    BUILD_IOS=true
    BUILD_WEB=true
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-tests)
                SKIP_TESTS=true
                shift
                ;;
            --android-only)
                BUILD_IOS=false
                BUILD_WEB=false
                shift
                ;;
            --ios-only)
                BUILD_ANDROID=false
                BUILD_WEB=false
                shift
                ;;
            --web-only)
                BUILD_ANDROID=false
                BUILD_IOS=false
                shift
                ;;
            --help)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --skip-tests     Skip running tests"
                echo "  --android-only   Build only Android"
                echo "  --ios-only       Build only iOS"
                echo "  --web-only       Build only Web"
                echo "  --help           Show this help message"
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
    
    # Execute build steps
    check_prerequisites
    clean_builds
    get_dependencies
    
    if [ "$SKIP_TESTS" = false ]; then
        run_tests
    else
        echo -e "${YELLOW}Skipping tests (--skip-tests flag)${NC}"
    fi
    
    if [ "$BUILD_ANDROID" = true ]; then
        build_android
    fi
    
    if [ "$BUILD_IOS" = true ]; then
        build_ios
    fi
    
    if [ "$BUILD_WEB" = true ]; then
        build_web
    fi
    
    generate_report
    display_summary
}

# Run main function
main "$@"
