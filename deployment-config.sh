#!/bin/bash
################################################################################
# NXT Health Suite — Deployment Configuration File
#
# Domain architecture:
#   nxthealthsuite.com            → marketing website (separate host)
#   app.nxthealthsuite.com        → HMS application (this deployment)
#   city.app.nxthealthsuite.com   → per-tenant wildcard subdomains
#
# Usage:
#   1. Copy this file: cp deployment-config.sh deployment-config.local.sh
#   2. Edit deployment-config.local.sh with your settings
#   3. Run: ./deploy.sh  (auto-detects the local config)
#
# Note: deployment-config.local.sh is git-ignored for security
################################################################################

# ============================================================================
# DEPLOYMENT CONFIGURATION
# ============================================================================

# App sub-domain where the HMS software is served.
# The marketing site (nxthealthsuite.com) is hosted separately.
# Wildcard DNS record *.app.nxthealthsuite.com must A-point to this server.
DEPLOYMENT_DOMAIN="app.nxthealthsuite.com"

# Base Subdomain / Default Tenant Name
# This is the system default tenant identifier.
# For app.nxthealthsuite.com  →  use "app"
# New tenants are then:  city.app.nxthealthsuite.com (tenant = "city")
DEFAULT_TENANT_SUBDOMAIN="app"

# Deployment Mode
# Options: "http" (development/testing), "https" (production with SSL)
# ⚠️ PRODUCTION: Always use "https" for security!
DEPLOYMENT_MODE="https"

# ============================================================================
# OPTIONAL: PRE-CONFIGURED CREDENTIALS (for automated deployments)
# ============================================================================
# Leave empty to be prompted during deployment

# Email Configuration (REMOVED - now per-tenant via database)
# Email settings are now configured per-tenant via:
# Admin Panel → System → Tenant Configuration → Email Settings
# SMTP_EMAIL=""  # Not used - configure per tenant
# ADMIN_EMAILS=""  # For SSL cert notifications only (optional)

# MySQL Configuration (auto-generated if empty)
MYSQL_ROOT_PASSWORD=""
MYSQL_DB_PASSWORD=""

# JWT Secret (auto-generated if empty)
JWT_SECRET=""

# ============================================================================
# INTEGRATION CONFIGURATION (optional - can configure later via UI)
# ============================================================================
# NOTE: Most integrations are now configured per-tenant via Admin Panel.
# These settings are kept for backward compatibility but will be ignored
# in favor of database configurations.

# ====================================================================================
# TENANT-SPECIFIC CONFIGURATIONS REMOVED
# ====================================================================================
# These are now configured per-tenant via:
# Admin Panel → System → Tenant Configuration
# 
# Each tenant configures their own:
# - Email (SMTP credentials, settings)
# - WhatsApp (API credentials, retry settings)
# - OpenAI (API key, model settings)
# - Webhooks (notification URLs)
# - Business Rules (leave balance, reception share, etc.)
# - Schedulers (cron expressions)
# - Locale (timezone, currency, formats)
# - FBR Tax Integration (POS ID, API token, environment)
# ====================================================================================

# NOTE: FBR_INTEGRATION_ENABLED removed - now per-tenant configuration
# Configure FBR per tenant via: Admin Panel → FBR Management

# ============================================================================
# ADVANCED CONFIGURATION
# ============================================================================

# Docker Image Tags (use 'latest' or specific versions like 'develop-329-2250faf4')
BACKEND_IMAGE_TAG="latest"
FRONTEND_IMAGE_TAG="latest"
PORTAL_IMAGE_TAG="latest"

# ============================================================================
# DEPLOYMENT PRESETS (uncomment and customize one to use)
# ============================================================================

# Preset 1: NXT Health Suite SaaS (production — recommended)
# DEPLOYMENT_DOMAIN="app.nxthealthsuite.com"
# DEFAULT_TENANT_SUBDOMAIN="app"
# DEPLOYMENT_MODE="https"
# Tenant pattern: lahore.app.nxthealthsuite.com, karachi.app.nxthealthsuite.com

# Preset 2: White-label / custom domain for a hospital group
# DEPLOYMENT_DOMAIN="app.medeast.pk"
# DEFAULT_TENANT_SUBDOMAIN="app"
# DEPLOYMENT_MODE="https"
# Tenant pattern: lahore.app.medeast.pk, karachi.app.medeast.pk

# Preset 3: Development (IP-based, no domain)
# DEPLOYMENT_DOMAIN=""  # Will auto-detect VM IP
# DEFAULT_TENANT_SUBDOMAIN="app"
# DEPLOYMENT_MODE="http"

# Preset 4: Single-hospital deployment (no multi-tenancy needed)
# DEPLOYMENT_DOMAIN="hms.cityhospital.pk"
# DEFAULT_TENANT_SUBDOMAIN="hms"
# DEPLOYMENT_MODE="https"
# 
# NOTE: After deployment, configure tenant-specific settings via:
# Admin Panel → System → Tenant Configuration
# - Email Settings (SMTP credentials)
# - WhatsApp Settings (API credentials)
# - OpenAI Settings (API key)
# - Locale Settings (timezone, currency)

# ============================================================================
# VALIDATION (do not modify)
# ============================================================================

validate_config() {
    local errors=0
    
    # Validate tenant subdomain
    if [ -z "$DEFAULT_TENANT_SUBDOMAIN" ]; then
        echo "ERROR: DEFAULT_TENANT_SUBDOMAIN cannot be empty"
        errors=$((errors + 1))
    fi
    
    # Validate deployment mode
    if [ "$DEPLOYMENT_MODE" != "http" ] && [ "$DEPLOYMENT_MODE" != "https" ]; then
        echo "ERROR: DEPLOYMENT_MODE must be 'http' or 'https'"
        errors=$((errors + 1))
    fi
    
    # Warn if HTTPS without domain
    if [ "$DEPLOYMENT_MODE" = "https" ] && [ -z "$DEPLOYMENT_DOMAIN" ]; then
        echo "WARNING: HTTPS mode requires a domain name. SSL certificates cannot be issued for IP addresses."
        echo "         Either set DEPLOYMENT_DOMAIN or change DEPLOYMENT_MODE to 'http'"
        errors=$((errors + 1))
    fi
    
    return $errors
}
