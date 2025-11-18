#!/bin/bash

# NaviGPT Test Runner Script
# This script builds and runs all unit tests for Phase 1

set -e  # Exit on any error

echo "🧪 NaviGPT Phase 1 Test Suite"
echo "=============================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Project paths
PROJECT_DIR="/Users/sohambhowmick/Desktop/NaviGPT/NaviGPT-main/NaviGPT_build_from_here"
PROJECT_FILE="$PROJECT_DIR/NaviGPT.xcodeproj"
SCHEME="Intern1"

echo "📍 Project Directory: $PROJECT_DIR"
echo "📦 Project File: $PROJECT_FILE"
echo "🎯 Scheme: $SCHEME"
echo ""

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}❌ Error: xcodebuild not found. Please install Xcode.${NC}"
    exit 1
fi

echo "🔨 Building NaviGPT..."
xcodebuild clean build \
    -project "$PROJECT_FILE" \
    -scheme "$SCHEME" \
    -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=latest' \
    -quiet

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Build successful${NC}"
    echo ""
else
    echo -e "${RED}❌ Build failed${NC}"
    exit 1
fi

echo "🧪 Running Unit Tests..."
echo ""

# Run the tests
xcodebuild test \
    -project "$PROJECT_FILE" \
    -scheme "$SCHEME" \
    -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=latest' \
    -only-testing:NaviGPTTests \
    2>&1 | tee test_output.log

# Check test results
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ All tests passed!${NC}"
    echo ""
    
    # Extract test summary
    echo "📊 Test Summary:"
    grep -E "Test Suite|Executed|tests passed" test_output.log | tail -5
    
    exit 0
else
    echo ""
    echo -e "${RED}❌ Tests failed${NC}"
    echo ""
    
    # Show failures
    echo "❌ Failed Tests:"
    grep -A 2 "FAILED" test_output.log || echo "No detailed failure info available"
    
    exit 1
fi
