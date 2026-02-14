#!/bin/bash

# Migration Runner for NXT Hospital Management System
# Executes database migration scripts in the data/scripts/migrations folder

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}===== NXT Hospital Database Migration Runner =====${NC}"
echo ""

# Load environment variables from hms-backend.env
if [ -f "hms-backend.env" ]; then
    echo -e "${GREEN}✓ Loading environment from hms-backend.env${NC}"
    export $(cat hms-backend.env | grep -v '^#' | grep -v '^$' | xargs)
else
    echo -e "${RED}✗ Error: hms-backend.env not found${NC}"
    exit 1
fi

# Database connection details
DB_HOST="${DB_HOST:-localhost}"
DB_NAME="${SOURCE_DB_NAME:-nxt-hospital}"
DB_USER="${DB_USERNAME:-root}"
DB_PASSWORD="${DB_PASSWORD}"

# Migrations directory
MIGRATIONS_DIR="./data/scripts/migrations"

# Check if migrations directory exists
if [ ! -d "$MIGRATIONS_DIR" ]; then
    echo -e "${RED}✗ Error: Migrations directory not found: $MIGRATIONS_DIR${NC}"
    exit 1
fi

# Count migration files
MIGRATION_FILES=$(ls -1 "$MIGRATIONS_DIR"/*.sql 2>/dev/null | wc -l)

if [ "$MIGRATION_FILES" -eq 0 ]; then
    echo -e "${YELLOW}⚠ No migration files found in $MIGRATIONS_DIR${NC}"
    exit 0
fi

echo -e "${CYAN}Found $MIGRATION_FILES migration file(s)${NC}"
echo ""

# Debug: Show detected Docker Compose command
if [ -n "$DOCKER_COMPOSE_CMD" ]; then
    echo -e "${CYAN}Docker Compose detected: $DOCKER_COMPOSE_CMD${NC}"
else
    echo -e "${YELLOW}Docker Compose not detected, will use direct MySQL connection${NC}"
fi
echo ""

# Detect docker compose command (v2 uses 'docker compose', v1 uses 'docker-compose')
DOCKER_COMPOSE_CMD=""
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker-compose"
elif command -v docker &> /dev/null && docker compose version &> /dev/null 2>&1; then
    DOCKER_COMPOSE_CMD="docker compose"
fi

# Function to execute a migration file
run_migration() {
    local migration_file=$1
    local filename=$(basename "$migration_file")
    
    echo -e "${YELLOW}Running migration: $filename${NC}"
    
    # Try docker first (most common on VMs)
    if [ -n "$DOCKER_COMPOSE_CMD" ]; then
        # Check if MySQL container is running
        echo -e "${CYAN}Checking MySQL container status...${NC}"
        MYSQL_CONTAINER_STATUS=$($DOCKER_COMPOSE_CMD ps 2>&1 | grep mysql || echo "")
        
        if [ -n "$MYSQL_CONTAINER_STATUS" ] && echo "$MYSQL_CONTAINER_STATUS" | grep -qE "(Up|running)"; then
            echo -e "${CYAN}✓ MySQL container is running, using Docker exec${NC}"
            # Use docker exec to run migration inside container
            cat "$migration_file" | $DOCKER_COMPOSE_CMD exec -T mysql mysql -u"$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" 2>&1
            
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✓ Migration $filename completed successfully${NC}"
                return 0
            else
                echo -e "${RED}✗ Migration $filename failed in Docker container${NC}"
                return 1
            fi
        else
            echo -e "${YELLOW}⚠ MySQL container not running or not found${NC}"
            echo -e "${YELLOW}Container status: $MYSQL_CONTAINER_STATUS${NC}"
        fi
    fi
    
    # Fallback to direct MySQL connection if docker not available or container not running
    if command -v mysql &> /dev/null; then
        echo -e "${CYAN}Using direct MySQL connection${NC}"
        mysql -h "$DB_HOST" -u"$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" < "$migration_file" 2>&1
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Migration $filename completed successfully${NC}"
            return 0
        else
            echo -e "${RED}✗ Migration $filename failed with direct connection${NC}"
            return 1
        fi
    else
        echo -e "${RED}✗ Error: Neither docker nor mysql command available${NC}"
        return 1
    fi
}

# Run all migrations in order
FAILED_MIGRATIONS=0
SUCCESSFUL_MIGRATIONS=0

for migration_file in "$MIGRATIONS_DIR"/*.sql; do
    if [ -f "$migration_file" ]; then
        if run_migration "$migration_file"; then
            ((SUCCESSFUL_MIGRATIONS++))
        else
            ((FAILED_MIGRATIONS++))
            echo -e "${RED}Stopping migration process due to error${NC}"
            break
        fi
        echo ""
    fi
done

# Summary
echo -e "${CYAN}===== Migration Summary =====${NC}"
echo -e "${GREEN}Successful: $SUCCESSFUL_MIGRATIONS${NC}"
echo -e "${RED}Failed: $FAILED_MIGRATIONS${NC}"
echo ""

if [ $FAILED_MIGRATIONS -eq 0 ]; then
    echo -e "${GREEN}✓ All migrations completed successfully!${NC}"
    echo ""
    echo -e "${CYAN}Next steps:${NC}"
    echo "1. Restart backend: docker-compose restart hospital-apis"
    echo "2. Test payment receipts endpoint: curl http://localhost:3001/api-server/payment/receipts"
    echo "3. Access admin panel: Payment Receipts in Tenant Management"
    echo ""
    exit 0
else
    echo -e "${RED}✗ Some migrations failed. Please check the errors above.${NC}"
    echo ""
    exit 1
fi
