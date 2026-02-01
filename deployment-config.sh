#!/bin/bash
################################################################################
# NXT HMS - Deployment Configuration File
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
DEPLOYMENT_DOMAIN=""

# Base Subdomain / Default Tenant Name
# This becomes the system default tenant identifier
# Examples: "hms", "medeast", "familycare", "careplus"
# For hms.yourdomain.com → use "hms"
# For medeast.healthcare.com → use "medeast"
DEFAULT_TENANT_SUBDOMAIN="hms"

# Deployment Mode
# Options: "http" (development/testing), "https" (production with SSL)
DEPLOYMENT_MODE="http"

# ============================================================================
# OPTIONAL: PRE-CONFIGURED CREDENTIALS (for automated deployments)
# ============================================================================
# Leave empty to be prompted during deployment

# Email Configuration (for notifications)
SMTP_EMAIL=""
SMTP_PASSWORD=""
ADMIN_EMAILS=""

# MySQL Configuration (auto-generated if empty)
MYSQL_ROOT_PASSWORD=""
MYSQL_DB_PASSWORD=""

# JWT Secret (auto-generated if empty)
JWT_SECRET=""

# ============================================================================
# INTEGRATION CONFIGURATION (optional - can configure later via UI)
# ============================================================================

# WhatsApp Integration
ENABLE_WHATSAPP="false"
MSGPK_WHATSAPP_API_KEY=""
WHATSAPP_IMAGE_URL=""

# OpenAI Integration
OPENAI_API_KEY=""
OPENAI_MODEL="gpt-4-turbo"

# FBR Tax Integration (Pakistan)
FBR_INTEGRATION_ENABLED="false"

# Google Chat Webhook (for system notifications)
WEBHOOK_URL=""

# ============================================================================
# ADVANCED CONFIGURATION
# ============================================================================

# Docker Image Tags (use 'latest' or specific versions like 'develop-329-2250faf4')
BACKEND_IMAGE_TAG="latest"
FRONTEND_IMAGE_TAG="latest"
PORTAL_IMAGE_TAG="latest"

# Reception Share Configuration
RECEPTION_SHARE_ENABLED="true"
RECEPTION_SHARE_PERCENTAGE="1.25"

# Patient Portal Configuration
PATIENT_DEFAULT_PASSWORD="NxtHospital123"

# ============================================================================
# DEPLOYMENT PRESETS (uncomment and customize one to use)
# ============================================================================

# Preset 1: Generic HMS (recommended starting point)
# DEPLOYMENT_DOMAIN="hms.yourdomain.com"
# DEFAULT_TENANT_SUBDOMAIN="hms"
# DEPLOYMENT_MODE="https"
# SMTP_EMAIL="noreply@yourdomain.com"
# ADMIN_EMAILS="admin@yourdomain.com"

# Preset 2: Specific Hospital (e.g., MedEast)
# DEPLOYMENT_DOMAIN="medeast.healthcare.com"
# DEFAULT_TENANT_SUBDOMAIN="medeast"
# DEPLOYMENT_MODE="https"
# SMTP_EMAIL="noreply@medeast.healthcare.com"
# ADMIN_EMAILS="admin@medeast.healthcare.com"

# Preset 3: Development (IP-based, no domain)
# DEPLOYMENT_DOMAIN=""  # Will auto-detect VM IP
# DEFAULT_TENANT_SUBDOMAIN="hms"
# DEPLOYMENT_MODE="http"
# SMTP_EMAIL="test@example.com"
# ADMIN_EMAILS="dev@example.com"

# Preset 4: Multi-branch Hospital Group (e.g., FamilyCare)
# DEPLOYMENT_DOMAIN="familycare.nxtwebmasters.com"
# DEFAULT_TENANT_SUBDOMAIN="familycare"
# DEPLOYMENT_MODE="https"
# SMTP_EMAIL="noreply@familycare.nxtwebmasters.com"
# ADMIN_EMAILS="admin@familycare.com,operations@familycare.com"
# ENABLE_WHATSAPP="true"
# MSGPK_WHATSAPP_API_KEY="your-api-key-here"

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
