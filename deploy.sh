#!/bin/bash

################################################################################
# NXT HMS - Automated Production Deployment Script
# For Ubuntu 20.04+ / Debian-based systems
# 
# Prerequisites: Docker, Docker Compose installed
# 
# Usage: 
#   1. Clone this repository
#   2. cd into repository directory
#   3. (Optional) Create deployment-config.local.sh with your settings
#   4. Run: ./deploy.sh
#
# Configuration:
#   - Uses deployment-config.local.sh (if exists) for automated deployments
#   - Falls back to deployment-config.sh for defaults
#   - Prompts interactively if no config found
#
# Examples:
#   ./deploy.sh                    # Interactive mode
#   ./deploy.sh --config custom.sh # Use custom config file
#   ./deploy.sh --help             # Show usage
################################################################################

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log file
LOG_FILE="deployment_$(date +%Y%m%d_%H%M%S).log"
DEPLOYMENT_DIR="$(pwd)"  # Use current directory
DOCKER_COMPOSE_CMD="docker compose"  # Default, will be updated in preflight_checks

# Configuration file paths
DEFAULT_CONFIG="deployment-config.sh"
LOCAL_CONFIG="deployment-config.local.sh"
CUSTOM_CONFIG=""
CONFIG_LOADED=0

################################################################################
# Helper Functions
################################################################################

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

prompt_yes_no() {
    while true; do
        read -p "$1 (y/n): " yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        log_error "$1 is not installed. Please install it first."
        exit 1
    fi
}

generate_password() {
    openssl rand -base64 24 | tr -d "=+/" | cut -c1-24
}

generate_jwt_secret() {
    openssl rand -hex 32
}

# Wrapper for sudo that handles root user
sudo_wrapper() {
    if [ "$EUID" -eq 0 ]; then
        # Already root, execute directly
        "$@"
    else
        # Not root, use sudo
        sudo "$@"
    fi
}

################################################################################
# Configuration Loading
################################################################################

show_usage() {
    cat << EOF
═══════════════════════════════════════════════════════════════
  NXT HMS - Multi-Tenant Hospital Management System Deployment
═══════════════════════════════════════════════════════════════

Usage: $0 [OPTIONS]

Options:
  --config FILE    Use custom configuration file
  --help, -h       Show this help message
  --version        Show version information

Configuration:
  The script looks for configuration in this order:
    1. Custom file specified with --config
    2. deployment-config.local.sh (git-ignored, for your env)
    3. deployment-config.sh (default template)
    4. Interactive prompts

Examples:
  $0                                  # Interactive or auto-config
  $0 --config familycare.config.sh   # Use specific config
  
Get Started:
  1. Copy: cp deployment-config.sh deployment-config.local.sh
  2. Edit: nano deployment-config.local.sh
  3. Set DEPLOYMENT_DOMAIN and DEFAULT_TENANT_SUBDOMAIN
  4. Run: ./deploy.sh

═══════════════════════════════════════════════════════════════
EOF
    exit 0
}

load_deployment_config() {
    log "=========================================="
    log "Loading Deployment Configuration"
    log "=========================================="
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --config)
                CUSTOM_CONFIG="$2"
                shift 2
                ;;
            --help|-h)
                show_usage
                ;;
            --version)
                echo "NXT HMS Deployment Script v2.0.0"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                ;;
        esac
    done
    
    # Determine which config file to use
    if [ -n "$CUSTOM_CONFIG" ]; then
        if [ -f "$CUSTOM_CONFIG" ]; then
            CONFIG_FILE="$CUSTOM_CONFIG"
            log "Using custom config: $CUSTOM_CONFIG"
        else
            log_error "Custom config file not found: $CUSTOM_CONFIG"
            exit 1
        fi
    elif [ -f "$LOCAL_CONFIG" ]; then
        CONFIG_FILE="$LOCAL_CONFIG"
        log "Using local config: $LOCAL_CONFIG"
    elif [ -f "$DEFAULT_CONFIG" ]; then
        CONFIG_FILE="$DEFAULT_CONFIG"
        log_warning "Using default config: $DEFAULT_CONFIG"
        log_warning "For production, create deployment-config.local.sh"
    else
        log_info "No config file found. Will use interactive mode."
        CONFIG_LOADED=0
        return
    fi
    
    # Source the configuration file
    log "Loading configuration from: $CONFIG_FILE"
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
    
    # Validate configuration if validation function exists
    if declare -f validate_config > /dev/null; then
        if ! validate_config; then
            log_error "Configuration validation failed"
            exit 1
        fi
    fi
    
    CONFIG_LOADED=1
    log "✓ Configuration loaded successfully"
    log "  Domain: ${DEPLOYMENT_DOMAIN:-<Will use VM IP>}"
    log "  Default Tenant: $DEFAULT_TENANT_SUBDOMAIN"
    log "  Mode: $DEPLOYMENT_MODE"
}

################################################################################
# Phase 1: Pre-flight Checks
################################################################################

preflight_checks() {
    log "=========================================="
    log "Phase 1: Pre-flight Checks"
    log "=========================================="

    # Check if we're in the right directory
    if [ ! -f "docker-compose.yml" ] || [ ! -f "hms-backend.env" ]; then
        log_error "This script must be run from the nxt-hospital-skeleton-project directory!"
        log_error "Please cd into the cloned repository first."
        exit 1
    fi

    # Check if running as root
    if [ "$EUID" -eq 0 ]; then 
        log_warning "Running as root user. This is acceptable for VPS/VM deployments."
        log_warning "Note: sudo commands will run directly without password prompts."
    fi

    # Check required commands
    log "Checking required dependencies..."
    check_command "docker"
    check_command "curl"
    
    # Check Docker Compose (v2 vs v1)
    if docker compose version &> /dev/null; then
        log "✓ Docker Compose v2 detected: $(docker compose version)"
    elif docker-compose version &> /dev/null; then
        log_warning "Docker Compose v1 detected. v2 is recommended."
        DOCKER_COMPOSE_CMD="docker-compose"
    else
        log_error "Docker Compose not found. Please install Docker Compose."
        exit 1
    fi
    DOCKER_COMPOSE_CMD=${DOCKER_COMPOSE_CMD:-"docker compose"}

    # Check disk space (need at least 20GB)
    available_space=$(df / | tail -1 | awk '{print $4}')
    required_space=$((20 * 1024 * 1024))  # 20GB in KB
    if [ "$available_space" -lt "$required_space" ]; then
        log_error "Insufficient disk space. Required: 20GB, Available: $((available_space / 1024 / 1024))GB"
        exit 1
    fi
    log "✓ Disk space check passed: $((available_space / 1024 / 1024))GB available"

    # Check RAM (recommend at least 2GB)
    total_ram=$(free -m | awk 'NR==2{print $2}')
    if [ "$total_ram" -lt 2048 ]; then
        log_warning "Low RAM detected: ${total_ram}MB. Recommended: 4GB+"
        if ! prompt_yes_no "Continue anyway?"; then
            exit 0
        fi
    else
        log "✓ RAM check passed: ${total_ram}MB"
    fi

    # Check if ports 80 and 443 are available
    if sudo_wrapper netstat -tlnp 2>/dev/null | grep -E ':80 |:443 ' > /dev/null; then
        log_warning "Ports 80 or 443 are already in use"
        if prompt_yes_no "Attempt to stop conflicting services (apache2/nginx)?"; then
            sudo_wrapper systemctl stop apache2 2>/dev/null || true
            sudo_wrapper systemctl disable apache2 2>/dev/null || true
            sudo_wrapper systemctl stop nginx 2>/dev/null || true
            sudo_wrapper systemctl disable nginx 2>/dev/null || true
            log "✓ Stopped conflicting web servers"
        fi
    else
        log "✓ Ports 80 and 443 are available"
    fi

    log "✓ Pre-flight checks completed successfully"
}

################################################################################
# Phase 2: System Setup
################################################################################

system_setup() {
    log "=========================================="
    log "Phase 2: System Setup & Dependencies"
    log "=========================================="

    # Update package lists
    log "Updating package lists..."
    sudo_wrapper apt update >> "$LOG_FILE" 2>&1

    # Install essential utilities
    log "Installing essential utilities..."
    sudo_wrapper apt install -y curl wget nano htop net-tools ufw openssl >> "$LOG_FILE" 2>&1

    # Configure firewall
    if prompt_yes_no "Configure UFW firewall (allow SSH, HTTP, HTTPS)?"; then
        log "Configuring firewall..."
        sudo_wrapper ufw allow 22/tcp >> "$LOG_FILE" 2>&1
        sudo_wrapper ufw allow 80/tcp >> "$LOG_FILE" 2>&1
        sudo_wrapper ufw allow 443/tcp >> "$LOG_FILE" 2>&1
        echo "y" | sudo_wrapper ufw enable >> "$LOG_FILE" 2>&1
        log "✓ Firewall configured"
    fi

    # Configure Docker permissions (skip if root)
    if [ "$EUID" -ne 0 ]; then
        log "Configuring Docker permissions..."
        if ! groups | grep -q docker; then
            sudo usermod -aG docker "$USER"
            log_warning "Docker group added. You may need to log out and back in for this to take effect."
            log "Attempting to continue with newgrp docker..."
        fi
    else
        log "✓ Running as root, Docker permissions not needed"
    fi

    log "✓ System setup completed"
}

################################################################################
# Phase 3: Setup Directories
################################################################################

setup_directories() {
    log "=========================================="
    log "Phase 3: Setup Directories"
    log "=========================================="

    # Create images directory
    log "Creating images directory for file storage..."
    mkdir -p images
    chmod 755 images
    
    log "✓ Directory setup completed"
}

################################################################################
# Phase 4: Configuration
################################################################################

configure_environment() {
    log "=========================================="
    log "Phase 4: Environment Configuration"
    log "=========================================="

    # Backup original env file
    if [ -f "hms-backend.env" ]; then
        cp hms-backend.env "hms-backend.env.backup.$(date +%Y%m%d_%H%M%S)"
        log "✓ Backed up original environment file"
    fi

    # Get VM IP (always needed for fallback)
    export VM_IP=$(curl -s -4 ifconfig.me 2>/dev/null || echo "localhost")
    
    # If config loaded, use those values; otherwise prompt
    if [ $CONFIG_LOADED -eq 1 ]; then
        log "Using configuration from file..."
        
        # Use configured domain or fall back to VM IP
        if [ -n "$DEPLOYMENT_DOMAIN" ]; then
            export DOMAIN_OR_IP="$DEPLOYMENT_DOMAIN"
        else
            export DOMAIN_OR_IP="$VM_IP"
        fi
        
        # Use configured tenant subdomain (required)
        if [ -z "$DEFAULT_TENANT_SUBDOMAIN" ]; then
            log_error "DEFAULT_TENANT_SUBDOMAIN not set in config file"
            exit 1
        fi
        export BASE_SUBDOMAIN="$DEFAULT_TENANT_SUBDOMAIN"
        
        # Use configured credentials or generate new ones
        SMTP_EMAIL="${SMTP_EMAIL:-noreply@$DOMAIN_OR_IP}"
        SMTP_PASSWORD="${SMTP_PASSWORD:-disabled}"
        export SSL_EMAIL="$SMTP_EMAIL"
        
        # Convert ADMIN_EMAILS to JSON array if needed
        if [ -n "$ADMIN_EMAILS" ]; then
            # Check if already in JSON format
            if [[ "$ADMIN_EMAILS" =~ ^\[.*\]$ ]]; then
                ADMIN_EMAILS_JSON="$ADMIN_EMAILS"
            else
                # Convert comma-separated to JSON array
                ADMIN_EMAILS_JSON=$(echo "$ADMIN_EMAILS" | awk -F',' '{for(i=1;i<=NF;i++){printf "\"%s\"%s", $i, (i<NF?",":"")}}')
                ADMIN_EMAILS_JSON="[$ADMIN_EMAILS_JSON]"
            fi
        else
            ADMIN_EMAILS_JSON="[\"$SMTP_EMAIL\"]"
        fi
        
        # Generate secure passwords if not provided
        if [ -z "$MYSQL_ROOT_PASSWORD" ]; then
            MYSQL_ROOT_PASSWORD=$(generate_password)
            log "Generated MySQL root password"
        fi
        if [ -z "$MYSQL_DB_PASSWORD" ]; then
            MYSQL_DB_PASSWORD=$(generate_password)
            log "Generated MySQL DB password"
        fi
        if [ -z "$JWT_SECRET" ]; then
            JWT_SECRET=$(generate_jwt_secret)
            log "Generated JWT secret"
        fi
        
        # Optional integrations from config
        ENABLE_WHATSAPP="${ENABLE_WHATSAPP:-false}"
        MSGPK_WHATSAPP_API_KEY="${MSGPK_WHATSAPP_API_KEY:-}"
        WHATSAPP_IMAGE_URL="${WHATSAPP_IMAGE_URL:-}"
        OPENAI_API_KEY="${OPENAI_API_KEY:-}"
        OPENAI_MODEL="${OPENAI_MODEL:-gpt-4-turbo}"
        FBR_INTEGRATION_ENABLED="${FBR_INTEGRATION_ENABLED:-false}"
        WEBHOOK_URL="${WEBHOOK_URL:-}"
        
        # Reception share config
        RECEPTION_SHARE_ENABLED="${RECEPTION_SHARE_ENABLED:-true}"
        RECEPTION_SHARE_PERCENTAGE="${RECEPTION_SHARE_PERCENTAGE:-1.25}"
        
        # Patient portal config
        PATIENT_DEFAULT_PASSWORD="${PATIENT_DEFAULT_PASSWORD:-NxtHospital123}"
        
        log "✓ Configuration loaded from file"
        log "  Domain: $DOMAIN_OR_IP"
        log "  Default Tenant: $BASE_SUBDOMAIN"
        log "  SMTP: $SMTP_EMAIL"
        log "  WhatsApp: $ENABLE_WHATSAPP"
        log "  OpenAI: $([ -n "$OPENAI_API_KEY" ] && echo "Enabled" || echo "Disabled")"
        
    else
        # Interactive mode - prompt for all values
        clear
        echo ""
        echo "=========================================="
        echo "  Production Configuration Setup"
        echo "=========================================="
        echo ""
        echo "Please provide the following information:"
        echo ""

        # Domain or IP
        echo "─────────────────────────────────────────"
        echo "1. Domain/IP Address Configuration"
        echo "─────────────────────────────────────────"
        echo "Your VM IP: $VM_IP"
        read -p "Enter your domain name (or press Enter to use VM IP): " USER_DOMAIN
        
        if [ -z "$USER_DOMAIN" ]; then
            export DOMAIN_OR_IP="$VM_IP"
            log "Using VM IP: $DOMAIN_OR_IP"
        else
            export DOMAIN_OR_IP="$USER_DOMAIN"
            log "Using domain: $DOMAIN_OR_IP"
        fi
        
        echo ""
        
        # Base Subdomain / Default Tenant
        echo "─────────────────────────────────────────"
        echo "2. Default Tenant Configuration"
        echo "─────────────────────────────────────────"
        echo "For multi-tenant system, specify the base subdomain."
        echo "Examples:"
        echo "  familycare.nxtwebmasters.com → use 'familycare'"
        echo "  hms.yourdomain.com → use 'hms'"
        echo "  medeast.hospital.com → use 'medeast'"
        echo ""
        read -p "Enter base subdomain/default tenant name: " BASE_SUBDOMAIN
        
        if [ -z "$BASE_SUBDOMAIN" ]; then
            log_error "Base subdomain cannot be empty!"
            exit 1
        fi
        
        export BASE_SUBDOMAIN
        log "Default tenant set to: $BASE_SUBDOMAIN"
        
        echo ""
        
        # Email Configuration
        echo "─────────────────────────────────────────"
        echo "3. Email Configuration (for notifications)"
        echo "─────────────────────────────────────────"
        read -p "SMTP Email (e.g., admin@yourdomain.com): " SMTP_EMAIL
        export SSL_EMAIL="$SMTP_EMAIL"  # Use same email for SSL
        
        if [ -z "$SMTP_EMAIL" ]; then
            log_warning "No email provided. Email notifications will be disabled."
            SMTP_EMAIL="noreply@example.com"
            SMTP_PASSWORD="disabled"
            ADMIN_EMAILS_JSON='["admin@example.com"]'
        else
            read -p "SMTP Password/App Key: " -s SMTP_PASSWORD
            echo ""
            read -p "Admin Email Recipients (comma-separated, e.g., admin@domain.com,support@domain.com): " ADMIN_EMAILS_INPUT
            
            if [ -z "$ADMIN_EMAILS_INPUT" ]; then
                ADMIN_EMAILS_JSON="[\"$SMTP_EMAIL\"]"
            else
                # Convert comma-separated to JSON array format
                ADMIN_EMAILS_JSON=$(echo "$ADMIN_EMAILS_INPUT" | awk -F',' '{for(i=1;i<=NF;i++){printf "\"%s\"%s", $i, (i<NF?",":"")}}')
                ADMIN_EMAILS_JSON="[$ADMIN_EMAILS_JSON]"
            fi
        fi
        
        echo ""
        
        # Generate secure passwords
        echo "─────────────────────────────────────────"
        echo "4. Security Configuration"
        echo "─────────────────────────────────────────"
        log "Generating secure passwords and secrets..."
        MYSQL_ROOT_PASSWORD=$(generate_password)
        MYSQL_DB_PASSWORD=$(generate_password)
        JWT_SECRET=$(generate_jwt_secret)
        
        echo ""
        echo "✓ Generated secure credentials:"
        echo "  - MySQL Root Password: ${MYSQL_ROOT_PASSWORD:0:8}..."
        echo "  - MySQL DB Password:   ${MYSQL_DB_PASSWORD:0:8}..."
        echo "  - JWT Secret:          ${JWT_SECRET:0:16}..."
        echo ""
        
        # Optional integrations
        echo "─────────────────────────────────────────"
        echo "5. Optional Integrations (can configure later)"
        echo "─────────────────────────────────────────"
        
        if prompt_yes_no "Enable WhatsApp integration now?"; then
            read -p "WhatsApp API Key: " MSGPK_WHATSAPP_API_KEY
            read -p "WhatsApp Image URL (optional): " WHATSAPP_IMAGE_URL
            ENABLE_WHATSAPP="true"
        else
            MSGPK_WHATSAPP_API_KEY=""
            WHATSAPP_IMAGE_URL=""
            ENABLE_WHATSAPP="false"
        fi
        
        if prompt_yes_no "Enable OpenAI integration now?"; then
            read -p "OpenAI API Key: " OPENAI_API_KEY
            OPENAI_MODEL="gpt-4-turbo"
        else
            OPENAI_API_KEY=""
            OPENAI_MODEL="gpt-4-turbo"
        fi
        
        # Set defaults for other settings
        FBR_INTEGRATION_ENABLED="false"
        WEBHOOK_URL=""
        RECEPTION_SHARE_ENABLED="true"
        RECEPTION_SHARE_PERCENTAGE="1.25"
        PATIENT_DEFAULT_PASSWORD="NxtHospital123"
        
        echo ""
    fi

    # Update hms-backend.env with all settings
    log "Updating hms-backend.env..."
    
    # Build EMAIL_IMAGE_PATH dynamically
    if [ "$DOMAIN_OR_IP" != "$VM_IP" ]; then
        EMAIL_IMAGE_PATH="https://$DOMAIN_OR_IP/images/logo.png"
    else
        EMAIL_IMAGE_PATH="http://$DOMAIN_OR_IP/images/logo.png"
    fi
    
    # Build WHATSAPP_IMAGE_URL if not set
    if [ -z "$WHATSAPP_IMAGE_URL" ] && [ -n "$DOMAIN_OR_IP" ]; then
        WHATSAPP_IMAGE_URL="https://$DOMAIN_OR_IP/images/logo.jpg"
    fi
    
    cat > hms-backend.env << EOF
# Server Configuration
PORT=80
LOG_LEVEL=info

# Multi-Tenancy Configuration
# Base subdomain for system/default tenant (extracted from hostname)
# For ${DOMAIN_OR_IP}, this is set to '${BASE_SUBDOMAIN}'
# Multi-tenant subdomains will be like: hospital1-${BASE_SUBDOMAIN}.domain.com
BASE_SUBDOMAIN=$BASE_SUBDOMAIN

# Database Configuration (MySQL)
DB_HOST=mysql
SOURCE_DB_NAME=nxt-hospital
DB_USERNAME=nxt_user
DB_PASSWORD=$MYSQL_DB_PASSWORD
DB_CONNECTION_LIMIT=10
DB_MULTIPLE_STATEMENTS=true

# FBR Integration Configuration
FBR_INTEGRATION_ENABLED=$FBR_INTEGRATION_ENABLED
FBR_API_URL_PRODUCTION=https://api.fbr.gov.pk/v1/pos/invoice
FBR_API_URL_SANDBOX=https://api.fbr.gov.pk/v1/pos/sandbox/invoice
FBR_TIMEOUT_MS=30000
FBR_RETRY_ATTEMPTS=3

# Email Configuration
EMAIL_USER=$SMTP_EMAIL
EMAIL_PASSWORD=$SMTP_PASSWORD
EMAIL_IMAGE_PATH=$EMAIL_IMAGE_PATH
EMAIL_RECIPIENTS=$ADMIN_EMAILS_JSON

# JWT Configuration
JWT_SECRET=$JWT_SECRET

# File Storage Configuration
IMAGE_STORAGE_PATH=/usr/share/nginx/html/images
FILE_SERVER_URL=/images

# Webhook Configuration
WEBHOOK_URL=$WEBHOOK_URL

# URL Configuration
CUSTOMER_PORTAL_URL=/assets/print
BACKEND_URL=/api-server
PATIENT_PORTAL_URL=/portal

# CORS Configuration
ALLOWED_ORIGINS=["http://$DOMAIN_OR_IP","https://$DOMAIN_OR_IP","http://localhost","*.localhost","*.local"]

# Database Backup Configuration
BACKUP_TABLES=["nxt_appointment","nxt_slip","nxt_bill","nxt_lab_invoice","nxt_lab_report","nxt_patient","recentactivity"]

# Leave Balance Configuration
LEAVEBALANCE={"sick":8,"earn":16,"annual":5,"compensation":0}

# Redis Configuration
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=
REDIS_MAX_RETRIES=3
REDIS_CONNECT_TIMEOUT=10000
REDIS_COMMAND_TIMEOUT=10000

# URL Configuration
URL_EXPIRATION_MS=900000
DEFAULT_PRINT_LAYOUT=a4
PATIENT_DEFAULT_PASSWORD=$PATIENT_DEFAULT_PASSWORD

# WhatsApp Configuration
ENABLE_WHATSAPP=$ENABLE_WHATSAPP
MSGPK_WHATSAPP_API_URL=https://msgpk.com/api/send.php
MSGPK_WHATSAPP_API_KEY=$MSGPK_WHATSAPP_API_KEY
MSGPK_WHATSAPP_GROUP_API_URL=https://msgpk.com/apps/check_group.php
MSGPK_WHATSAPP_CHECK_API_URL=https://msgpk.com/api/whatsapp_numbers.php
WHATSAPP_MAX_RETRIES=3
WHATSAPP_RETRY_DELAY_MS=1000
WHATSAPP_RATE_LIMIT_DELAY_MS=100
WHATSAPP_IMAGE_URL=$WHATSAPP_IMAGE_URL

# Reception Share Configuration
RECEPTION_SHARE={"ENABLED":$RECEPTION_SHARE_ENABLED,"PERCENTAGE":$RECEPTION_SHARE_PERCENTAGE}

# OpenAI Configuration
OPENAI_API_KEY=$OPENAI_API_KEY
OPENAI_MODEL=$OPENAI_MODEL
MAX_TOKENS=2500
TEMPERATURE=0.5
TOP_P=1.0

# Segment Configuration
ENABLE_SEGMENT_FALLBACK=true
DEFAULT_TIMEZONE=Asia/Karachi

# User Configuration
RETURN_TEMP_PASSWORD=true

# Scheduler Configuration
SCHED_DISABLE=false
SCHED_OPD_DAILY_CRON="0 6 * * *"
SCHED_OPD_WEEKLY_CRON="0 7 * * 1"
SCHED_OPD_BIMONTHLY_CRON="0 7 1,16 * *"
SCHED_OPD_MONTHLY_CRON="0 8 1 * *"
SCHED_DB_BACKUP_CRON="0 2 * * 0"
EOF

    log "✓ Environment configuration completed"
    log "  BASE_SUBDOMAIN=$BASE_SUBDOMAIN"
    log "  DOMAIN_OR_IP=$DOMAIN_OR_IP"
    
    # Update docker-compose.yml with passwords
    log "Updating docker-compose.yml with generated passwords..."
    sed -i "s/MYSQL_ROOT_PASSWORD: \".*\"/MYSQL_ROOT_PASSWORD: \"$MYSQL_ROOT_PASSWORD\"/" docker-compose.yml
    sed -i "s/MYSQL_PASSWORD: \".*\"/MYSQL_PASSWORD: \"$MYSQL_DB_PASSWORD\"/" docker-compose.yml
    
    # CRITICAL: Also update hms-backend.env with matching password
    log "Updating hms-backend.env with matching database password..."
    sed -i "s/^DB_PASSWORD=.*/DB_PASSWORD=$MYSQL_DB_PASSWORD/" hms-backend.env
    
    log "✓ Docker Compose and backend environment updated with secure passwords"
    
    # Replace schema placeholders with actual values
    log "Updating database schema with tenant configuration..."
    sed -i "s/{{DEFAULT_TENANT_SUBDOMAIN}}/$BASE_SUBDOMAIN/g" data/scripts/1-schema.sql
    log "✓ Database schema updated with BASE_SUBDOMAIN=$BASE_SUBDOMAIN"
    
    # Save credentials to a secure file
    CREDS_FILE="$HOME/.hms_credentials_$(date +%Y%m%d).txt"
    cat > "$CREDS_FILE" << EOF
═══════════════════════════════════════
HMS Production Credentials
Generated: $(date)
═══════════════════════════════════════

Multi-Tenancy Configuration:
  Base Subdomain:      $BASE_SUBDOMAIN
  Default Tenant:      ${BASE_SUBDOMAIN} (system_default_tenant)
  Domain:              $DOMAIN_OR_IP

MySQL Root Password: $MYSQL_ROOT_PASSWORD
MySQL DB Password:   $MYSQL_DB_PASSWORD
JWT Secret:          $JWT_SECRET

SMTP Email:          $SMTP_EMAIL

Access URLs:
  Admin Panel:       http://$DOMAIN_OR_IP/
  Patient Portal:    http://$DOMAIN_OR_IP/portal/
  API Health:        http://$DOMAIN_OR_IP/api-server/health

Multi-Tenant Access Pattern:
  - Default tenant:  $DOMAIN_OR_IP (or ${BASE_SUBDOMAIN}.yourdomain.com)
  - Other tenants:   hospital1-${BASE_SUBDOMAIN}.yourdomain.com
  - Tenant creation: POST /api-server/tenant/create

═══════════════════════════════════════
⚠️  IMPORTANT: Save these credentials securely!
    Delete this file after copying to password manager.
═══════════════════════════════════════
EOF
    chmod 600 "$CREDS_FILE"
    
    echo ""
    log "✓ Credentials saved to: $CREDS_FILE"
    echo ""
    read -p "Press Enter to continue with deployment..."
}

################################################################################
# Phase 5: Deployment
################################################################################

deploy_application() {
    log "=========================================="
    log "Phase 5: Application Deployment"
    log "=========================================="

    echo ""
    log "Pulling Docker images (this may take 5-10 minutes)..."
    echo "Please wait..."
    
    if $DOCKER_COMPOSE_CMD pull >> "$LOG_FILE" 2>&1; then
        log "✓ Docker images pulled successfully"
    else
        log_warning "Failed to pull some images. Checking if images exist locally..."
        
        # Show actual error from log
        echo ""
        echo "Last 20 lines from log:"
        tail -20 "$LOG_FILE"
        echo ""
        
        # Check if critical images exist locally
        MISSING_IMAGES=0
        REQUIRED_IMAGES=(
            "nginx:1.25"
            "mysql:latest"
            "redis:7.2"
            "pandanxt/hospital-frontend:develop-235-0c0ff35d"
            "pandanxt/customer-portal:develop-78-24a5986b"
            "pandanxt/hms-backend-apis:develop-296-9bae757b"
        )
        
        for img in "${REQUIRED_IMAGES[@]}"; do
            img_name=$(echo $img | cut -d: -f1)
            if ! docker images | grep -q "$img_name"; then
                log_error "Critical image missing: $img"
                MISSING_IMAGES=1
            else
                log "✓ Found: $img_name"
            fi
        done
        
        if [ $MISSING_IMAGES -eq 1 ]; then
            log_error "Some critical images are missing. Cannot continue."
            exit 1
        fi
        
        log "✓ Required images found locally, continuing deployment..."
    fi

    echo ""
    log "Starting Docker containers..."
    log "This may take 5-10 minutes on first run (MySQL schema initialization)..."
    echo ""
    
    # Start containers with live output
    $DOCKER_COMPOSE_CMD up -d 2>&1 | tee -a "$LOG_FILE"
    
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        log "✓ Docker containers started"
    else
        log_error "Failed to start containers. Check log: $LOG_FILE"
        exit 1
    fi
    
    echo ""
    log "Waiting for services to fully initialize..."
    log "MySQL may take 2-3 minutes to create all database tables..."
    echo ""
    
    # Show progress with container status checks
    for i in {1..24}; do
        sleep 5
        RUNNING=$(docker compose ps --services --filter "status=running" 2>/dev/null | wc -l)
        echo -n "[$i/24] Containers running: $RUNNING/6  "
        
        # Check if MySQL is ready
        if docker exec hospital-mysql mysqladmin ping -h localhost --silent 2>/dev/null; then
            echo "✓ MySQL ready"
        else
            echo "⏳ Initializing..."
        fi
    done
    echo ""
    
    echo ""
    log "✓ Application deployment completed"
    
    # Show container status
    echo ""
    echo "Container Status:"
    echo "─────────────────────────────────────────"
    $DOCKER_COMPOSE_CMD ps
    echo "─────────────────────────────────────────"
}

################################################################################
# Phase 6: Verification
################################################################################

verify_deployment() {
    log "=========================================="
    log "Phase 6: Deployment Verification"
    log "=========================================="

    cd "$DEPLOYMENT_DIR"

    # Check container health
    log "Verifying container health..."
    
    CONTAINERS=("nginx-reverse-proxy" "api-hospital" "nxt-hospital" "portal-hospital" "hospital-mysql" "hospital-redis")
    
    for container in "${CONTAINERS[@]}"; do
        if docker ps --format "{{.Names}}" | grep -q "^${container}$"; then
            log "✓ $container is running"
        else
            log_error "$container is NOT running"
        fi
    done

    # Wait for MySQL to be fully ready
    log "Waiting for MySQL to be fully initialized..."
    max_attempts=30
    attempt=0
    while [ $attempt -lt $max_attempts ]; do
        if docker exec hospital-mysql mysqladmin ping -h localhost -u nxt_user -p$(grep "DB_PASSWORD=" hms-backend.env | cut -d'=' -f2) --silent 2>/dev/null; then
            log "✓ MySQL is ready"
            break
        fi
        attempt=$((attempt + 1))
        sleep 2
    done

    if [ $attempt -eq $max_attempts ]; then
        log_warning "MySQL health check timeout. It may still be initializing."
    fi

    # Test health endpoints
    log "Testing application endpoints..."
    
    sleep 5  # Give nginx a moment
    
    if curl -f -s http://localhost/nginx-health > /dev/null 2>&1; then
        log "✓ Nginx health check passed"
    else
        log_warning "Nginx health check failed"
    fi

    if curl -f -s http://localhost/api-server/health > /dev/null 2>&1; then
        log "✓ Backend API health check passed"
    else
        log_warning "Backend API health check failed (it may still be starting up)"
    fi

    # Verify database schema
    log "Verifying database schema..."
    DB_PASSWORD=$(grep "DB_PASSWORD=" hms-backend.env | cut -d'=' -f2)
    TABLE_COUNT=$(docker exec hospital-mysql mysql -u nxt_user -p"$DB_PASSWORD" nxt-hospital -se "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='nxt-hospital';" 2>/dev/null || echo "0")
    
    if [ "$TABLE_COUNT" -gt 50 ]; then
        log "✓ Database schema verified: $TABLE_COUNT tables"
    else
        log_warning "Database may still be initializing: $TABLE_COUNT tables found"
    fi

    log "✓ Verification completed"
}

################################################################################
# Phase 7: Production Hardening
################################################################################

production_hardening() {
    log "=========================================="
    log "Phase 7: Production Hardening"
    log "=========================================="

    cd "$DEPLOYMENT_DIR"

    # Create backup script
    log "Creating backup script..."
    sudo_wrapper mkdir -p /opt/hms-backups
    
    DB_PASSWORD=$(grep "DB_PASSWORD=" hms-backend.env | cut -d'=' -f2)
    
    sudo_wrapper tee /usr/local/bin/hms-backup.sh > /dev/null << EOFBACKUP
#!/bin/bash
BACKUP_DIR="/opt/hms-backups"
DATE=\$(date +%Y%m%d_%H%M%S)
CONTAINER="hospital-mysql"
DB_USER="nxt_user"
DB_PASS="$DB_PASSWORD"
DB_NAME="nxt-hospital"
PROJECT_DIR="$DEPLOYMENT_DIR"

mkdir -p "\$BACKUP_DIR"

# Backup database
docker exec \$CONTAINER mysqldump -u \$DB_USER -p\$DB_PASS \$DB_NAME | gzip > "\$BACKUP_DIR/db_\$DATE.sql.gz"

# Backup images folder
tar -czf "\$BACKUP_DIR/images_\$DATE.tar.gz" -C "\$PROJECT_DIR" images/

# Keep only last 7 days of backups
find "\$BACKUP_DIR" -type f -mtime +7 -delete

echo "\$(date): Backup completed: \$DATE" >> /var/log/hms-backup.log
EOFBACKUP

    sudo_wrapper chmod +x /usr/local/bin/hms-backup.sh
    log "✓ Backup script created and made executable"

    echo ""
    if prompt_yes_no "Setup automated backups and health checks (recommended)?"; then
        log "Configuring automated tasks..."
        
        # Add cron jobs (avoid duplicates)
        (crontab -l 2>/dev/null | grep -v "hms-backup.sh" | grep -v "hms-health-check.sh"; \
         echo "0 3 * * * /usr/local/bin/hms-backup.sh >> /var/log/hms-backup.log 2>&1"; \
         echo "*/5 * * * * /usr/local/bin/hms-health-check.sh") | crontab -
        
        log "✓ Automated tasks configured:"
        log "  • Daily database backups at 3:00 AM"
        log "  • Health checks every 5 minutes"
    else
        log "Skipping automated tasks"
    fi

    # SSL Setup
    echo ""
    if [ "$DOMAIN_OR_IP" != "$VM_IP" ]; then
        if prompt_yes_no "Setup HTTPS with Let's Encrypt SSL certificate?"; then
            setup_ssl
        else
            log_info "Skipping SSL setup"
            log_info "You can configure SSL later with: sudo certbot certonly --standalone -d yourdomain.com"
        fi
    else
        log_info "Skipping SSL setup (using IP address instead of domain)"
    fi

    # Create health check script
    log "Creating health check script..."
    sudo_wrapper tee /usr/local/bin/hms-health-check.sh > /dev/null << EOFHEALTH
#!/bin/bash
LOG_FILE="/var/log/hms-health.log"
PROJECT_DIR="$DEPLOYMENT_DIR"

cd "\$PROJECT_DIR" || exit 1

# Check container status
EXPECTED=6
RUNNING=\$(docker compose ps --services --filter "status=running" | wc -l)

if [ "\$RUNNING" -lt "\$EXPECTED" ]; then
    echo "\$(date): ALERT - Only \$RUNNING/\$EXPECTED containers running. Restarting..." >> "\$LOG_FILE"
    docker compose up -d >> "\$LOG_FILE" 2>&1
fi

# Check API health
if ! curl -f http://localhost/api-server/health > /dev/null 2>&1; then
    echo "\$(date): ALERT - API health check failed. Restarting backend..." >> "\$LOG_FILE"
    docker compose restart hospital-apis >> "\$LOG_FILE" 2>&1
fi
EOFHEALTH

    sudo_wrapper chmod +x /usr/local/bin/hms-health-check.sh
    log "✓ Health check script created and made executable"

    log "✓ Production hardening completed"
}

################################################################################
# SSL Setup
################################################################################

setup_ssl() {
    log "Setting up SSL certificate for Multi-Tenant System..."

    echo ""
    log_info "For multi-tenant HMS, you need a WILDCARD SSL certificate"
    log_info "This requires DNS validation (not HTTP validation)"
    echo ""
    
    read -p "Enter your BASE domain (e.g., hms.yourdomain.com): " SSL_DOMAIN

    if [ -z "$SSL_DOMAIN" ]; then
        log_warning "No domain provided. Skipping SSL setup."
        return
    fi

    echo ""
    log_info "Wildcard certificate will cover: $SSL_DOMAIN AND *.$SSL_DOMAIN"
    echo ""
    
    # Ask for DNS provider
    echo "Select your DNS provider:"
    echo "  1) Cloudflare (recommended)"
    echo "  2) Manual DNS (you'll add TXT records manually)"
    echo "  3) Skip wildcard - single domain only"
    read -p "Choice (1-3): " DNS_CHOICE

    case $DNS_CHOICE in
        1)
            # Cloudflare DNS challenge
            log "Setting up Cloudflare DNS challenge..."
            
            # Install certbot cloudflare plugin
            if ! dpkg -l | grep -q python3-certbot-dns-cloudflare; then
                log "Installing Cloudflare DNS plugin..."
                sudo_wrapper apt install -y python3-certbot-dns-cloudflare >> "$LOG_FILE" 2>&1
            fi
            
            echo ""
            log_info "You need Cloudflare API Token with Zone:DNS:Edit permissions"
            log_info "Get it from: https://dash.cloudflare.com/profile/api-tokens"
            echo ""
            read -p "Enter Cloudflare API Token: " CF_TOKEN
            
            if [ -z "$CF_TOKEN" ]; then
                log_error "API Token required for Cloudflare DNS challenge"
                SSL_SUCCESS=0
                return
            fi
            
            # Create credentials file
            sudo_wrapper mkdir -p /root/.secrets
            sudo_wrapper tee /root/.secrets/cloudflare.ini > /dev/null << EOF
dns_cloudflare_api_token = $CF_TOKEN
EOF
            sudo_wrapper chmod 600 /root/.secrets/cloudflare.ini
            
            # Request wildcard certificate
            log "Requesting wildcard SSL certificate from Let's Encrypt..."
            log "This may take 1-2 minutes for DNS propagation..."
            
            echo ""
            echo "═══════════════════════════════════════════════════════════════"
            echo "  Contacting Let's Encrypt..."
            echo "═══════════════════════════════════════════════════════════════"
            echo ""
            
            SSL_SUCCESS=0
            CERT_OUTPUT=$(mktemp)
            if sudo_wrapper certbot certonly \
                --dns-cloudflare \
                --dns-cloudflare-credentials /root/.secrets/cloudflare.ini \
                -d "$SSL_DOMAIN" \
                -d "*.$SSL_DOMAIN" \
                --non-interactive \
                --agree-tos \
                --email "$SSL_EMAIL" 2>&1 | tee "$CERT_OUTPUT"; then
                SSL_SUCCESS=1
                echo ""
                echo "═══════════════════════════════════════════════════════════════"
                echo "  ✅ SSL CERTIFICATE GENERATION SUCCESSFUL!"
                echo "═══════════════════════════════════════════════════════════════"
                log "✓ Wildcard SSL certificate generated successfully"
                log_info "Certificate covers: $SSL_DOMAIN and *.$SSL_DOMAIN"
                log_info "Stored in: /etc/letsencrypt/live/$SSL_DOMAIN/"
                echo ""
                cat "$CERT_OUTPUT" >> "$LOG_FILE"
            else
                SSL_SUCCESS=0
                echo ""
                echo "═══════════════════════════════════════════════════════════════"
                echo "  ❌ SSL CERTIFICATE GENERATION FAILED"
                echo "═══════════════════════════════════════════════════════════════"
                log_error "Certificate generation failed!"
                echo ""
                echo "Error details:"
                cat "$CERT_OUTPUT"
                echo ""
                echo "Full log: $LOG_FILE"
                echo ""
                cat "$CERT_OUTPUT" >> "$LOG_FILE"
                
                echo "Common issues:"
                echo "  1. Invalid Cloudflare API token (check permissions)"
                echo "  2. Domain not managed by Cloudflare"
                echo "  3. API token missing Zone:DNS:Edit permission"
                echo "  4. Rate limit reached (try again in 1 hour)"
                echo ""
                read -p "Press Enter to continue deployment without SSL..."
            fi
            rm -f "$CERT_OUTPUT"
            ;;
            
        2)
            # Manual DNS challenge
            log "Starting manual DNS challenge for wildcard certificate..."
            
            # Install certbot if not present
            if ! command -v certbot &> /dev/null; then
                log "Installing certbot..."
                sudo_wrapper apt install -y certbot >> "$LOG_FILE" 2>&1
            fi
            
            echo ""
            echo "═══════════════════════════════════════════════════════════════"
            echo "  IMPORTANT: Manual DNS Challenge Instructions"
            echo "═══════════════════════════════════════════════════════════════"
            echo ""
            echo "Certbot will show you TWO TXT records that you need to add to"
            echo "your DNS provider (Hoster.pk cPanel)."
            echo ""
            echo "For each TXT record:"
            echo "  1. DON'T press Enter when certbot shows the record"
            echo "  2. Login to Hoster.pk cPanel → Zone Editor"
            echo "  3. Add TXT record:"
            echo "     Name:   _acme-challenge.hms"
            echo "     Type:   TXT"
            echo "     Record: [value shown by certbot]"
            echo "     TTL:    300"
            echo "  4. Verify with: dig _acme-challenge.$SSL_DOMAIN TXT +short"
            echo "  5. Only then press Enter in certbot"
            echo ""
            echo "You'll need to add TWO records (same name, different values)"
            echo ""
            echo "═══════════════════════════════════════════════════════════════"
            echo ""
            read -p "Press Enter when ready to start certificate request..."
            
            log_info "Starting certificate request. Follow the prompts carefully."
            echo ""
            
            # Run certbot in interactive mode
            SSL_SUCCESS=0
            if sudo_wrapper certbot certonly \
                --manual \
                --preferred-challenges dns \
                -d "$SSL_DOMAIN" \
                -d "*.$SSL_DOMAIN" \
                --agree-tos \
                --email "$SSL_EMAIL"; then
                
                # Verify certificate was actually created
                if [ -d "/etc/letsencrypt/live/$SSL_DOMAIN" ]; then
                    SSL_SUCCESS=1
                    echo ""
                    echo "═══════════════════════════════════════════════════════════════"
                    echo "  ✅ SSL CERTIFICATE GENERATION SUCCESSFUL!"
                    echo "═══════════════════════════════════════════════════════════════"
                    log "✓ Wildcard SSL certificate generated successfully"
                    log_info "Certificate covers: $SSL_DOMAIN and *.$SSL_DOMAIN"
                    log_info "Stored in: /etc/letsencrypt/live/$SSL_DOMAIN/"
                    echo ""
                    echo "Certificate files:"
                    sudo_wrapper ls -lh /etc/letsencrypt/live/$SSL_DOMAIN/
                    echo ""
                else
                    SSL_SUCCESS=0
                    log_error "Certificate directory not found after certbot completion"
                fi
            else
                SSL_SUCCESS=0
                echo ""
                echo "═══════════════════════════════════════════════════════════════"
                echo "  ❌ SSL CERTIFICATE GENERATION FAILED"
                echo "═══════════════════════════════════════════════════════════════"
                log_error "Manual DNS challenge failed or was cancelled"
                echo ""
                read -p "Press Enter to continue deployment without SSL..."
            fi
            ;;
            
        3)
            # HTTP challenge - single domain only
            log "Setting up HTTP challenge for single domain (no wildcard)..."
            
            # Install certbot if not present
            if ! command -v certbot &> /dev/null; then
                log "Installing certbot..."
                sudo_wrapper apt install -y certbot >> "$LOG_FILE" 2>&1
            fi
            
            # Stop nginx for standalone challenge
            log "Stopping nginx temporarily..."
            $DOCKER_COMPOSE_CMD stop nginx-reverse-proxy 2>/dev/null || true
            
            echo ""
            echo "═══════════════════════════════════════════════════════════════"
            echo "  Requesting SSL certificate..."
            echo "═══════════════════════════════════════════════════════════════"
            echo ""
            
            SSL_SUCCESS=0
            CERT_OUTPUT=$(mktemp)
            if sudo_wrapper certbot certonly \
                --standalone \
                -d "$SSL_DOMAIN" \
                --non-interactive \
                --agree-tos \
                --email "$SSL_EMAIL" 2>&1 | tee "$CERT_OUTPUT"; then
                
                if [ -d "/etc/letsencrypt/live/$SSL_DOMAIN" ]; then
                    SSL_SUCCESS=1
                    echo ""
                    echo "═══════════════════════════════════════════════════════════════"
                    echo "  ✅ SSL CERTIFICATE GENERATION SUCCESSFUL!"
                    echo "═══════════════════════════════════════════════════════════════"
                    log "✓ SSL certificate generated for $SSL_DOMAIN"
                    log_warning "Note: This does NOT cover subdomains (*.domain)"
                    log_warning "For multi-tenant support, you need wildcard certificate"
                    echo ""
                else
                    SSL_SUCCESS=0
                    log_error "Certificate directory not found"
                fi
                cat "$CERT_OUTPUT" >> "$LOG_FILE"
            else
                SSL_SUCCESS=0
                echo ""
                echo "═══════════════════════════════════════════════════════════════"
                echo "  ❌ SSL CERTIFICATE GENERATION FAILED"
                echo "═══════════════════════════════════════════════════════════════"
                log_error "SSL certificate generation failed"
                echo ""
                echo "Error details:"
                cat "$CERT_OUTPUT"
                echo ""
                cat "$CERT_OUTPUT" >> "$LOG_FILE"
                echo ""
                read -p "Press Enter to continue deployment without SSL..."
            fi
            rm -f "$CERT_OUTPUT"
            
            # Start nginx again
            $DOCKER_COMPOSE_CMD start nginx-reverse-proxy 2>/dev/null || true
            ;;
            
        *)
            log_warning "Invalid choice. Skipping SSL setup."
            SSL_SUCCESS=0
            return
            ;;
    esac
    
    # Only show next steps and setup renewal if certificate was successful
    if [ $SSL_SUCCESS -eq 1 ]; then
        echo ""
        echo "═══════════════════════════════════════════════════════════════"
        echo "  ✅ SSL Certificate Successfully Generated!"
        echo "═══════════════════════════════════════════════════════════════"
        echo ""
        log_info "Next steps to enable HTTPS:"
        log_info "1. Create nginx HTTPS configuration file"
        log_info "2. Update docker-compose.yml to mount SSL certificates"
        log_info "3. Restart nginx: docker compose restart nginx"
        echo ""
        
        # Setup auto-renewal for Let's Encrypt
        log "Setting up SSL certificate auto-renewal..."
        
        # Add certbot renewal to crontab (runs twice daily)
        CRON_CMD="0 0,12 * * * certbot renew --quiet --post-hook 'docker compose -f $DEPLOYMENT_DIR/docker-compose.yml restart nginx-reverse-proxy' >> /var/log/certbot-renewal.log 2>&1"
        (crontab -l 2>/dev/null | grep -v "certbot renew"; echo "$CRON_CMD") | crontab -
        
        log "✓ SSL auto-renewal configured (checks twice daily)"
        log_info "Renewal logs: /var/log/certbot-renewal.log"
        
        echo ""
        log_info "To complete HTTPS setup after deployment, run these commands:"
        echo ""
        echo "  # Create HTTPS nginx config"
        echo "  nano ~/nxt-hospital-skeleton-project/nginx/conf.d/reverse-proxy-https.conf"
        echo ""
        echo "  # Update docker-compose.yml"
        echo "  # Add this line under nginx volumes:"
        echo "  #   - /etc/letsencrypt:/etc/letsencrypt:ro"
        echo ""
        echo "  # Restart nginx"
        echo "  docker compose restart nginx"
        echo ""
    else
        echo ""
        log_warning "SSL certificate was not generated. You can set it up manually later."
        log_info "Manual setup command:"
        log_info "  certbot certonly --manual --preferred-challenges dns -d $SSL_DOMAIN -d *.$SSL_DOMAIN"
        echo ""
    fi
    
    log "✓ SSL setup completed"
}

################################################################################
# Deployment Summary
################################################################################

deployment_summary() {
    clear
    
    echo ""
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║                                                          ║"
    echo "║      🎉 HMS DEPLOYMENT COMPLETED SUCCESSFULLY! 🎉       ║"
    echo "║                                                          ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo ""
    echo "┌──────────────────────────────────────────────────────────┐"
    echo "│  📱 ACCESS YOUR APPLICATION                              │"
    echo "└──────────────────────────────────────────────────────────┘"
    echo ""
    echo "  🌐 Admin Panel:     http://$DOMAIN_OR_IP/"
    echo "  👤 Patient Portal:  http://$DOMAIN_OR_IP/portal/"
    echo "  💚 API Health:      http://$DOMAIN_OR_IP/api-server/health"
    echo ""
    echo "┌──────────────────────────────────────────────────────────┐"
    echo "│  📋 IMPORTANT INFORMATION                                │"
    echo "└──────────────────────────────────────────────────────────┘"
    echo ""
    echo "  📁 Project Directory:  $DEPLOYMENT_DIR"
    echo "  🔑 Credentials File:   $HOME/.hms_credentials_*.txt"
    echo "  📝 Deployment Log:     $LOG_FILE"
    echo ""
    echo "┌──────────────────────────────────────────────────────────┐"
    echo "│  🏢 MULTI-TENANT ARCHITECTURE                            │"
    echo "└──────────────────────────────────────────────────────────┘"
    echo ""
    echo "  This deployment supports UNLIMITED hospital tenants:"
    echo ""
    echo "  🌐 DNS Setup:"
    echo "     • Main domain:    $DOMAIN_OR_IP"
    echo "     • Wildcard:       *.$DOMAIN_OR_IP (all subdomains)"
    echo ""
    echo "  🏥 Tenant Access Pattern:"
    echo "     • hospital-a.$DOMAIN_OR_IP → Tenant A"
    echo "     • hospital-b.$DOMAIN_OR_IP → Tenant B"
    echo "     • clinic-xyz.$DOMAIN_OR_IP → Tenant XYZ"
    echo ""
    echo "  📂 File Storage:"
    echo "     • Tenant-isolated: $DEPLOYMENT_DIR/images/<tenant_id>/"
    echo "     • Auto-served via: http://$DOMAIN_OR_IP/images/<tenant_id>/"
    echo ""
    echo "  🔒 Security:"
    echo "     • JWT-based authentication"
    echo "     • Tenant ID in every DB query"
    echo "     • Isolated file storage per tenant"
    echo ""
    echo "┌──────────────────────────────────────────────────────────┐"
    echo "│  🔧 USEFUL COMMANDS                                      │"
    echo "└──────────────────────────────────────────────────────────┘"
    echo ""
    echo "  View logs:       docker compose logs -f"
    echo "  Restart all:     docker compose restart"
    echo "  Stop:            docker compose down"
    echo "  Start:           docker compose up -d"
    echo "  Backup now:      sudo /usr/local/bin/hms-backup.sh"
    echo ""
    echo "┌──────────────────────────────────────────────────────────┐"
    echo "│  📚 NEXT STEPS                                           │"
    echo "└──────────────────────────────────────────────────────────┘"
    echo ""
    echo "  1. Open browser: http://$DOMAIN_OR_IP/"
    echo "  2. Create first admin user in default tenant"
    echo "  3. Add hospitals: See docs/TENANT_ONBOARDING.md"
    echo "  4. Configure DNS: See docs/MULTI_TENANT_DNS_SETUP.md"
    echo "  5. Enable HTTPS: Update nginx config with SSL certificates"
    echo "  6. Test tenant: http://hospital-name.$DOMAIN_OR_IP/"
    echo ""
    echo "┌──────────────────────────────────────────────────────────┐"
    echo "│  📖 DOCUMENTATION                                        │"
    echo "└──────────────────────────────────────────────────────────┘"
    echo ""
    echo "  • docs/PRODUCTION_DEPLOYMENT.md     - Production setup guide"
    echo "  • docs/TENANT_ONBOARDING.md         - Add new hospitals (SQL)"
    echo "  • docs/MULTI_TENANT_DNS_SETUP.md    - Wildcard DNS config"
    echo "  • README.md                         - Architecture overview"
    echo "  • .github/copilot-instructions.md   - Developer guide"
    echo ""
    echo "══════════════════════════════════════════════════════════════"
    echo ""
    
    log "Deployment completed successfully at $(date)"
    log "Log file: $LOG_FILE"
}

################################################################################
# Main Function
################################################################################

main() {
    clear
    echo ""
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║                                                          ║"
    echo "║        🏥 NXT HMS - Production Deployment 🏥             ║"
    echo "║         Automated Multi-Tenant Setup v2.0                ║"
    echo "║                                                          ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo ""
    echo "This script will deploy your HMS application automatically."
    echo ""
    echo "What it does:"
    echo "  ✓ Load deployment configuration (domain, tenant, integrations)"
    echo "  ✓ Verify system requirements (Docker, ports, disk space)"
    echo "  ✓ Install required system packages"
    echo "  ✓ Configure firewall (UFW)"
    echo "  ✓ Setup production environment with multi-tenancy"
    echo "  ✓ Deploy all Docker containers"
    echo "  ✓ Setup automated backups"
    echo "  ✓ Configure health monitoring"
    echo ""
    echo "⏱️  Estimated time: 10-15 minutes"
    echo "📝 Log file: $LOG_FILE"
    echo ""
    echo "══════════════════════════════════════════════════════════════"
    echo ""

    if ! prompt_yes_no "Ready to begin deployment?"; then
        echo ""
        echo "Deployment cancelled. You can run this script again anytime."
        echo ""
        echo "💡 TIP: Create deployment-config.local.sh for automated deployments"
        echo "   cp deployment-config.sh deployment-config.local.sh"
        echo "   nano deployment-config.local.sh"
        exit 0
    fi

    clear
    log "🚀 Starting HMS deployment at $(date)"
    echo ""
    
    # Load configuration first
    load_deployment_config "$@"
    echo ""

    # Execute deployment phases
    preflight_checks
    echo ""
    
    system_setup
    echo ""
    
    setup_directories
    echo ""
    
    configure_environment
    echo ""
    
    deploy_application
    echo ""
    
    verify_deployment
    echo ""
    
    production_hardening
    echo ""
    
    deployment_summary

    log "✅ All deployment phases completed successfully"
}

################################################################################
# Script Entry Point
################################################################################

# Run main function with all command line arguments
main "$@"
