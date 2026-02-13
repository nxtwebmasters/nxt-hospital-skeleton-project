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

# Function to execute a migration file
run_migration() {
    local migration_file=$1
    local filename=$(basename "$migration_file")
    
    echo -e "${YELLOW}Running migration: $filename${NC}"
    
    # Execute migration using docker-compose exec
    if docker-compose ps mysql | grep -q "Up"; then
        # Use docker-compose exec for container MySQL
        docker-compose exec -T mysql mysql -u"$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" < "$migration_file"
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Migration $filename completed successfully${NC}"
            return 0
        else
            echo -e "${RED}✗ Migration $filename failed${NC}"
            return 1
        fi
    else
        # Use direct MySQL connection if container is not running
        mysql -h "$DB_HOST" -u"$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" < "$migration_file"
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Migration $filename completed successfully${NC}"
            return 0
        else
            echo -e "${RED}✗ Migration $filename failed${NC}"
            return 1
        fi
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
