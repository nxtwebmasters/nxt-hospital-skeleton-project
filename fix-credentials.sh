#!/bin/bash
################################################################################
# HMS Credential Fixer Script
# 
# Use this script to extract and update config files with actual credentials
# from running Docker containers when deploy.sh failed to update files properly.
#
# Usage: ./fix-credentials.sh
################################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo -e "${GREEN}HMS Credential Extraction & Fix Tool${NC}"
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo ""

# Check if Docker is running
if ! docker ps &> /dev/null; then
    echo -e "${RED}Error: Docker is not running or you don't have permission.${NC}"
    exit 1
fi

# Check if containers are running
if ! docker ps | grep -q "hospital-mysql"; then
    echo -e "${RED}Error: hospital-mysql container is not running.${NC}"
    echo "Please start your containers first: docker compose up -d"
    exit 1
fi

echo -e "${YELLOW}Step 1: Extracting credentials from running containers...${NC}"
echo ""

# Extract MySQL credentials
MYSQL_PASSWORD=$(docker exec hospital-mysql printenv MYSQL_PASSWORD 2>/dev/null || echo "")
MYSQL_ROOT_PASSWORD=$(docker exec hospital-mysql printenv MYSQL_ROOT_PASSWORD 2>/dev/null || echo "")

# Extract Backend credentials
DB_PASSWORD=$(docker exec api-hospital printenv DB_PASSWORD 2>/dev/null || echo "")
JWT_SECRET=$(docker exec api-hospital printenv JWT_SECRET 2>/dev/null || echo "")
BASE_SUBDOMAIN=$(docker exec api-hospital printenv BASE_SUBDOMAIN 2>/dev/null || echo "")
EMAIL_USER=$(docker exec api-hospital printenv EMAIL_USER 2>/dev/null || echo "")
EMAIL_PASSWORD=$(docker exec api-hospital printenv EMAIL_PASSWORD 2>/dev/null || echo "")

# Display extracted credentials
echo -e "${GREEN}✓ Credentials extracted successfully:${NC}"
echo "  MYSQL_PASSWORD: $MYSQL_PASSWORD"
echo "  MYSQL_ROOT_PASSWORD: $MYSQL_ROOT_PASSWORD"
echo "  DB_PASSWORD: $DB_PASSWORD"
echo "  JWT_SECRET: ${JWT_SECRET:0:20}... (truncated)"
echo "  BASE_SUBDOMAIN: $BASE_SUBDOMAIN"
echo "  EMAIL_USER: $EMAIL_USER"
echo ""

# Verify passwords match
if [ "$MYSQL_PASSWORD" != "$DB_PASSWORD" ]; then
    echo -e "${RED}Warning: MYSQL_PASSWORD and DB_PASSWORD don't match!${NC}"
    echo "  MYSQL_PASSWORD: $MYSQL_PASSWORD"
    echo "  DB_PASSWORD: $DB_PASSWORD"
    echo ""
fi

echo -e "${YELLOW}Step 2: Updating docker-compose.yml...${NC}"

# Backup original files
cp docker-compose.yml docker-compose.yml.backup.$(date +%Y%m%d_%H%M%S)
cp hms-backend.env hms-backend.env.backup.$(date +%Y%m%d_%H%M%S)
echo -e "${GREEN}✓ Backup files created${NC}"

# Update docker-compose.yml
sed -i "s|MYSQL_ROOT_PASSWORD:.*|MYSQL_ROOT_PASSWORD: \"$MYSQL_ROOT_PASSWORD\"|g" docker-compose.yml
sed -i "s|MYSQL_PASSWORD:.*|MYSQL_PASSWORD: \"$MYSQL_PASSWORD\"|g" docker-compose.yml

echo -e "${GREEN}✓ docker-compose.yml updated${NC}"

echo -e "${YELLOW}Step 3: Updating hms-backend.env...${NC}"

# Update hms-backend.env
sed -i "s|^DB_PASSWORD=.*|DB_PASSWORD=$DB_PASSWORD|g" hms-backend.env
sed -i "s|^JWT_SECRET=.*|JWT_SECRET=$JWT_SECRET|g" hms-backend.env
sed -i "s|^BASE_SUBDOMAIN=.*|BASE_SUBDOMAIN=$BASE_SUBDOMAIN|g" hms-backend.env

if [ -n "$EMAIL_USER" ] && [ "$EMAIL_USER" != "noreply@yourdomain.com" ]; then
    sed -i "s|^EMAIL_USER=.*|EMAIL_USER=$EMAIL_USER|g" hms-backend.env
fi

if [ -n "$EMAIL_PASSWORD" ] && [ "$EMAIL_PASSWORD" != "your-smtp-app-password" ]; then
    sed -i "s|^EMAIL_PASSWORD=.*|EMAIL_PASSWORD=$EMAIL_PASSWORD|g" hms-backend.env
fi

echo -e "${GREEN}✓ hms-backend.env updated${NC}"

echo ""
echo -e "${YELLOW}Step 4: Verifying updates...${NC}"

# Verify no placeholders remain
if grep -q "REPLACE_WITH_SECURE_PASSWORD" docker-compose.yml hms-backend.env; then
    echo -e "${RED}✗ Warning: Some placeholders still exist!${NC}"
    grep "REPLACE_WITH_SECURE_PASSWORD" docker-compose.yml hms-backend.env
else
    echo -e "${GREEN}✓ All placeholders replaced successfully${NC}"
fi

echo ""
echo -e "${YELLOW}Step 5: Saving credentials to file...${NC}"

CREDS_FILE="$HOME/.hms_credentials_fixed_$(date +%Y%m%d).txt"
cat > "$CREDS_FILE" << EOF
═══════════════════════════════════════
HMS Production Credentials (Extracted)
Date: $(date)
═══════════════════════════════════════

Multi-Tenancy Configuration:
  Base Subdomain:      $BASE_SUBDOMAIN

MySQL Credentials:
  Root Password:       $MYSQL_ROOT_PASSWORD
  User:                nxt_user
  User Password:       $MYSQL_PASSWORD
  Database:            nxt-hospital

Backend Credentials:
  DB Password:         $DB_PASSWORD
  JWT Secret:          $JWT_SECRET

Email Configuration:
  Email User:          $EMAIL_USER
  Email Password:      $EMAIL_PASSWORD

DBeaver Connection Settings:
  Host:                localhost (via SSH tunnel) or <server-ip>
  Port:                3306
  Database:            nxt-hospital
  Username:            nxt_user
  Password:            $MYSQL_PASSWORD

SSH Tunnel Command (from Windows/Mac):
  ssh -L 3306:localhost:3306 root@<your-server-ip>

═══════════════════════════════════════
KEEP THIS FILE SECURE!
Location: $CREDS_FILE
═══════════════════════════════════════
EOF

chmod 600 "$CREDS_FILE"
echo -e "${GREEN}✓ Credentials saved to: $CREDS_FILE${NC}"

echo ""
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo -e "${GREEN}Credential Fix Complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo ""
echo "Your configuration files have been updated with actual credentials."
echo "Backup files created: *.backup.*"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. View credentials: cat $CREDS_FILE"
echo "2. Commit updated files to your repo (if needed)"
echo "3. Connect to MySQL with DBeaver using credentials above"
echo ""
