#!/bin/bash
# Master script to run all security scans

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}    IDaaS Platform - Security Scan Suite       ${NC}"
echo -e "${BLUE}================================================${NC}"

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR/.."

# Create reports directory
REPORTS_DIR="./security-reports"
mkdir -p "$REPORTS_DIR"

# Track failures
TOTAL_FAILED=0

# 1. Run dependency vulnerability scanning
echo -e "\n${BLUE}[1/3] Running dependency vulnerability scans...${NC}"
if bash "$SCRIPT_DIR/dependency-scan.sh"; then
    echo -e "${GREEN}✓ Dependency scans passed${NC}"
else
    echo -e "${YELLOW}⚠ Dependency scans found issues${NC}"
    TOTAL_FAILED=$((TOTAL_FAILED + 1))
fi

# 2. Run SAST scanning
echo -e "\n${BLUE}[2/3] Running SAST scans...${NC}"
if bash "$SCRIPT_DIR/sast-scan.sh"; then
    echo -e "${GREEN}✓ SAST scans passed${NC}"
else
    echo -e "${YELLOW}⚠ SAST scans found issues${NC}"
    TOTAL_FAILED=$((TOTAL_FAILED + 1))
fi

# 3. Run container image scanning (only if images exist)
echo -e "\n${BLUE}[3/3] Running container image scans...${NC}"
if docker images | grep -q "idaas"; then
    if bash "$SCRIPT_DIR/security-scan.sh"; then
        echo -e "${GREEN}✓ Container scans passed${NC}"
    else
        echo -e "${YELLOW}⚠ Container scans found issues${NC}"
        TOTAL_FAILED=$((TOTAL_FAILED + 1))
    fi
else
    echo -e "${YELLOW}⚠ No container images found - skipping container scans${NC}"
    echo -e "${YELLOW}  Run 'docker-compose build' first to build images${NC}"
fi

# Summary
echo -e "\n${BLUE}================================================${NC}"
echo -e "${BLUE}              Scan Summary                      ${NC}"
echo -e "${BLUE}================================================${NC}"
echo -e "Reports directory: ${YELLOW}$REPORTS_DIR${NC}"
echo -e "Total scans with issues: ${RED}$TOTAL_FAILED${NC}"

if [ -d "$REPORTS_DIR" ]; then
    echo -e "\nGenerated reports:"
    ls -lh "$REPORTS_DIR"
fi

if [ $TOTAL_FAILED -eq 0 ]; then
    echo -e "\n${GREEN}✓ All security scans passed!${NC}"
    exit 0
else
    echo -e "\n${YELLOW}⚠ Some scans found issues - please review reports${NC}"
    exit 1
fi
