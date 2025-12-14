#!/bin/bash
# Pre-flight check before deployment
# Verifies prerequisites and environment setup

set -e

echo "========================================"
echo "  HMS Deployment Pre-Flight Check"
echo "========================================"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

FAIL=0

echo "Checking prerequisites..."
echo "-------------------------------------------"

# Check Docker
echo -n "Docker Engine... "
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version | awk '{print $3}' | sed 's/,//')
    echo -e "${GREEN}✓ $DOCKER_VERSION${NC}"
else
    echo -e "${RED}✗ Not installed${NC}"
    echo "Install Docker: https://docs.docker.com/engine/install/"
    FAIL=1
fi

# Check Docker Compose
echo -n "Docker Compose... "
if docker compose version &> /dev/null; then
    COMPOSE_VERSION=$(docker compose version --short)
    echo -e "${GREEN}✓ $COMPOSE_VERSION${NC}"
else
    echo -e "${RED}✗ Not installed or wrong version${NC}"
    echo "Need Docker Compose v2. Install: https://docs.docker.com/compose/install/"
    FAIL=1
fi

# Check Docker daemon
echo -n "Docker Daemon... "
if docker ps &> /dev/null; then
    echo -e "${GREEN}✓ Running${NC}"
else
    echo -e "${RED}✗ Not running${NC}"
    echo "Start Docker daemon: sudo systemctl start docker"
    FAIL=1
fi

# Check disk space
echo -n "Disk Space... "
AVAILABLE=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
if [ "$AVAILABLE" -gt 10 ]; then
    echo -e "${GREEN}✓ ${AVAILABLE}GB available${NC}"
else
    echo -e "${YELLOW}⚠ Only ${AVAILABLE}GB available (recommend 10GB+)${NC}"
fi

# Check memory
echo -n "System Memory... "
if command -v free &> /dev/null; then
    TOTAL_MEM=$(free -g | awk 'NR==2 {print $2}')
    if [ "$TOTAL_MEM" -ge 4 ]; then
        echo -e "${GREEN}✓ ${TOTAL_MEM}GB total${NC}"
    else
        echo -e "${YELLOW}⚠ ${TOTAL_MEM}GB total (recommend 4GB+)${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Cannot detect (Linux only)${NC}"
fi

echo ""
echo "Checking port availability..."
echo "-------------------------------------------"

# Check port 80
echo -n "Port 80 (HTTP)... "
if ! sudo lsof -i :80 &> /dev/null && ! sudo netstat -tuln 2>/dev/null | grep -q ":80 "; then
    echo -e "${GREEN}✓ Available${NC}"
else
    echo -e "${RED}✗ In use${NC}"
    echo "Port 80 is required. Stop other services:"
    sudo lsof -i :80 2>/dev/null || sudo netstat -tulpn | grep :80
    FAIL=1
fi

# Check port 443 (optional for HTTP-only testing)
echo -n "Port 443 (HTTPS)... "
if ! sudo lsof -i :443 &> /dev/null && ! sudo netstat -tuln 2>/dev/null | grep -q ":443 "; then
    echo -e "${GREEN}✓ Available${NC}"
else
    echo -e "${YELLOW}⚠ In use (not critical for HTTP testing)${NC}"
fi

echo ""
echo "Checking deployment files..."
echo "-------------------------------------------"

# Check docker-compose.yml
echo -n "docker-compose.yml... "
if [ -f "docker-compose.yml" ]; then
    echo -e "${GREEN}✓ Found${NC}"
else
    echo -e "${RED}✗ Missing${NC}"
    FAIL=1
fi

# Check env files
echo -n "hms-backend.env... "
if [ -f "hms-backend.env" ]; then
    echo -e "${GREEN}✓ Found${NC}"
else
    echo -e "${RED}✗ Missing${NC}"
    FAIL=1
fi

echo -n "campaign.env... "
if [ -f "campaign.env" ]; then
    echo -e "${GREEN}✓ Found${NC}"
else
    echo -e "${YELLOW}⚠ Missing (optional)${NC}"
fi

# Check nginx config
echo -n "nginx/conf.d/reverse-proxy-http.conf... "
if [ -f "nginx/conf.d/reverse-proxy-http.conf" ]; then
    echo -e "${GREEN}✓ Found${NC}"
else
    echo -e "${RED}✗ Missing${NC}"
    FAIL=1
fi

# Check schema scripts
echo -n "data/scripts/1-schema.sql... "
if [ -f "data/scripts/1-schema.sql" ]; then
    echo -e "${GREEN}✓ Found${NC}"
else
    echo -e "${RED}✗ Missing${NC}"
    FAIL=1
fi

echo ""
echo "Validating configuration..."
echo "-------------------------------------------"

# Check if old HTTPS config is disabled
echo -n "HTTPS config disabled... "
if [ ! -f "nginx/conf.d/reverse-proxy.conf" ]; then
    echo -e "${GREEN}✓ Disabled (HTTP mode)${NC}"
else
    echo -e "${YELLOW}⚠ reverse-proxy.conf exists (should be renamed to .disabled)${NC}"
fi

# Check if ports are commented in docker-compose
echo -n "Service ports secured... "
if grep -q "# ports:" docker-compose.yml && ! grep -E "^\s+- (5001|6001|8001):" docker-compose.yml &> /dev/null; then
    echo -e "${GREEN}✓ Only nginx exposed${NC}"
else
    echo -e "${YELLOW}⚠ Direct service ports may be exposed${NC}"
fi

echo ""
echo "========================================"
if [ "$FAIL" -eq 0 ]; then
    echo -e "${GREEN}✓ PRE-FLIGHT CHECK PASSED${NC}"
    echo ""
    echo "Ready to deploy! Run:"
    echo -e "  ${YELLOW}docker compose up -d${NC}"
    echo ""
    echo "After ~30 seconds, verify with:"
    echo -e "  ${YELLOW}bash scripts/verify-deployment.sh${NC}"
    exit 0
else
    echo -e "${RED}✗ PRE-FLIGHT CHECK FAILED${NC}"
    echo ""
    echo "Fix the issues above before deploying."
    exit 1
fi
