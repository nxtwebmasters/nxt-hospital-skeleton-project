#!/bin/bash
# Quick Tenant Verification Script
# Checks if tenant resolution is working correctly

set -e

echo "🔍 HMS Tenant Resolution Verification"
echo "======================================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Database credentials
DB_HOST="${DB_HOST:-localhost}"
DB_USER="${DB_USER:-nxt_user}"
DB_PASS="${DB_PASS:-NxtWebMasters464}"
DB_NAME="${DB_NAME:-nxt-hospital}"

# Check if running in Docker context
if docker ps | grep -q hospital-mysql; then
    echo -e "${GREEN}✓${NC} Docker containers detected"
    MYSQL_CMD="docker exec -i hospital-mysql mysql -u $DB_USER -p$DB_PASS $DB_NAME"
else
    echo -e "${YELLOW}⚠${NC} No Docker containers found, trying local MySQL"
    MYSQL_CMD="mysql -h $DB_HOST -u $DB_USER -p$DB_PASS $DB_NAME"
fi

echo ""
echo "Step 1: Checking tenant records..."
echo "-----------------------------------"

$MYSQL_CMD -e "SELECT tenant_id, tenant_subdomain, tenant_status FROM nxt_tenant;" 2>/dev/null || {
    echo -e "${RED}✗${NC} Could not query database"
    echo "   Make sure MySQL is running and credentials are correct"
    exit 1
}

echo ""
echo "Step 2: Verifying system default tenant..."
echo "------------------------------------------"

SUBDOMAIN=$($MYSQL_CMD -sN -e "SELECT tenant_subdomain FROM nxt_tenant WHERE tenant_id = 'system_default_tenant';" 2>/dev/null)

if [ -z "$SUBDOMAIN" ]; then
    echo -e "${RED}✗${NC} System default tenant not found!"
    echo "   Run: docker compose up -d to initialize database"
    exit 1
fi

echo -e "System tenant subdomain: ${GREEN}$SUBDOMAIN${NC}"

# Expected subdomain for hms.nxtwebmasters.com is 'hms'
if [ "$SUBDOMAIN" = "hms" ]; then
    echo -e "${GREEN}✓${NC} Subdomain is correctly set to 'hms'"
elif [ "$SUBDOMAIN" = "default" ]; then
    echo -e "${RED}✗${NC} Subdomain is 'default' but should be 'hms' for hms.nxtwebmasters.com"
    echo ""
    echo "To fix:"
    echo "  docker exec -i hospital-mysql mysql -u $DB_USER -p$DB_PASS $DB_NAME <<EOF"
    echo "  UPDATE nxt_tenant SET tenant_subdomain = 'hms' WHERE tenant_id = 'system_default_tenant';"
    echo "  EOF"
    exit 1
else
    echo -e "${YELLOW}⚠${NC} Subdomain is '$SUBDOMAIN' - verify this matches your domain"
fi

echo ""
echo "Step 3: Checking Redis cache..."
echo "-------------------------------"

if docker ps | grep -q hospital-redis; then
    echo -e "${GREEN}✓${NC} Redis container found"
    docker exec hospital-redis redis-cli PING > /dev/null 2>&1 && {
        echo -e "${GREEN}✓${NC} Redis is responding"
    } || {
        echo -e "${RED}✗${NC} Redis not responding"
    }
else
    echo -e "${YELLOW}⚠${NC} Redis container not found"
fi

echo ""
echo "Step 4: Checking backend service..."
echo "-----------------------------------"

if docker ps | grep -q hospital-hms-backend; then
    echo -e "${GREEN}✓${NC} Backend container is running"
    
    # Check environment variable
    BASE_SUB=$(docker exec hospital-hms-backend printenv BASE_SUBDOMAIN 2>/dev/null || echo "not set")
    if [ "$BASE_SUB" = "hms" ]; then
        echo -e "${GREEN}✓${NC} BASE_SUBDOMAIN environment variable is set to 'hms'"
    elif [ "$BASE_SUB" = "not set" ]; then
        echo -e "${YELLOW}⚠${NC} BASE_SUBDOMAIN not set (will default to 'hms')"
    else
        echo -e "${YELLOW}⚠${NC} BASE_SUBDOMAIN is set to '$BASE_SUB'"
    fi
else
    echo -e "${RED}✗${NC} Backend container not running"
fi

echo ""
echo "Step 5: Testing debug endpoint..."
echo "---------------------------------"

DOMAIN="${DOMAIN:-hms.nxtwebmasters.com}"
PROTOCOL="${PROTOCOL:-https}"
URL="${PROTOCOL}://${DOMAIN}/api-server/tenant/debug"

echo "Testing: $URL"

if command -v curl &> /dev/null; then
    RESPONSE=$(curl -s -w "\n%{http_code}" "$URL" 2>/dev/null || echo "000")
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | sed '$d')
    
    if [ "$HTTP_CODE" = "200" ]; then
        echo -e "${GREEN}✓${NC} Debug endpoint responding (HTTP $HTTP_CODE)"
        
        # Parse JSON response
        EXTRACTED=$(echo "$BODY" | grep -o '"extractedSubdomain":"[^"]*"' | cut -d'"' -f4)
        FOUND=$(echo "$BODY" | grep -o '"tenantFound":[^,}]*' | cut -d':' -f2)
        
        if [ -n "$EXTRACTED" ]; then
            echo "  Extracted subdomain: $EXTRACTED"
        fi
        
        if [ "$FOUND" = "true" ]; then
            echo -e "  ${GREEN}✓${NC} Tenant found in database"
        else
            echo -e "  ${RED}✗${NC} Tenant NOT found in database"
            echo ""
            echo "This means the subdomain extracted from your domain doesn't match"
            echo "any tenant record. Check the subdomain in your database."
        fi
    else
        echo -e "${YELLOW}⚠${NC} Debug endpoint not accessible (HTTP $HTTP_CODE)"
        echo "  This might be normal if you're not deployed yet"
    fi
else
    echo -e "${YELLOW}⚠${NC} curl not found, skipping endpoint test"
fi

echo ""
echo "======================================"
echo -e "${GREEN}Verification complete!${NC}"
echo "======================================"
echo ""

if [ "$SUBDOMAIN" = "hms" ] && [ "$FOUND" = "true" ]; then
    echo -e "${GREEN}✓ All checks passed!${NC} Your tenant resolution should work correctly."
else
    echo -e "${YELLOW}Some issues detected. See messages above for fixes.${NC}"
fi

echo ""
