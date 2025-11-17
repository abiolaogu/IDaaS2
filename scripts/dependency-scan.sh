#!/bin/bash
# Dependency vulnerability scanning script
# Uses Safety to check Python dependencies for known vulnerabilities

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting dependency vulnerability scans...${NC}"

# Create reports directory
REPORTS_DIR="./security-reports"
mkdir -p "$REPORTS_DIR"

SCAN_FAILED=0

# Scan webapp dependencies
echo -e "${YELLOW}Scanning webapp dependencies...${NC}"
if [ -f "./apps/webapp/requirements.txt" ]; then
    # Install safety if not installed
    pip install safety 2>/dev/null || true

    # Run Safety check
    safety check \
        --file ./apps/webapp/requirements.txt \
        --json \
        --output "$REPORTS_DIR/webapp-dependencies.json" || SCAN_FAILED=1

    # Also create human-readable report
    safety check \
        --file ./apps/webapp/requirements.txt \
        --output text | tee "$REPORTS_DIR/webapp-dependencies.txt" || true
fi

# Scan test dependencies
echo -e "${YELLOW}Scanning test dependencies...${NC}"
if [ -f "./tests/requirements.txt" ]; then
    safety check \
        --file ./tests/requirements.txt \
        --json \
        --output "$REPORTS_DIR/test-dependencies.json" || SCAN_FAILED=1

    safety check \
        --file ./tests/requirements.txt \
        --output text | tee "$REPORTS_DIR/test-dependencies.txt" || true
fi

# Run pip-audit as alternative checker
echo -e "${YELLOW}Running pip-audit...${NC}"
pip install pip-audit 2>/dev/null || true

if [ -f "./apps/webapp/requirements.txt" ]; then
    pip-audit \
        --requirement ./apps/webapp/requirements.txt \
        --format json \
        --output "$REPORTS_DIR/webapp-pip-audit.json" || SCAN_FAILED=1

    pip-audit \
        --requirement ./apps/webapp/requirements.txt || true
fi

echo -e "${GREEN}Dependency scan reports saved to $REPORTS_DIR${NC}"

if [ $SCAN_FAILED -eq 1 ]; then
    echo -e "${YELLOW}Dependency scans found vulnerabilities - check reports${NC}"
    exit 1
else
    echo -e "${GREEN}All dependency scans passed!${NC}"
    exit 0
fi
