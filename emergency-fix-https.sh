#!/bin/bash
################################################################################
# EMERGENCY FIX: Nginx HTTPS Configuration
# 
# This script fixes the nginx restart loop caused by placeholder domain
# in the HTTPS configuration file.
#
# Issue: Nginx is trying to load HTTPS config with YOURDOMAIN.COM placeholder
# Fix: Updates the config with actual domain and restarts nginx
#
# Usage: ./emergency-fix-https.sh
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; exit 1; }
info() { echo -e "${BLUE}ℹ${NC} $1"; }

echo "=========================================="
echo "  🚨 EMERGENCY FIX: Nginx HTTPS Config"
echo "=========================================="
echo ""

# Load deployment config to get domain
if [ -f "deployment-config.local.sh" ]; then
    source deployment-config.local.sh
elif [ -f "deployment-config.sh" ]; then
    source deployment-config.sh
else
    error "No configuration file found!"
fi

DOMAIN="${DEPLOYMENT_DOMAIN}"

if [ -z "$DOMAIN" ]; then
    error "No domain configured in deployment-config.sh"
fi

info "Domain from config: $DOMAIN"
info "Tenant: $DEFAULT_TENANT_SUBDOMAIN"
echo ""

# Check if SSL certificate exists
log "Step 1: Verifying SSL certificate exists..."
if [ ! -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
    error "SSL certificate not found at /etc/letsencrypt/live/$DOMAIN/"
fi
log "SSL certificate verified"
echo ""

# Stop nginx container to avoid file locking
log "Step 2: Stopping nginx container..."
docker compose stop nginx 2>/dev/null || docker stop nginx-reverse-proxy 2>/dev/null || true
log "Nginx stopped"
echo ""

# Check current nginx config status
log "Step 3: Checking nginx configuration files..."
HTTP_CONFIG="nginx/conf.d/reverse-proxy-http.conf"
HTTPS_CONFIG="nginx/conf.d/reverse-proxy-https.conf"
HTTPS_DISABLED="nginx/conf.d/reverse-proxy-https.conf.disabled"

if [ -f "$HTTPS_CONFIG" ]; then
    if grep -q "YOURDOMAIN.COM" "$HTTPS_CONFIG" 2>/dev/null; then
        warn "HTTPS config exists but has placeholder - will update"
        HAS_PLACEHOLDER=1
    else
        log "HTTPS config already configured"
        HAS_PLACEHOLDER=0
    fi
elif [ -f "$HTTPS_DISABLED" ]; then
    info "HTTPS config is disabled - will enable and configure"
    HAS_PLACEHOLDER=1
else
    error "No HTTPS config found (neither active nor disabled)"
fi
echo ""

# Fix the configuration
log "Step 4: Configuring HTTPS..."

if [ $HAS_PLACEHOLDER -eq 1 ]; then
    # Source config (either active with placeholder or disabled)
    if [ -f "$HTTPS_CONFIG" ]; then
        SOURCE="$HTTPS_CONFIG"
    else
        SOURCE="$HTTPS_DISABLED"
    fi
    
    # Create temporary file with updated domain
    TEMP_CONFIG=$(mktemp)
    sed "s/YOURDOMAIN\.COM/$DOMAIN/g" "$SOURCE" > "$TEMP_CONFIG"
    
    # Replace active config
    mv "$TEMP_CONFIG" "$HTTPS_CONFIG"
    log "Updated HTTPS config with domain: $DOMAIN"
    
    # Disable HTTP-only config
    if [ -f "$HTTP_CONFIG" ]; then
        mv "$HTTP_CONFIG" "$HTTP_CONFIG.disabled"
        log "Disabled HTTP-only config"
    fi
else
    log "HTTPS config already up to date"
fi
echo ""

# Verify nginx configuration syntax
log "Step 5: Testing nginx configuration..."
if docker run --rm -v "$(pwd)/nginx/nginx.conf:/etc/nginx/nginx.conf:ro" \
    -v "$(pwd)/nginx/conf.d:/etc/nginx/conf.d:ro" \
    -v "/etc/letsencrypt:/etc/letsencrypt:ro" \
    nginx:1.25 nginx -t 2>&1 | grep -q "successful"; then
    log "Nginx configuration is valid"
else
    error "Nginx configuration test failed!"
fi
echo ""

# Start nginx container
log "Step 6: Starting nginx container..."
docker compose start nginx || docker start nginx-reverse-proxy
sleep 3
log "Nginx started"
echo ""

# Verify nginx is running
log "Step 7: Verifying nginx is running..."
if docker ps | grep -q "nginx-reverse-proxy"; then
    STATUS=$(docker ps --format "{{.Status}}" --filter "name=nginx-reverse-proxy")
    if echo "$STATUS" | grep -q "Up"; then
        log "Nginx is running: $STATUS"
    else
        warn "Nginx status: $STATUS"
        info "Check logs: docker logs nginx-reverse-proxy"
    fi
else
    error "Nginx container not found or not running"
fi
echo ""

# Test HTTPS endpoint
log "Step 8: Testing HTTPS endpoint..."
sleep 2

if curl -k -s -f "https://$DOMAIN/nginx-health" > /dev/null 2>&1; then
    log "HTTPS is working!"
    info "URL: https://$DOMAIN/nginx-health"
elif curl -k -s -f "https://localhost/nginx-health" > /dev/null 2>&1; then
    log "HTTPS is working on localhost"
    warn "Domain $DOMAIN may need DNS configuration"
else
    warn "HTTPS health check failed - nginx may still be starting"
    info "Wait 10 seconds and test manually:"
    info "  curl -k https://$DOMAIN/nginx-health"
    info "  curl -k https://localhost/nginx-health"
fi
echo ""

# Success
echo "=========================================="
log "✅ FIX APPLIED SUCCESSFULLY!"
echo ""
info "Access URLs:"
info "  Admin UI:       https://$DOMAIN/"
info "  Patient Portal: https://$DOMAIN/portal/"
info "  API Health:     https://$DOMAIN/api-server/health"
echo ""
info "If domain doesn't work, try localhost:"
info "  https://$(hostname -I | awk '{print $1}')/"
echo ""
info "Check nginx logs: docker logs -f nginx-reverse-proxy"
echo "=========================================="
