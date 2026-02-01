#!/bin/bash

##############################################################################
# HMS Deployment Verification Script
# Run this after deployment to verify all services are working
##############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  HMS Deployment Verification"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Check if containers are running
echo "1. Checking Docker Containers..."
echo "────────────────────────────────────────────────────────────────"

CONTAINERS=("nginx-reverse-proxy" "api-hospital" "nxt-hospital" "portal-hospital" "hospital-mysql" "hospital-redis")
ALL_RUNNING=1

for container in "${CONTAINERS[@]}"; do
    if docker ps --format "{{.Names}}" | grep -q "^${container}$"; then
        STATUS=$(docker inspect --format='{{.State.Status}}' "$container")
        if [ "$STATUS" == "running" ]; then
            echo -e "${GREEN}✓${NC} $container: running"
        else
            echo -e "${RED}✗${NC} $container: $STATUS"
            ALL_RUNNING=0
        fi
    else
        echo -e "${RED}✗${NC} $container: not found"
        ALL_RUNNING=0
    fi
done

if [ $ALL_RUNNING -eq 0 ]; then
    echo ""
    echo -e "${RED}Some containers are not running properly!${NC}"
    echo "Run: docker compose ps"
    exit 1
fi

echo ""

# Check nginx health
echo "2. Checking Nginx Health..."
echo "────────────────────────────────────────────────────────────────"

if curl -f -s http://localhost/nginx-health > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Nginx health check: PASSED"
else
    echo -e "${RED}✗${NC} Nginx health check: FAILED"
    echo "   Check logs: docker logs nginx-reverse-proxy"
    echo ""
    echo "Last 10 lines of nginx logs:"
    docker logs nginx-reverse-proxy --tail 10
    exit 1
fi

echo ""

# Check API health
echo "3. Checking Backend API Health..."
echo "────────────────────────────────────────────────────────────────"

if curl -f -s http://localhost/api-server/health > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Backend API health check: PASSED"
    
    # Get API response
    API_RESPONSE=$(curl -s http://localhost/api-server/health)
    echo "   Response: $API_RESPONSE"
else
    echo -e "${YELLOW}⚠${NC} Backend API health check: NOT READY YET"
    echo "   API may still be bootstrapping (can take 30-60 seconds)"
    echo "   Check logs: docker logs -f api-hospital"
fi

echo ""

# Check MySQL
echo "4. Checking MySQL Database..."
echo "────────────────────────────────────────────────────────────────"

if docker exec hospital-mysql mysqladmin ping -h localhost --silent 2>/dev/null; then
    echo -e "${GREEN}✓${NC} MySQL: responding to ping"
    
    # Count tables
    DB_PASSWORD=$(grep "DB_PASSWORD=" hms-backend.env | cut -d'=' -f2)
    TABLE_COUNT=$(docker exec hospital-mysql mysql -u nxt_user -p"$DB_PASSWORD" nxt-hospital -se "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='nxt-hospital';" 2>/dev/null || echo "0")
    
    if [ "$TABLE_COUNT" -gt 50 ]; then
        echo -e "${GREEN}✓${NC} Database schema: $TABLE_COUNT tables (expected 65+)"
    else
        echo -e "${YELLOW}⚠${NC} Database schema: $TABLE_COUNT tables (may still be initializing)"
    fi
else
    echo -e "${RED}✗${NC} MySQL: not responding"
    exit 1
fi

echo ""

# Check Redis
echo "5. Checking Redis Cache..."
echo "────────────────────────────────────────────────────────────────"

if docker exec hospital-redis redis-cli ping > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Redis: responding to ping"
else
    echo -e "${RED}✗${NC} Redis: not responding"
    exit 1
fi

echo ""

# Check access URLs
echo "6. Access URLs..."
echo "────────────────────────────────────────────────────────────────"

VM_IP=$(curl -s -4 ifconfig.me 2>/dev/null || echo "localhost")

echo "  Admin Panel:     http://$VM_IP/"
echo "  Patient Portal:  http://$VM_IP/portal/"
echo "  API Health:      http://$VM_IP/api-server/health"
echo "  Images:          http://$VM_IP/images/"

echo ""

# Check BASE_SUBDOMAIN
echo "7. Multi-Tenant Configuration..."
echo "────────────────────────────────────────────────────────────────"

BASE_SUBDOMAIN=$(grep "^BASE_SUBDOMAIN=" hms-backend.env | cut -d'=' -f2)
echo "  Default Tenant:  $BASE_SUBDOMAIN"
echo "  Tenant Pattern:  <hospital>-${BASE_SUBDOMAIN}.yourdomain.com"

echo ""

# Final summary
echo "════════════════════════════════════════════════════════════════"
echo -e "  ${GREEN}✓ Deployment Verification Complete!${NC}"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Next Steps:"
echo "  1. Open: http://$VM_IP/"
echo "  2. Create first admin user"
echo "  3. Configure tenant settings"
echo ""
echo "Monitoring Commands:"
echo "  • View all logs:    docker compose logs -f"
echo "  • View API logs:    docker logs -f api-hospital"
echo "  • View Nginx logs:  docker logs -f nginx-reverse-proxy"
echo "  • Container status: docker compose ps"
echo ""
