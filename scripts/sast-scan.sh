#!/bin/bash
# Static Application Security Testing (SAST) script
# Uses Bandit for Python code security analysis

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting SAST scans with Bandit...${NC}"

# Create reports directory
REPORTS_DIR="./security-reports"
mkdir -p "$REPORTS_DIR"

SCAN_FAILED=0

# Scan Flask webapp
echo -e "${YELLOW}Scanning Flask webapp...${NC}"
if [ -d "./apps/webapp" ]; then
    cd apps/webapp

    # Install bandit if not already installed
    pip install bandit bandit-sarif-formatter 2>/dev/null || true

    # Run Bandit scan
    bandit -r . \
        -f json \
        -o "../../$REPORTS_DIR/webapp-bandit.json" \
        --exclude './tests,./venv,./env' \
        --severity-level medium || SCAN_FAILED=1

    # Also create human-readable report
    bandit -r . \
        -f txt \
        --exclude './tests,./venv,./env' \
        --severity-level medium | tee "../../$REPORTS_DIR/webapp-bandit.txt" || true

    # Generate SARIF format for GitHub integration
    bandit -r . \
        -f sarif \
        -o "../../$REPORTS_DIR/webapp-bandit.sarif" \
        --exclude './tests,./venv,./env' \
        --severity-level medium || true

    cd ../..
fi

# Run flake8 for code quality
echo -e "${YELLOW}Running code quality checks...${NC}"
if [ -d "./apps/webapp" ]; then
    cd apps/webapp

    # Install flake8 if not installed
    pip install flake8 2>/dev/null || true

    # Run flake8
    flake8 . \
        --exclude=venv,env,tests,__pycache__ \
        --max-line-length=120 \
        --output-file="../../$REPORTS_DIR/webapp-flake8.txt" || SCAN_FAILED=1

    cd ../..
fi

echo -e "${GREEN}SAST scan reports saved to $REPORTS_DIR${NC}"

if [ $SCAN_FAILED -eq 1 ]; then
    echo -e "${YELLOW}SAST scans found issues - check reports${NC}"
    exit 1
else
    echo -e "${GREEN}All SAST scans passed!${NC}"
    exit 0
fi
