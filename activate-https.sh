#!/bin/bash
################################################################################
# Activate HTTPS Configuration for NXT HMS
# 
# This script switches from HTTP-only mode to HTTPS mode by:
# 1. Updating the HTTPS config with the correct domain
# 2. Disabling HTTP-only config
# 3. Enabling HTTPS config
# 4. Restarting nginx
#
# Usage: ./activate-https.sh <domain>
# Example: ./activate-https.sh nxthms.nxtwebmasters.com
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log() { echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }

# Check if domain argument provided
if [ -z "$1" ]; then
    error "Usage: $0 <domain>"
    error "Example: $0 nxthms.nxtwebmasters.com"
fi

DOMAIN="$1"
NGINX_CONF_DIR="nginx/conf.d"
HTTP_CONFIG="$NGINX_CONF_DIR/reverse-proxy-http.conf"
HTTPS_CONFIG_TEMPLATE="$NGINX_CONF_DIR/reverse-proxy-https.conf"
HTTPS_CONFIG_DISABLED="$NGINX_CONF_DIR/reverse-proxy-https.conf.disabled"
HTTPS_CONFIG_ACTIVE="$NGINX_CONF_DIR/reverse-proxy-https.conf"

log "🔒 Activating HTTPS for domain: $DOMAIN"
echo "=========================================="

# Step 1: Verify SSL certificate exists
log "Step 1: Verifying SSL certificate..."
if [ ! -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
    error "SSL certificate not found at /etc/letsencrypt/live/$DOMAIN/fullchain.pem"
fi
if [ ! -f "/etc/letsencrypt/live/$DOMAIN/privkey.pem" ]; then
    error "Private key not found at /etc/letsencrypt/live/$DOMAIN/privkey.pem"
fi
log "✓ SSL certificates verified"

# Step 2: Determine which config file to use
log "Step 2: Preparing HTTPS configuration..."

if [ -f "$HTTPS_CONFIG_DISABLED" ]; then
    SOURCE_CONFIG="$HTTPS_CONFIG_DISABLED"
    log "Using disabled config: $HTTPS_CONFIG_DISABLED"
elif [ -f "$HTTPS_CONFIG_TEMPLATE" ]; then
    SOURCE_CONFIG="$HTTPS_CONFIG_TEMPLATE"
    log "Using template config: $HTTPS_CONFIG_TEMPLATE"
else
    error "HTTPS config file not found!"
fi

# Step 3: Create working copy and update domain placeholders
log "Step 3: Updating domain in HTTPS configuration..."

# Create backup of current config
if [ -f "$HTTPS_CONFIG_ACTIVE" ]; then
    cp "$HTTPS_CONFIG_ACTIVE" "$HTTPS_CONFIG_ACTIVE.backup.$(date +%Y%m%d_%H%M%S)"
    log "✓ Backed up existing HTTPS config"
fi

# Copy source to active location
cp "$SOURCE_CONFIG" "$HTTPS_CONFIG_ACTIVE"

# Replace YOURDOMAIN.COM with actual domain
sed -i "s/YOURDOMAIN\.COM/$DOMAIN/g" "$HTTPS_CONFIG_ACTIVE"
log "✓ Updated domain placeholders to: $DOMAIN"

# Step 4: Disable HTTP-only config
log "Step 4: Disabling HTTP-only configuration..."
if [ -f "$HTTP_CONFIG" ]; then
    mv "$HTTP_CONFIG" "$HTTP_CONFIG.disabled"
    log "✓ Disabled: $HTTP_CONFIG"
fi

# Step 5: Verify nginx configuration
log "Step 5: Testing nginx configuration..."
docker compose exec -T nginx nginx -t || error "Nginx configuration test failed!"
log "✓ Nginx configuration is valid"

# Step 6: Restart nginx
log "Step 6: Restarting nginx..."
docker compose restart nginx
sleep 5
log "✓ Nginx restarted"

# Step 7: Verify HTTPS is working
log "Step 7: Verifying HTTPS access..."
sleep 2

if curl -k -s -f "https://$DOMAIN/nginx-health" > /dev/null 2>&1; then
    log "✓ HTTPS is working! Testing endpoint: https://$DOMAIN/nginx-health"
else
    warn "HTTPS health check failed - nginx may still be starting"
    info "Wait a few seconds and test manually:"
    info "  curl https://$DOMAIN/nginx-health"
fi

# Success message
echo "=========================================="
log "✅ HTTPS activated successfully!"
echo ""
info "Access URLs:"
info "  Admin UI:      https://$DOMAIN/"
info "  Patient Portal: https://$DOMAIN/portal/"
info "  API Health:    https://$DOMAIN/api-server/health"
echo ""
info "Multi-tenant URLs (after creating tenants):"
info "  Tenant 1: https://hospital1-${DOMAIN#*.}/"
info "  Tenant 2: https://hospital2-${DOMAIN#*.}/"
echo ""
info "To check nginx logs: docker logs -f nginx-reverse-proxy"
info "To test SSL: openssl s_client -connect $DOMAIN:443 -servername $DOMAIN"
