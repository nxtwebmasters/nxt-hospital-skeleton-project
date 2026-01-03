#!/bin/bash

################################################################################
# NXT HMS - Automated Production Deployment Script
# For Ubuntu 20.04+ / Debian-based systems
# 
# Prerequisites: Docker, Docker Compose installed
# Usage: 
#   1. Clone this repository
#   2. cd into repository directory
#   3. Run: ./deploy.sh
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
        log_error "Please do not run this script as root. Run as regular user with sudo privileges."
        exit 1
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
    if sudo netstat -tlnp 2>/dev/null | grep -E ':80 |:443 ' > /dev/null; then
        log_warning "Ports 80 or 443 are already in use"
        if prompt_yes_no "Attempt to stop conflicting services (apache2/nginx)?"; then
            sudo systemctl stop apache2 2>/dev/null || true
            sudo systemctl disable apache2 2>/dev/null || true
            sudo systemctl stop nginx 2>/dev/null || true
            sudo systemctl disable nginx 2>/dev/null || true
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
    sudo apt update >> "$LOG_FILE" 2>&1

    # Install essential utilities
    log "Installing essential utilities..."
    sudo apt install -y curl wget nano htop net-tools ufw openssl >> "$LOG_FILE" 2>&1

    # Configure firewall
    if prompt_yes_no "Configure UFW firewall (allow SSH, HTTP, HTTPS)?"; then
        log "Configuring firewall..."
        sudo ufw allow 22/tcp >> "$LOG_FILE" 2>&1
        sudo ufw allow 80/tcp >> "$LOG_FILE" 2>&1
        sudo ufw allow 443/tcp >> "$LOG_FILE" 2>&1
        echo "y" | sudo ufw enable >> "$LOG_FILE" 2>&1
        log "✓ Firewall configured"
    fi

    # Configure Docker permissions
    log "Configuring Docker permissions..."
    if ! groups | grep -q docker; then
        sudo usermod -aG docker "$USER"
        log_warning "Docker group added. You may need to log out and back in for this to take effect."
        log "Attempting to continue with newgrp docker..."
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

    clear
    echo ""
    echo "=========================================="
    echo "  Production Configuration Setup"
    echo "=========================================="
    echo ""
    echo "Please provide the following information:"
    echo ""

    # Get VM IP automatically
    VM_IP=$(curl -s -4 ifconfig.me 2>/dev/null || echo "localhost")
    
    # Domain or IP
    echo "─────────────────────────────────────────"
    echo "1. Domain/IP Address Configuration"
    echo "─────────────────────────────────────────"
    echo "Your VM IP: $VM_IP"
    read -p "Enter your domain name (or press Enter to use VM IP): " USER_DOMAIN
    
    if [ -z "$USER_DOMAIN" ]; then
        DOMAIN_OR_IP="$VM_IP"
        log "Using VM IP: $DOMAIN_OR_IP"
    else
        DOMAIN_OR_IP="$USER_DOMAIN"
        log "Using domain: $DOMAIN_OR_IP"
    fi
    
    echo ""
    
    # Email Configuration
    echo "─────────────────────────────────────────"
    echo "2. Email Configuration (for notifications)"
    echo "─────────────────────────────────────────"
    read -p "SMTP Email (e.g., admin@yourdomain.com): " SMTP_EMAIL
    
    if [ -z "$SMTP_EMAIL" ]; then
        log_warning "No email provided. Email notifications will be disabled."
        SMTP_EMAIL="noreply@example.com"
        SMTP_PASSWORD="disabled"
        ADMIN_EMAILS='"admin@example.com"'
    else
        read -p "SMTP Password/App Key: " -s SMTP_PASSWORD
        echo ""
        read -p "Admin Email Recipients (comma-separated, e.g., admin@domain.com,support@domain.com): " ADMIN_EMAILS_INPUT
        
        if [ -z "$ADMIN_EMAILS_INPUT" ]; then
            ADMIN_EMAILS="\"$SMTP_EMAIL\""
        else
            # Convert comma-separated to JSON array format
            ADMIN_EMAILS=$(echo "$ADMIN_EMAILS_INPUT" | awk -F',' '{for(i=1;i<=NF;i++){printf "\"%s\"%s", $i, (i<NF?",":"")}}')
        fi
    fi
    
    echo ""
    
    # Generate secure passwords
    echo "─────────────────────────────────────────"
    echo "3. Security Configuration"
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
    echo "4. Optional Integrations (can configure later)"
    echo "─────────────────────────────────────────"
    
    if prompt_yes_no "Enable WhatsApp integration now?"; then
        read -p "WhatsApp API Key: " WHATSAPP_API_KEY
        ENABLE_WHATSAPP="true"
    else
        WHATSAPP_API_KEY=""
        ENABLE_WHATSAPP="false"
    fi
    
    if prompt_yes_no "Enable OpenAI integration now?"; then
        read -p "OpenAI API Key: " OPENAI_API_KEY
    else
        OPENAI_API_KEY=""
    fi
    
    echo ""

    # Update hms-backend.env
    log "Updating hms-backend.env..."
    
    cat > hms-backend.env << EOF
# Server Configuration
PORT=80
LOG_LEVEL=info

# Database Configuration (MySQL)
DB_HOST=mysql
SOURCE_DB_NAME=nxt-hospital
DB_USERNAME=nxt_user
DB_PASSWORD=$MYSQL_DB_PASSWORD
DB_CONNECTION_LIMIT=10
DB_MULTIPLE_STATEMENTS=true

# FBR Integration Configuration
FBR_INTEGRATION_ENABLED=false
FBR_API_URL_PRODUCTION=https://api.fbr.gov.pk/v1/pos/invoice
FBR_API_URL_SANDBOX=https://api.fbr.gov.pk/v1/pos/sandbox/invoice
FBR_TIMEOUT_MS=30000
FBR_RETRY_ATTEMPTS=3

# Email Configuration
EMAIL_USER=$SMTP_EMAIL
EMAIL_PASSWORD=$SMTP_PASSWORD
EMAIL_IMAGE_PATH=https://$DOMAIN_OR_IP/images/logo.png
EMAIL_RECIPIENTS=[$ADMIN_EMAILS]

# JWT Configuration
JWT_SECRET=$JWT_SECRET

# File Storage Configuration
IMAGE_STORAGE_PATH=/usr/share/nginx/html/images
FILE_SERVER_URL=/images

# Webhook Configuration
WEBHOOK_URL=

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
PATIENT_DEFAULT_PASSWORD=NxtHospital123

# WhatsApp Configuration
ENABLE_WHATSAPP=$ENABLE_WHATSAPP
MSGPK_WHATSAPP_API_URL=https://msgpk.com/api/send.php
MSGPK_WHATSAPP_API_KEY=$WHATSAPP_API_KEY
MSGPK_WHATSAPP_GROUP_API_URL=https://msgpk.com/apps/check_group.php
MSGPK_WHATSAPP_CHECK_API_URL=https://msgpk.com/api/whatsapp_numbers.php
WHATSAPP_MAX_RETRIES=3
WHATSAPP_RETRY_DELAY_MS=1000
WHATSAPP_RATE_LIMIT_DELAY_MS=100
WHATSAPP_IMAGE_URL=

# Reception Share Configuration
RECEPTION_SHARE={"ENABLED":true,"PERCENTAGE":1.25}

# OpenAI Configuration
OPENAI_API_KEY=$OPENAI_API_KEY
OPENAI_MODEL=gpt-4-turbo
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
    
    # Update docker-compose.yml with passwords
    log "Updating docker-compose.yml..."
    sed -i "s/MYSQL_ROOT_PASSWORD: \".*\"/MYSQL_ROOT_PASSWORD: \"$MYSQL_ROOT_PASSWORD\"/" docker-compose.yml
    sed -i "s/MYSQL_PASSWORD: \".*\"/MYSQL_PASSWORD: \"$MYSQL_DB_PASSWORD\"/" docker-compose.yml
    
    # Save credentials to a secure file
    CREDS_FILE="$HOME/.hms_credentials_$(date +%Y%m%d).txt"
    cat > "$CREDS_FILE" << EOF
═══════════════════════════════════════
HMS Production Credentials
Generated: $(date)
═══════════════════════════════════════

MySQL Root Password: $MYSQL_ROOT_PASSWORD
MySQL DB Password:   $MYSQL_DB_PASSWORD
JWT Secret:          $JWT_SECRET

Domain/IP:           $DOMAIN_OR_IP
SMTP Email:          $SMTP_EMAIL

Access URLs:
  Admin Panel:       http://$DOMAIN_OR_IP/
  Patient Portal:    http://$DOMAIN_OR_IP/portal/
  API Health:        http://$DOMAIN_OR_IP/api-server/health

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
    
    if $DOCKER_COMPOSE_CMD pull >> "$LOG_FILE" 2>&1; then
        log "✓ Docker images pulled successfully"
    else
        log_error "Failed to pull Docker images. Check your internet connection."
        exit 1
    fi

    echo ""
    log "Starting Docker containers..."
    $DOCKER_COMPOSE_CMD up -d >> "$LOG_FILE" 2>&1
    
    echo ""
    log "Waiting for services to initialize..."
    echo "This may take up to 60 seconds..."
    
    # Show a progress indicator
    for i in {1..12}; do
        echo -n "."
        sleep 5
    done
    echo ""
    
    echo ""
    log "✓ Application deployment completed"
    
    # Show container status
    echo ""
    echo "Container Status:"
    echo "─────────────────────────────────────────"
    $DOCKER_COMPOSE_CMD ps
    echo "─────────────────────────────────────────
    # Pull Docker images
    log "Pulling Docker images (this may take several minutes)..."
    $DOCKER_COMPOSE_CMD pull >> "$LOG_FILE" 2>&1
    log "✓ Docker images pulled successfully"

    # Start the stack
    log "Starting Docker stack..."
    $DOCKER_COMPOSE_CMD up -d >> "$LOG_FILE" 2>&1
    
    log "Waiting for services to initialize (60 seconds)..."
    sleep 60

    # Check container status
    log "Checking container status..."
    $DOCKER_COMPOSE_CMD ps

    log "✓ Application deployment completed"
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
    sudo mkdir -p /opt/hms-backups
    
    DB_PASSWORD=$(grep "DB_PASSWORD=" hms-backend.env | cut -d'=' -f2)
    
    sudo tee /usr/local/bin/hms-backup.sh > /dev/null << 'EOFBACKUP'
#!/bin/bash
BACKUP_DIR="/opt/hms-backups"
DATE=$(date +%Y%m%d_%H%M%S)
CONTAINER="hospital-mysql"
DB_USER="nxt_user"
DB_PASS="DB_PASSWORD_PLACEHOLDER"
DB_NAME="nxt-hospital"
PROJECT_DIR="/opt/nxt-hospital-skeleton-project"

mkdir -p "$BACKUP_DIR"

# Backup database
docker exec $CONTAINER mysqldump -u $DB_USER -p$DB_PASS $DB_NAME | gzip > "$BACKUP_DIR/db_$DATE.sql.gz"

# Backup images folder
tar -czf "$BACKUP_DIR/images_$DATE.tar.gz" -C "$PROJECT_DIR" images/

# Keep only last 7 days of backups
find "$BACKUP_DIR" -type f -mtime +7 -delete

echo "$(date): Backup completed: $DATE" >> /var/log/hms-backup.log
EOFBACKUP

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
        log_info "Skipping SSL setup (using IP address instead of domain)
    echo "$(date): ALERT - Only $RUNNING/$EXPECTED containers running. Restarting..." >> "$LOG_FILE"
    docker compose up -d >> "$LOG_FILE" 2>&1
fi

# Check API health
if ! curl -f http://localhost/api-server/health > /dev/null 2>&1; then
    echo "$(date): ALERT - API health check failed. Restarting backend..." >> "$LOG_FILE"
    docker compose restart hospital-apis >> "$LOG_FILE" 2>&1
fi
EOFHEALTH

    sudo chmod +x /usr/local/bin/hms-health-check.sh
    log "✓ Health check script created at /usr/local/bin/hms-health-check.sh"

    # Setup cron jobs
    if prompt_yes_no "Setup automated backups and health checks (cron jobs)?"; then
        log "Configuring cron jobs..."
        
        # Add cron jobs (avoid duplicates)
        (crontab -l 2>/dev/null | grep -v "hms-backup.sh" | grep -v "hms-health-check.sh"; \
         echo "0 3 * * * /usr/local/bin/hms-backup.sh >> /var/log/hms-backup.log 2>&1"; \
         echo "*/5 * * * * /usr/local/bin/hms-health-check.sh") | crontab -
        
        log "✓ Cron jobs configured:"
        log "  - Daily backups at 3 AM"
        log "  - Health checks every 5 minutes"
    fi

    # SSL Setup
    if prompt_yes_no "Setup HTTPS with Let's Encrypt SSL certificate?"; then
        setup_ssl
    else
        log_info "Skipping SSL setup. You can run 'sudo certbot certonly --standalone -d yourdomain.com' later"
    fi

    log "✓ Production hardening completed"
}

################################################################################
# SSL Setup
################################################################################

setup_ssl() {
    log "Setting up SSL certificate..."

    # Install certbot if not present
    if ! command -v certbot &> /dev/null; then
        log "Installing certbot..."
        sudo apt install -y certbot >> "$LOG_FILE" 2>&1
    fi

    echo ""
    log_info "Enter your domain name for SSL certificate:"
    read -p "Domain (e.g., hms.yourhospital.com): " SSL_DOMAIN

    if [ -z "$SSL_DOMAIN" ]; then
        log_warning "No domain provided. Skipping SSL setup."
        return
    fi

    # Stop nginx temporarily for certbot standalone
    log "Stopping nginx temporarily for certificate generation..."
    $DOCKER_COMPOSE_CMD stop nginx
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
    echo "  1. Open browser and access: http://$DOMAIN_OR_IP/"
    echo "  2. Create your first admin user"
    echo "  3. Add your first tenant (see docs/TENANT_ONBOARDING.md)"
    echo "  4. Configure integrations if needed (FBR, WhatsApp, etc.)"
    echo ""
    echo "┌──────────────────────────────────────────────────────────┐"
    echo "│  📖 DOCUMENTATION                                        │"
    echo "└──────────────────────────────────────────────────────────┘"
    echo ""
    echo "  • docs/PRODUCTION_DEPLOYMENT.md  - Production guide"
    echo "  • docs/TENANT_ONBOARDING.md      - Add new hospitals"
    echo "  • README.md                      - Architecture overview"
    echo ""
    echo "══════════════════════════════════════════════════════════════"
    echo ""
    
    log "Deployment completed successfully at $(date)"
    log "Log file: $LOG_FILE"
    
    echo ""
    echo "⚠️  Remember to:"
    echo "   • Save your credentials from: $HOME/.hms_credentials_*.txt"
    echo "   • Delete the credentials file after saving"
    echo "   • Change default passwords on first login"
    echo "
    echo "  HMS DEPLOYMENT COMPLETED SUCCESSFULLY!"
    echo "=========================================="
    echo ""
    echo "Access URLs:"
    echo "  Admin Panel:    http://$DOMAIN_OR_IP/"
    echo "  Patient Portal: http://$DOMAIN_OR_IP/portal/"
    echo "  API Health:     http://$DOMAIN_OR_IP/api-server/health"
    echo ""
    echo "Container Status:"
    $DOCKER_COMPOSE_CMD ps
    echo ""
    echo ""
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║                                                          ║"
    echo "║        🏥 NXT HMS - Production Deployment 🏥             ║"
    echo "║              Automated Setup Script v2.0                 ║"
    echo "║                                                          ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo ""
    echo "This script will deploy your HMS application automatically."
    echo ""
    echo "What it does:"
    echo "  ✓ Verify system requirements (Docker, ports, disk space)"
    echo "  ✓ Install required system packages"
    echo "  ✓ Configure firewall (UFW)"
    echo "  ✓ Setup production environment"
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
        exit 0
    fi

    clear
    log "🚀 Starting HMS deployment at $(date)"
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

    log "✅ 
main() {
    clear
    echo "=========================================="
    echo "  NXT HMS - Production Deployment"
    echo "  Automated Setup Script v1.0"
    echo "=========================================="
    echo ""
    echo "This script will:"
    echo "  1. Verify system requirements"
    echo "  2. Install dependencies"
    echo "  3. Configure firewall"
    echo "  4. Clone/setup repository"
    echo "  5. Configure environment"
    echo "  6. Deploy application"
    echo "  7. Setup backups and monitoring"
    echo ""
    echo "Estimated time: 10-15 minutes"
    echo "Log file: $LOG_FILE"
    echo ""

    if ! prompt_yes_no "Ready to begin deployment?"; then
        echo "Deployment cancelled."
        exit 0
    fi

    echo ""
    log "Starting deployment at $(date)"

    # Execute deployment phases
    preflight_checks
    system_setup
    repository_setup
    configure_environment
    deploy_application
    verify_deployment
    production_hardening
    deployment_summary

    log "Deployment script completed successfully!"
}

# Run main function
main
