#!/bin/bash
# Security scanning script using Trivy for container images
# This script scans Docker images for vulnerabilities

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting security scans...${NC}"

# Create reports directory
REPORTS_DIR="./security-reports"
mkdir -p "$REPORTS_DIR"

# Function to scan image with Trivy
scan_image() {
    local image=$1
    local name=$2

    echo -e "${YELLOW}Scanning $name image: $image${NC}"

    # Scan for vulnerabilities
    trivy image \
        --severity HIGH,CRITICAL \
        --format json \
        --output "$REPORTS_DIR/${name}-vulnerabilities.json" \
        "$image"

    # Also create human-readable report
    trivy image \
        --severity HIGH,CRITICAL \
        --format table \
        "$image" | tee "$REPORTS_DIR/${name}-vulnerabilities.txt"

    # Scan for misconfigurations
    trivy image \
        --scanners config \
        --format json \
        --output "$REPORTS_DIR/${name}-misconfig.json" \
        "$image"

    # Check exit code
    if trivy image --severity HIGH,CRITICAL --exit-code 1 "$image" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ No HIGH or CRITICAL vulnerabilities found in $name${NC}"
        return 0
    else
        echo -e "${RED}✗ Vulnerabilities found in $name - check reports${NC}"
        return 1
    fi
}

# Scan all images
SCAN_FAILED=0

# Webapp
if docker images | grep -q "idaas-webapp"; then
    scan_image "idaas-webapp:latest" "webapp" || SCAN_FAILED=1
fi

# Keycloak
if docker images | grep -q "idaas-keycloak"; then
    scan_image "idaas-keycloak:latest" "keycloak" || SCAN_FAILED=1
fi

# OAuth2 Proxy
if docker images | grep -q "idaas-oauth2-proxy"; then
    scan_image "idaas-oauth2-proxy:latest" "oauth2-proxy" || SCAN_FAILED=1
fi

# Generate summary
echo -e "${GREEN}Security scan reports saved to $REPORTS_DIR${NC}"
ls -lh "$REPORTS_DIR"

if [ $SCAN_FAILED -eq 1 ]; then
    echo -e "${RED}Security scans found vulnerabilities!${NC}"
    exit 1
else
    echo -e "${GREEN}All security scans passed!${NC}"
    exit 0
fi
