#!/bin/bash
################################################################################
# NXT HOSPITAL - Deployment Configuration File
# 
# This file contains deployment-specific settings that can be customized
# for different environments without modifying the main deploy.sh script.
#
# Usage:
#   1. Copy this file: cp deployment-config.sh deployment-config.local.sh
#   2. Edit deployment-config.local.sh with your settings
#   3. Run: ./deploy.sh (it will auto-detect the local config)
#
# Note: deployment-config.local.sh is git-ignored for security
################################################################################

# ============================================================================
# DEPLOYMENT CONFIGURATION
# ============================================================================

# Domain Configuration
# Example: hms.yourdomain.com, hospital.example.com, medeast.healthcare.com
# Leave empty to use VM IP address (auto-detected)
DEPLOYMENT_DOMAIN="hms.nxtwebmasters.com"

# Base Subdomain / Default Tenant Name
# This becomes the system default tenant identifier
# Examples: "hms", "medeast", "familycare", "careplus"
# For hms.yourdomain.com → use "hms"
# For medeast.healthcare.com → use "medeast"
DEFAULT_TENANT_SUBDOMAIN="hms"

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

# Preset 1: Generic HMS (recommended starting point)
# DEPLOYMENT_DOMAIN="hms.yourdomain.com"
# DEFAULT_TENANT_SUBDOMAIN="hms"
# DEPLOYMENT_MODE="https"

# Preset 2: Specific Hospital (e.g., MedEast)
# DEPLOYMENT_DOMAIN="medeast.healthcare.com"
# DEFAULT_TENANT_SUBDOMAIN="medeast"
# DEPLOYMENT_MODE="https"

# Preset 3: Development (IP-based, no domain)
# DEPLOYMENT_DOMAIN=""  # Will auto-detect VM IP
# DEFAULT_TENANT_SUBDOMAIN="hms"
# DEPLOYMENT_MODE="http"

# Preset 4: Multi-branch Hospital Group
# DEPLOYMENT_DOMAIN="familycare.nxtwebmasters.com"
# DEFAULT_TENANT_SUBDOMAIN="familycare"
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
