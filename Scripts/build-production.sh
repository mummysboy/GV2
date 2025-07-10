#!/bin/bash

# Production Build Script for GV2
# This script builds, tests, and archives the app for App Store submission

set -e  # Exit on any error

# Configuration
PROJECT_NAME="GV2"
SCHEME_NAME="GV2"
CONFIGURATION="Release"
DESTINATION="generic/platform=iOS"
ARCHIVE_PATH="./build/${PROJECT_NAME}.xcarchive"
EXPORT_PATH="./build/Export"
EXPORT_OPTIONS_PLIST="./Config/ExportOptions.plist"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "${PROJECT_NAME}.xcodeproj/project.pbxproj" ]; then
    log_error "Project file not found. Please run this script from the project root directory."
    exit 1
fi

# Create build directory
log_info "Creating build directory..."
mkdir -p build
mkdir -p "${EXPORT_PATH}"

# Clean previous builds
log_info "Cleaning previous builds..."
xcodebuild clean \
    -project "${PROJECT_NAME}.xcodeproj" \
    -scheme "${SCHEME_NAME}" \
    -configuration "${CONFIGURATION}"

# Run tests
log_info "Running tests..."
xcodebuild test \
    -project "${PROJECT_NAME}.xcodeproj" \
    -scheme "${SCHEME_NAME}" \
    -configuration "${CONFIGURATION}" \
    -destination "platform=iOS Simulator,name=iPhone 16" \
    -enableCodeCoverage YES

# Check test results
if [ $? -eq 0 ]; then
    log_success "All tests passed!"
else
    log_error "Tests failed. Aborting build."
    exit 1
fi

# Build for archive
log_info "Building for archive..."
xcodebuild archive \
    -project "${PROJECT_NAME}.xcodeproj" \
    -scheme "${SCHEME_NAME}" \
    -configuration "${CONFIGURATION}" \
    -destination "${DESTINATION}" \
    -archivePath "${ARCHIVE_PATH}" \
    -allowProvisioningUpdates

# Check if archive was created
if [ ! -d "${ARCHIVE_PATH}" ]; then
    log_error "Archive creation failed."
    exit 1
fi

log_success "Archive created successfully!"

# Export IPA
log_info "Exporting IPA..."
xcodebuild -exportArchive \
    -archivePath "${ARCHIVE_PATH}" \
    -exportPath "${EXPORT_PATH}" \
    -exportOptionsPlist "${EXPORT_OPTIONS_PLIST}"

# Check if IPA was created
IPA_FILE=$(find "${EXPORT_PATH}" -name "*.ipa" | head -1)
if [ -z "${IPA_FILE}" ]; then
    log_error "IPA export failed."
    exit 1
fi

log_success "IPA exported successfully: ${IPA_FILE}"

# Validate IPA
log_info "Validating IPA..."
xcrun altool --validate-app \
    --type ios \
    --file "${IPA_FILE}" \
    --apiKey "${APP_STORE_CONNECT_API_KEY}" \
    --apiIssuer "${APP_STORE_CONNECT_ISSUER_ID}"

if [ $? -eq 0 ]; then
    log_success "IPA validation successful!"
else
    log_warning "IPA validation failed. You may still be able to upload to App Store Connect."
fi

# Generate build report
log_info "Generating build report..."
BUILD_REPORT_FILE="./build/build-report-$(date +%Y%m%d-%H%M%S).txt"

cat > "${BUILD_REPORT_FILE}" << EOF
GV2 Production Build Report
Generated: $(date)

Build Configuration:
- Project: ${PROJECT_NAME}
- Scheme: ${SCHEME_NAME}
- Configuration: ${CONFIGURATION}
- Archive Path: ${ARCHIVE_PATH}
- IPA Path: ${IPA_FILE}

Build Steps:
1. ✅ Project cleaned
2. ✅ Tests executed and passed
3. ✅ Archive created
4. ✅ IPA exported
5. ✅ IPA validated

Next Steps:
1. Upload IPA to App Store Connect
2. Submit for review
3. Monitor crash reports and analytics

EOF

log_success "Build completed successfully!"
log_info "Build report saved to: ${BUILD_REPORT_FILE}"
log_info "IPA ready for upload: ${IPA_FILE}"

# Optional: Upload to App Store Connect
if [ "${AUTO_UPLOAD}" = "true" ]; then
    log_info "Uploading to App Store Connect..."
    xcrun altool --upload-app \
        --type ios \
        --file "${IPA_FILE}" \
        --apiKey "${APP_STORE_CONNECT_API_KEY}" \
        --apiIssuer "${APP_STORE_CONNECT_ISSUER_ID}"
    
    if [ $? -eq 0 ]; then
        log_success "Upload to App Store Connect successful!"
    else
        log_error "Upload to App Store Connect failed."
        exit 1
    fi
fi

echo ""
log_success "🎉 Production build completed successfully!"
echo ""
echo "Next steps:"
echo "1. Review the build report: ${BUILD_REPORT_FILE}"
echo "2. Upload the IPA to App Store Connect: ${IPA_FILE}"
echo "3. Submit for App Store review"
echo "4. Monitor crash reports and analytics in production"
echo "" 