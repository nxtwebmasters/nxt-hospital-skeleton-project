#!/bin/bash
################################################################################
# Post-Deployment Status Check
# 
# Checks the current state after deployment and provides next steps
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
error() { echo -e "${RED}✗${NC} $1"; }
info() { echo -e "${BLUE}ℹ${NC} $1"; }

echo "=========================================="
echo "  NXT HMS - Post-Deployment Status Check"
echo "=========================================="
echo ""

# Load deployment config
if [ -f "deployment-config.local.sh" ]; then
    source deployment-config.local.sh
    CONFIG_FILE="deployment-config.local.sh"
elif [ -f "deployment-config.sh" ]; then
    source deployment-config.sh
    CONFIG_FILE="deployment-config.sh"
else
    error "No configuration file found!"
    exit 1
fi

info "Configuration: $CONFIG_FILE"
info "Domain: ${DEPLOYMENT_DOMAIN:-<IP-based>}"
info "Tenant: $DEFAULT_TENANT_SUBDOMAIN"
info "Mode: $DEPLOYMENT_MODE"
echo ""

# Check containers
echo "Container Status:"
echo "----------------"
ALL_RUNNING=true
for container in nginx-reverse-proxy api-hospital nxt-hospital portal-hospital hospital-mysql hospital-redis; do
    if docker ps --filter "name=$container" --filter "status=running" | grep -q "$container"; then
        log "$container is running"
    else
        error "$container is NOT running"
        ALL_RUNNING=false
    fi
done
echo ""

# Check SSL certificate
echo "SSL Certificate Status:"
echo "----------------------"
if [ ! -z "$DEPLOYMENT_DOMAIN" ] && [ "$DEPLOYMENT_MODE" = "https" ]; then
    if [ -f "/etc/letsencrypt/live/$DEPLOYMENT_DOMAIN/fullchain.pem" ]; then
        log "SSL certificate exists for: $DEPLOYMENT_DOMAIN"
        CERT_EXPIRY=$(openssl x509 -enddate -noout -in "/etc/letsencrypt/live/$DEPLOYMENT_DOMAIN/fullchain.pem" | cut -d= -f2)
        info "Expires: $CERT_EXPIRY"
    else
        error "SSL certificate NOT found at: /etc/letsencrypt/live/$DEPLOYMENT_DOMAIN/"
    fi
else
    info "HTTP mode - no SSL certificate needed"
fi
echo ""

# Check nginx configuration
echo "Nginx Configuration:"
echo "-------------------"
if [ -f "nginx/conf.d/reverse-proxy-http.conf" ]; then
    warn "HTTP-only config is ACTIVE"
    info "File: nginx/conf.d/reverse-proxy-http.conf"
fi

if [ -f "nginx/conf.d/reverse-proxy-https.conf" ]; then
    log "HTTPS config is ACTIVE"
    
    # Check if it still has placeholder
    if grep -q "YOURDOMAIN.COM" nginx/conf.d/reverse-proxy-https.conf 2>/dev/null; then
        warn "HTTPS config has placeholder YOURDOMAIN.COM (not configured yet)"
    else
        CONFIGURED_DOMAIN=$(grep "server_name" nginx/conf.d/reverse-proxy-https.conf | head -1 | awk '{print $2}' | tr -d ';')
        log "HTTPS configured for: $CONFIGURED_DOMAIN"
    fi
fi

if [ -f "nginx/conf.d/reverse-proxy-https.conf.disabled" ]; then
    warn "HTTPS config is DISABLED"
    info "File: nginx/conf.d/reverse-proxy-https.conf.disabled"
fi
echo ""

# Test endpoints
echo "Endpoint Health Checks:"
echo "----------------------"

# Detect access URL
if [ ! -z "$DEPLOYMENT_DOMAIN" ]; then
    BASE_URL="http://$DEPLOYMENT_DOMAIN"
    HTTPS_URL="https://$DEPLOYMENT_DOMAIN"
else
    VM_IP=$(hostname -I | awk '{print $1}')
    BASE_URL="http://$VM_IP"
    HTTPS_URL="N/A"
fi

# Test nginx health
if curl -s -f "$BASE_URL/nginx-health" > /dev/null 2>&1; then
    log "Nginx health: $BASE_URL/nginx-health"
elif [ "$DEPLOYMENT_MODE" = "https" ] && [ "$HTTPS_URL" != "N/A" ]; then
    if curl -k -s -f "$HTTPS_URL/nginx-health" > /dev/null 2>&1; then
        log "Nginx health (HTTPS): $HTTPS_URL/nginx-health"
    else
        error "Nginx health check failed (both HTTP and HTTPS)"
    fi
else
    error "Nginx health check failed: $BASE_URL/nginx-health"
fi

# Test API health
if curl -s -f "$BASE_URL/api-server/health" > /dev/null 2>&1; then
    log "API health: $BASE_URL/api-server/health"
elif [ "$DEPLOYMENT_MODE" = "https" ] && [ "$HTTPS_URL" != "N/A" ]; then
    if curl -k -s -f "$HTTPS_URL/api-server/health" > /dev/null 2>&1; then
        log "API health (HTTPS): $HTTPS_URL/api-server/health"
    else
        warn "API health check failed (may still be bootstrapping)"
        info "Check logs: docker logs -f api-hospital"
    fi
else
    warn "API health check failed (may still be bootstrapping)"
    info "Check logs: docker logs -f api-hospital"
fi
echo ""

# Provide next steps
echo "=========================================="
echo "  Next Steps"
echo "=========================================="
echo ""

if [ "$DEPLOYMENT_MODE" = "https" ]; then
    if [ -f "nginx/conf.d/reverse-proxy-http.conf" ] && [ ! -f "nginx/conf.d/reverse-proxy-https.conf" ]; then
        warn "HTTPS mode configured but HTTPS nginx config not activated!"
        echo ""
        info "To activate HTTPS, run:"
        echo "  chmod +x activate-https.sh"
        echo "  ./activate-https.sh $DEPLOYMENT_DOMAIN"
        echo ""
    elif [ -f "nginx/conf.d/reverse-proxy-https.conf" ]; then
        if grep -q "YOURDOMAIN.COM" nginx/conf.d/reverse-proxy-https.conf 2>/dev/null; then
            warn "HTTPS config exists but still has placeholder!"
            echo ""
            info "To activate HTTPS, run:"
            echo "  chmod +x activate-https.sh"
            echo "  ./activate-https.sh $DEPLOYMENT_DOMAIN"
            echo ""
        else
            log "HTTPS is properly configured!"
            echo ""
            info "Access URLs:"
            echo "  Admin UI:      https://$DEPLOYMENT_DOMAIN/"
            echo "  Patient Portal: https://$DEPLOYMENT_DOMAIN/portal/"
            echo "  API:           https://$DEPLOYMENT_DOMAIN/api-server/health"
            echo ""
        fi
    fi
else
    log "HTTP mode - deployment ready for testing"
    echo ""
    info "Access URLs:"
    if [ ! -z "$DEPLOYMENT_DOMAIN" ]; then
        echo "  Admin UI:      http://$DEPLOYMENT_DOMAIN/"
        echo "  Patient Portal: http://$DEPLOYMENT_DOMAIN/portal/"
        echo "  API:           http://$DEPLOYMENT_DOMAIN/api-server/health"
    else
        echo "  Admin UI:      http://$VM_IP/"
        echo "  Patient Portal: http://$VM_IP/portal/"
        echo "  API:           http://$VM_IP/api-server/health"
    fi
    echo ""
fi

# Check if API is still bootstrapping
if ! curl -s -f "$BASE_URL/api-server/health" > /dev/null 2>&1; then
    info "If API health check fails, it may still be bootstrapping..."
    info "Bootstrap process can take 30-60 seconds on first deployment"
    info "Monitor with: docker logs -f api-hospital"
    echo ""
fi

# Database credentials
echo "Database Credentials:"
echo "--------------------"
CREDS_FILE=$(ls -t ~/.hms_credentials_*.txt 2>/dev/null | head -1)
if [ -f "$CREDS_FILE" ]; then
    log "Credentials saved in: $CREDS_FILE"
    info "View with: cat $CREDS_FILE"
else
    warn "Credentials file not found in home directory"
fi
echo ""

# Useful commands
echo "Useful Commands:"
echo "---------------"
info "View all containers: docker compose ps"
info "View API logs: docker logs -f api-hospital"
info "View nginx logs: docker logs -f nginx-reverse-proxy"
info "Restart nginx: docker compose restart nginx"
info "Check database: docker exec -it hospital-mysql mysql -u root -p"
echo ""

echo "=========================================="
