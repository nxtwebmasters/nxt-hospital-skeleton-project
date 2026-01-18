#!/bin/bash

# Fix MySQL Deployment Issues
# This script fixes the foreign key constraint error and cleans up the database

set -e

echo "=========================================="
echo "   MySQL Deployment Fix Script"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
  echo -e "${RED}Please run as root (use sudo)${NC}"
  exit 1
fi

echo -e "${YELLOW}Step 1: Stopping all containers...${NC}"
cd ~/nxt-hospital-skeleton-project
docker-compose down

echo ""
echo -e "${YELLOW}Step 2: Removing MySQL data volume to start fresh...${NC}"
docker volume rm nxt-hospital-skeleton-project_mysql-data 2>/dev/null || echo "Volume already removed or doesn't exist"

echo ""
echo -e "${YELLOW}Step 3: Removing any stale MySQL socket files...${NC}"
docker volume create nxt-hospital-skeleton-project_mysql-data
# Prune any orphaned containers that might hold the socket
docker container prune -f

echo ""
echo -e "${YELLOW}Step 4: Verifying schema fix...${NC}"
if grep -q "ADD UNIQUE KEY \`unique_bill_uuid\`" ~/nxt-hospital-skeleton-project/data/scripts/1-schema.sql; then
    echo -e "${GREEN}✓ Schema file has been fixed (unique constraint on bill_uuid added)${NC}"
else
    echo -e "${RED}✗ Schema file needs manual fix${NC}"
    echo "The foreign key constraint issue requires adding:"
    echo "  ADD UNIQUE KEY \`unique_bill_uuid\` (\`bill_uuid\`),"
    echo "to the nxt_bill table indexes section"
    exit 1
fi

echo ""
echo -e "${YELLOW}Step 5: Starting MySQL container first...${NC}"
docker-compose up -d hospital-mysql

echo ""
echo -e "${YELLOW}Step 6: Waiting for MySQL to initialize (this may take 60-90 seconds)...${NC}"

# Wait function with better feedback
wait_for_mysql() {
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        echo -n "  Attempt $attempt/$max_attempts: "
        
        # Check if container is running
        if ! docker ps | grep -q hospital-mysql; then
            echo -e "${RED}Container not running${NC}"
            echo ""
            echo "Checking container logs:"
            docker logs --tail 50 hospital-mysql
            return 1
        fi
        
        # Check health status
        health=$(docker inspect --format='{{.State.Health.Status}}' hospital-mysql 2>/dev/null || echo "none")
        
        if [ "$health" = "healthy" ]; then
            echo -e "${GREEN}MySQL is healthy!${NC}"
            return 0
        elif [ "$health" = "none" ]; then
            # No healthcheck, try connection test
            if docker exec hospital-mysql mysqladmin ping -h localhost --silent 2>/dev/null; then
                echo -e "${GREEN}MySQL is responsive!${NC}"
                return 0
            else
                echo -e "${YELLOW}Starting up...${NC}"
            fi
        else
            echo -e "${YELLOW}Health: $health${NC}"
        fi
        
        sleep 3
        attempt=$((attempt + 1))
    done
    
    echo -e "${RED}MySQL failed to start within expected time${NC}"
    return 1
}

if wait_for_mysql; then
    echo ""
    echo -e "${GREEN}✓ MySQL initialized successfully${NC}"
    
    # Verify database was created
    echo ""
    echo -e "${YELLOW}Step 7: Verifying database creation...${NC}"
    if docker exec hospital-mysql mysql -u nxt_user -p\${MYSQL_PASSWORD:-nxt_password} -e "SHOW DATABASES LIKE 'nxt-hospital';" | grep -q "nxt-hospital"; then
        echo -e "${GREEN}✓ Database 'nxt-hospital' created successfully${NC}"
        
        # Check for schema loading errors
        if docker logs hospital-mysql 2>&1 | grep -q "ERROR.*at line"; then
            echo -e "${RED}⚠ Schema errors detected in initialization${NC}"
            echo "Last 20 lines of MySQL logs:"
            docker logs --tail 20 hospital-mysql
        else
            echo -e "${GREEN}✓ Schema loaded without errors${NC}"
        fi
    else
        echo -e "${RED}✗ Database creation failed${NC}"
        docker logs --tail 50 hospital-mysql
        exit 1
    fi
    
    echo ""
    echo -e "${YELLOW}Step 8: Starting remaining services...${NC}"
    docker-compose up -d
    
    echo ""
    echo -e "${YELLOW}Step 9: Waiting for all services to be healthy...${NC}"
    sleep 5
    
    echo ""
    echo "=========================================="
    echo "          Deployment Status"
    echo "=========================================="
    docker-compose ps
    
    echo ""
    echo -e "${GREEN}✓ Deployment fix completed!${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Check container status: docker-compose ps"
    echo "  2. View logs: docker-compose logs -f"
    echo "  3. Check MySQL logs: docker logs hospital-mysql"
    echo "  4. Access backend health: curl http://localhost:3030/health"
    echo ""
    
else
    echo ""
    echo -e "${RED}✗ MySQL initialization failed${NC}"
    echo ""
    echo "Detailed MySQL logs:"
    docker logs hospital-mysql
    echo ""
    echo "Please review the logs above for specific errors."
    exit 1
fi
