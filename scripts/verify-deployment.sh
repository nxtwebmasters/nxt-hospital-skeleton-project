#!/bin/bash
# Deployment Health Check Script
# Quick verification that all HMS services are running and responding

set -e

echo "=========================================="
echo "  HMS Multi-Tenant Deployment Health Check"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if a service is running
check_service() {
    local service_name=$1
    echo -n "Checking $service_name... "
    
    if docker ps --format '{{.Names}}' | grep -q "^${service_name}$"; then
        echo -e "${GREEN}✓ Running${NC}"
        return 0
    else
        echo -e "${RED}✗ Not Running${NC}"
        return 1
    fi
}

# Function to check HTTP endpoint
check_endpoint() {
    local url=$1
    local description=$2
    echo -n "Checking $description... "
    
    if curl -s -o /dev/null -w "%{http_code}" "$url" | grep -q "200\|302\|301"; then
        echo -e "${GREEN}✓ Responding${NC}"
        return 0
    else
        echo -e "${RED}✗ Not Responding${NC}"
        return 1
    fi
}

echo "1. Docker Container Status"
echo "-------------------------------------------"
check_service "nginx-reverse-proxy" || FAIL=1
check_service "api-hospital" || FAIL=1
check_service "nxt-hospital" || FAIL=1
check_service "portal-hospital" || FAIL=1
check_service "hospital-mysql" || FAIL=1
check_service "hospital-redis" || FAIL=1
echo ""

echo "2. Service Health Endpoints"
echo "-------------------------------------------"
check_endpoint "http://localhost/nginx-health" "Nginx Reverse Proxy" || FAIL=1
check_endpoint "http://localhost/api-server/health" "Backend API" || FAIL=1
check_endpoint "http://localhost/" "Admin Frontend" || FAIL=1
check_endpoint "http://localhost/portal/" "Patient Portal" || FAIL=1
echo ""

echo "3. Database Connectivity"
echo "-------------------------------------------"
echo -n "Checking MySQL connection... "
if docker exec hospital-mysql mysql -u nxt_user -pNxtWebMasters464 -e "SELECT 1" nxt-hospital > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Connected${NC}"
else
    echo -e "${RED}✗ Connection Failed${NC}"
    FAIL=1
fi

echo -n "Checking tenant table... "
if docker exec hospital-mysql mysql -u nxt_user -pNxtWebMasters464 -e "SELECT COUNT(*) FROM nxt_tenant" nxt-hospital > /dev/null 2>&1; then
    TENANT_COUNT=$(docker exec hospital-mysql mysql -u nxt_user -pNxtWebMasters464 -sN -e "SELECT COUNT(*) FROM nxt_tenant" nxt-hospital 2>/dev/null)
    echo -e "${GREEN}✓ Found ($TENANT_COUNT tenants)${NC}"
else
    echo -e "${RED}✗ Table Not Found${NC}"
    FAIL=1
fi
echo ""

echo "4. Redis Connectivity"
echo "-------------------------------------------"
echo -n "Checking Redis... "
if docker exec hospital-redis redis-cli ping > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Connected${NC}"
else
    echo -e "${RED}✗ Connection Failed${NC}"
    FAIL=1
fi
echo ""

echo "5. Network Access Points"
echo "-------------------------------------------"
echo -e "Admin Interface:    ${YELLOW}http://localhost/${NC}"
echo -e "Patient Portal:     ${YELLOW}http://localhost/portal/${NC}"
echo -e "API Endpoint:       ${YELLOW}http://localhost/api-server/${NC}"
echo -e "API Health:         ${YELLOW}http://localhost/api-server/health${NC}"
echo -e "Bootstrap Status:   ${YELLOW}http://localhost/api-server/bootstrap/status${NC}"
echo ""

echo "6. Quick Multi-Tenancy Verification"
echo "-------------------------------------------"
echo -n "Checking default tenant setup... "
DEFAULT_TENANT=$(docker exec hospital-mysql mysql -u nxt_user -pNxtWebMasters464 -sN -e "SELECT tenant_id FROM nxt_tenant WHERE tenant_subdomain='default'" nxt-hospital 2>/dev/null)
if [ "$DEFAULT_TENANT" = "tenant_system_default" ]; then
    echo -e "${GREEN}✓ Default tenant configured${NC}"
else
    echo -e "${YELLOW}⚠ Default tenant not found${NC}"
    FAIL=1
fi

echo -n "Checking tenant_id column in nxt_patient... "
if docker exec hospital-mysql mysql -u nxt_user -pNxtWebMasters464 -e "SHOW COLUMNS FROM nxt_patient LIKE 'tenant_id'" nxt-hospital 2>/dev/null | grep -q "tenant_id"; then
    echo -e "${GREEN}✓ Multi-tenancy schema ready${NC}"
else
    echo -e "${RED}✗ tenant_id column missing${NC}"
    FAIL=1
fi
echo ""

echo "=========================================="
if [ -z "$FAIL" ]; then
    echo -e "${GREEN}✓ ALL CHECKS PASSED${NC}"
    echo ""
    echo "Your HMS deployment is ready for multi-tenancy testing!"
    echo ""
    echo "Next Steps:"
    echo "  1. Access admin interface: http://localhost/"
    echo "  2. Login with default credentials"
    echo "  3. Test tenant isolation by creating test data"
    echo "  4. Monitor logs: docker compose logs -f"
    exit 0
else
    echo -e "${RED}✗ SOME CHECKS FAILED${NC}"
    echo ""
    echo "Troubleshooting:"
    echo "  - Check logs: docker compose logs"
    echo "  - Restart services: docker compose restart"
    echo "  - Full rebuild: docker compose down && docker compose up -d"
    exit 1
fi
