# Generic Deployment Guide

Complete guide for deploying NXT HMS to any domain/tenant with automated configuration.

---

## Quick Start (5 Minutes)

### Standard Deployment

```bash
# 1. Copy the configuration template
cp deployment-config.sh deployment-config.local.sh

# 2. Edit your settings
nano deployment-config.local.sh

# 3. Set these two critical values:
DEPLOYMENT_DOMAIN="yourdomain.com"          # Your domain (or leave empty for IP)
DEFAULT_TENANT_SUBDOMAIN="yourname"         # Your tenant identifier

# 4. Deploy everything automatically
./deploy.sh
```

### Using Presets

```bash
# 1. Copy template
cp deployment-config.sh deployment-config.local.sh

# 2. Uncomment your desired preset in the file
nano deployment-config.local.sh
# Uncomment one of: Generic HMS, Specific Hospital, Development, or Multi-branch

# 3. Deploy
./deploy.sh
```

---

## Configuration Overview

The `deployment-config.sh` file is a template with generic defaults and preset examples.

### Critical Settings

```bash
# 1. Domain Name
DEPLOYMENT_DOMAIN=""
# - Your domain name (e.g., "hms.yourdomain.com")
# - Leave empty "" to auto-detect VM IP address
# - Examples:
#   "hms.hospital.com"           → Production with domain
#   "medeast.healthcare.com"     → Specific hospital
#   ""                           → Development (uses VM IP)

# 2. Default Tenant Subdomain
DEFAULT_TENANT_SUBDOMAIN="hms"
# - System default tenant identifier (stored as 'system_default_tenant' in DB)
# - Becomes BASE_SUBDOMAIN in backend configuration
# - Examples:
#   For hms.yourdomain.com → "hms"
#   For medeast.healthcare.com → "medeast"
#   For familycare.nxtwebmasters.com → "familycare"

# 3. Deployment Mode
DEPLOYMENT_MODE="http"
# - "http"  = Development/testing (no SSL)
# - "https" = Production (requires domain + SSL certificates)
```

### How Multi-Tenancy Works
Multi-Tenancy Model

Your configuration creates this tenant structure:

**Example Configuration:**
```bash
DEPLOYMENT_DOMAIN="hms.yourdomain.com"
DEFAULT_TENANT_SUBDOMAIN="hms"
```

**Results in:**
1. **Default Tenant**: Database record `system_default_tenant` with subdomain `hms`
2. **Access URL**: `hms.yourdomain.com` (maps to default tenant)
3. **Additional Tenants**: 
   - `hospital1-Generic HMS (Preset 1)

**Use Case**: Standard hospital management system

```bash
# deployment-config.local.sh
DEPLOYMENT_DOMAIN="hms.yourdomain.com"
DEFAULT_TENANT_SUBDOMAIN="hms"
DEPLOYMENT_MODE="https"
SMTP_EMAIL="noreply@yourdomain.com"
ADMIN_EMAILS="admin@yourdomain.com"
```

**Result**:
- Default tenant: `hms` (system_default_tenant)
- Access URL: `https://hms.yourdomain.com`
- Multi-tenant URLs: `hospital1-hms.yourdomain.com`, etc.
- Database: `tenant_subdomain='hms'`

### Scenario 2: Specific Hospital (Preset 2)

**Use Case**: Dedicated deployment for specific hospital brand

```bash
# deployment-config.local.sh
DEPLOYMENT_DOMAIN="medeast.healthcare.com"
DEFAULT_TENANT_SUBDOMAIN="medeast"
DEPLOYMENT_MODE="https"
SMTP_EMAIL="noreply@medeast.healthcare.com"
ADMIN_EMAILS="admin@medeast.healthcare.com"
```

**Result**:
- Default tenant: `medeast`
- Access URL: `https://medeast.healthcare.com`
- Multi-tenant URLs: `branch1-medeast.healthcare.com`, etc.

### Scenario 3: Development (Preset 3)

**Use Case**: Local testing, staging environment

```bash
# deployment-config.local.sh
DEPLOYMENT_DOMAIN=""  # Empty = auto-detect VM IP
DEFAULT_TENANT_SUBDOMAIN="hms"
DEPLOYMENT_MODE="http"
SMTP_EMAIL="test@example.com"
ADMIN_EMAILS="dev@example.com"
```

**Result**:
- Default tenant: `hms`
- Access URL: `http://192.168.1.100` (auto-detected)
- No SSL required
- Multi-tenants require hosts file or DNS

### Scenario 4: Multi-Branch Hospital Group (Preset 4)

**Use Case**: Hospital chain with multiple locations

```bash
# deployment-config.local.sh
DEPLOYMENT_DOMAIN="familycare.nxtwebmasters.com"
DEFAULT_TENANT_SUBDOMAIN="familycare"
DEPLOYMENT_MODE="https"
SMTP_EMAIL="noreply@familycare.nxtwebmasters.com"
ADMIN_EMAILS="admin@familycare.com,operations@familycare.com"
ENABLE_WHATSAPP="true"
MSGPK_WHATSAPP_API_KEY="your-api-key"
```

**Result**:
- Default tenant: `familycare`
- Access URL: `https://familycare.nxtwebmasters.com`
- Branch URLs: `north-familycare.nxtwebmasters.com`, `south-familycare.nxtwebmasters.com`
- WhatsApp integration enabled
# deployment-config.local.sh
DEPLOYMENT_DOMAIN="medeast.nxtwebmasters.com"
DEFAULT_TENANT_SUBDOMAIN="medeast"
DEPLOYMENT_MODE="https"
```

Result:
- Default tenant: `medeast`
- Access URL: `https://medeast.nxtwebmasters.com`
- Other tenants: `branch1-medeast.nxtwebmasters.com`, etc.

---

## Configuration Workflow

### Option 1: Automated Deployment (Recommended)
Automated

When you run `./deploy.sh`, the script automatically:

### 1. Environment Configuration
**File**: `hms-backend.env` (auto-generated from template)
- `BASE_SUBDOMAIN` ← `DEFAULT_TENANT_SUBDOMAIN`
- `DB_PASSWORD` ← Auto-generated (24-char secure)
- `JWT_SECRET` ← Auto-generated (32-byte hex)
- `MYSQL_ROOT_PASSWORD` ← Auto-generated
- All integration settings from config

### 2. Database Schema
**File**: `data/scripts/1-schema.sql` (placeholder replacement)
- `{{DEFAULT_TENANT_SUBDOMAIN}}` → Your actual subdomain
- Default tenant record created with correct subdomain
- Example: `'familycare'` → `'hms'` or `'medeast'`

### 3. Docker Compose
**File**: `docker-compose.yml` (password sync)
- MySQL root password matched with backend
- MySQL user password matched with backend
- Ensures connection consistency

### 4. Nginx Configuration
**Auto-selected based on `DEPLOYMENT_MODE`:**
- HTTP mode → `nginx/conf.d/reverse-proxy-http.conf`
- HTTPS mode → `nginx/conf.d/reverse-proxy-https.conf`

### 5. Credentials File
**Location**: `~/.hms_credentials_YYYYMMDD.txt`
```Managing Multiple Environments

### Environment-Specific Config Files

Create separate config files for different environments:

```bash
# Production
deployment-config.production.sh
  DEPLOYMENT_DOMAIN="hms.yourdomain.com"
  DEFAULT_TENANT_SUBDOMAIN="hms"
  DEPLOYMENT_MODE="https"

# Staging
deployment-config.staging.sh
  DEPLOYMENT_DOMAIN="staging.yourdomain.com"
  DEFAULT_TENANT_SUBDOMAIN="hms-staging"
  DEPLOYMENT_MODE="https"

# Development
deployment-config.dev.sh
  DEPLOYMENT_DOMAIN=""
  DEFAULT_TENANT_SUBDOMAIN="hms-dev"
  DEPLOYMENT_MODE="http"
```

### Deploy to Specific Environment

```bash
# Production deployment
./deploy.sh --config deployment-config.production.sh

# Staging deployment
./deploy.sh --config deployment-config.staging.sh

# Development deployment
./deploy.sh --config deployment-config.dev.sh
DNS Configuration

### Wildcard DNS (Required for Multi-Tenant)

Configure these records in your DNS provider (Cloudflare, Route53, etc.):

```dns
# For hms.yourdomain.com deployment
Type: A
Name: hms
Value: <your-server-ip>

Type: A  
Name: *.hms
Value: <your-server-ip>
```

**Result**: All subdomains automatically resolve
- `hms.yourdomain.com` ✅
- `hospital1-hms.yourdomain.com` ✅
- `citycare-hms.yourdomain.com` ✅

### Testing DNS Resolution

```bash
# Test main domain
nslookup hms.yourdomain.com

# Test wildcard
nslookup hospital1-hms.yourdomain.com

# Verify propagation (masubdomain in database

**Symptom**: Default tenant has incorrect subdomain value

**Solution**: Clean redeploy
```bash
# Stop and remove all data
docker-compose down -v

# Fix configuration
nano deployment-config.local.sh
# Set correct DEFAULT_TENANT_SUBDOMAIN

# Redeploy
./deploy.sh
```

### Issue: Tenant not found errors

**Symptom**: API returns "Tenant not found" for valid domain

**Cause**: `BASE_SUBDOMAIN` mismatch

**Solution**: Verify configuration
```bash
# Check backend environment
cat hms-backend.env | grep BASE_SUBDOMAIN

# Check database tenant
docker exec -it hospital-mysql mysql -u root -p
> USE `nxt-hospital`;
> SELECT tenant_subdomain FROM nxt_tenant WHERE tenant_id='system_default_tenant';

# SAdvanced Topics

### Creating New Tenants

**Via API**:
```bash
curl -X POST https://hms.yourdomain.com/api-server/tenant/create \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <admin-token>" \
  -d '{
    "tenant_name": "City Care Hospital",
    "tenant_subdomain": "citycare-hms",
    "subscription_plan": "premium"
  }'
```

**Result**:
- Database record created
- File directory created: `images/citycare-hms/`
- Access URL: `https://citycare-hms.yourdomain.com`

### Tenant Isolation Verification

```bash
# Check tenant data isolation
docker exec -it hospital-mysql mysql -u root -p
> USE `nxt-hospital`;
> SELECT * FROM nxt_tenant;
### Configuration Management

1. **Never commit sensitive configs**
   - `deployment-config.local.sh` is git-ignored
   - Store production configs in secure location (vault, password manager)
   - Use environment-specific config files

2. **Use presets for consistency**
   ```bash
   # Copy template
   cp deployment-config.sh deployment-config.local.sh
   
   # Uncomment appropriate preset
   # Preset 1: Generic HMS
   # Preset 2: Specific Hospital
   # Preset 3: Development
   # Preset 4: Multi-branch Group
   ```

3. **Document tenant structure**
   ```
   # In your deployment notes
   hms.yourdomain.com           → Default (system_default_tenant)
   north-hms.yourdomain.com     → North Branch
   south-hms.yourdomain.com     → South Branch
   citycare-hms.yourdomain.com  → Partner Hospital
   Configuration Reference

### All Available Options

See `deployment-config.sh` template for complete list. Key sections:

**Core Settings**:
- `DEPLOYMENT_DOMAIN` - Your domain or empty for IP
- `DEFAULT_TENANT_SUBDOMAIN` - System default tenant identifier
- `DEPLOYMENT_MODE` - `http` or `https`

**Email Configuration**:
- `SMTP_EMAIL` - Sending email address
- `SMTP_PASSWORD` - SMTP app password
- `ADMIN_EMAILS` - Comma-separated admin emails

**Security** (auto-generated if empty):
- `MYSQL_ROOT_PASSWORD` - MySQL root password
- `MYSQL_DB_PASSWORD` - Application database password
- `JWT_SECRET` - JWT signing secret

**Integrations**:
- `ENABLE_WHATSAPP` - Enable WhatsApp campaigns
- `MSGPK_WHATSAPP_API_KEY` - WhatsApp API key
- `OPENAI_API_KEY` - OpenAI API key for AI features
- `FBR_INTEGRATION_ENABLED` - Enable FBR tax integration
- `WEBHOOK_URL` - Google Chat webhook for notifications

**Advanced**:
- `BACKEND_IMAGE_TAG` - Docker image version (default: `latest`)
- `PATIENT_DEFAULT_PASSWORD` - Default password for patients
- `RECEPTION_SHARE_ENABLED` - Enable reception commission
- `RECEPTION_SHARE_PERCENTAGE` - Commission percentage

### Preset Examples

The template includes 4 ready-to-use presets:
1. **Generic HMS** - Standard deployment
2. **Specific Hospital** - Branded deployment
3. **Development** - IP-based testing
4. **Multi-branch Group** - Hospital chain with integrations

---

## Getting Help

### Self-Service Resources

1. **Check deployment logs**:
   ```bash
   tail -f deployment_$(date +%F)*.log
   ```

2. **View application logs**:
   ```bash
   docker-compose logs -f hospital-apis
   docker-compose logs -f mysql
   ```

3. **Validate configuration**:
   ```bash
   source deployment-config.local.sh
   validate_config
   ```

4. **Review documentation**:
   - Main README: `../README.md`
   - Production Checklist: `../PRODUCTION-CHECKLIST.md`
   - This guide: `docs/GENERIC_DEPLOYMENT_GUIDE.md`

### Support Channels

- **Email**: nxtwebmasters@gmail.com
- **Phone**: +92 312 8776604
- **Repository Issues**: See main project GitHub

---

**Last Updated**: February 2026  
**Guide Version**: 2.0  
**Compatible With**: deploy.sh v2.0+
   docker exec hospital-mysql mysqldump -u root -p nxt-hospital > backup_$(date +%F).sql
   
   # Backup config
   cp deployment-config.local.sh deployment-config.local.sh.backup
   ```

3. **Monitor after deployment**
   ```bash
   # Watch logs for 5-10 minutes
   docker-compose logs -f hospital-apis
   
   # Check health endpoints
   watch -n 5 'curl -s https://yourdomain.com/api-server/health | jq'
   
   # Verify database
   docker exec hospital-mysql mysql -u root -p -e "SELECT tenant_subdomain FROM nxt_tenant" nxt-hospital
   ```

### Security Recommendations

1. **Generate unique credentials per environment**
   - Never reuse production passwords in staging
   - Let deploy.sh auto-generate secure passwords
   - Save credentials file to password manager

2. **Use HTTPS in production**
   ```bash
   DEPLOYMENT_MODE="https"  # Always for production
   ```

3. **Restrict access**
   ```bash
   # Configure firewall
   sudo ufw allow 22    # SSH
   sudo ufw allow 80    # HTTP
   sudo ufw allow 443   # HTTPS
   sudo ufw enable
   ```

4. **Regular updates**
   ```bash
   # Update OS packages monthly
   sudo apt update && sudo apt upgrade
   
   # Update Docker images
   docker-compose pull
   docker-compose up -d
```

### Backup & Restore

```bash
# Manual backup
docker exec hospital-mysql mysqldump -u root -p'<password>' nxt-hospital > backup.sql

# Restore
docker exec -i hospital-mysql mysql -u root -p'<password>' nxt-hospital < backup.sql

# Scheduled backups (configured automatically)
sudo crontab -l | grep hms-backup
# 0 3 * * * /usr/local/bin/hms-backup.sh
```

### CI/CD Integration

**GitLab CI**:
```yaml
# .gitlab-ci.yml
deploy_production:
  stage: deploy
  script:
    - cp configs/deployment-config.production.sh deployment-config.local.sh
    - ./deploy.sh
  only:
    - main
  when: manual

deploy_staging:
  stage: deploy
  script:
    - cp configs/deployment-config.staging.sh deployment-config.local.sh
    - ./deploy.sh
  only:
    - develop
```

**GitHub Actions**:
```yaml
# .github/workflows/deploy.yml
name: Deploy HMS
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Deploy to Production
        run: |
          cp configs/deployment-config.production.sh deployment-config.local.sh
          chmod +x deploy.sh
      ### Issue: SSL certificate errors

**Symptom**: Browser shows "Not secure" or certificate mismatch

**Solution**: Verify certificate and restart
```bash
# Check current certificates
sudo ls -la /etc/letsencrypt/live/<domain>/

# Check nginx configuration
cat nginx/conf.d/reverse-proxy-https.conf

# Restart nginx
docker-compose restart nginx-reverse-proxy

# Verify
curl -I https://<domain>

# Check nginx error logs
docker-compose logs nginx-reverse-proxy | grep -i error
```

### Issue: Database connection failed

**Symptom**: Backend can't connect to MySQL

**Solution**: Verify password consistency
```bash
# Check passwords match
grep DB_PASSWORD hms-backend.env
grep MYSQL_PASSWORD docker-compose.yml

# Should be identical
# If not, run deploy.sh again (it syncs passwords automatically)
```

### Issue: Changes to config not taking effect

**Symptom**: Modified deployment-config.local.sh but deployment uses old values

**Solution**: Restart deployment
```bash
# Stop containers
docker-compose down

# Redeploy (regenerates all configs)
./deploy.sh

# Verify
cat hms-backend.env | grep BASE_SUBDOMAIN
```
/etc/letsencrypt/live/<domain>/
├── fullchain.pem  → Certificate + chain
├── privkey.pem    → Private key
├── cert.pem       → Certificate only
└── chain.pem      → Chain only
```

### Manual Certificate Verification

```bash
# Verify certificate files exist
sudo ls -la /etc/letsencrypt/live/hms.yourdomain.com/

# Restart nginx
docker-compose restart nginx-reverse-proxy

# Verify SSL
curl -I https://hms.yourdomain.com

# Check nginx logs
docker-compose logs nginx-reverse-proxy
```

---

## Integration Configuration

### Pre-configure Integrations (Optional)

Edit `deployment-config.local.sh`:

```bash
# Email Notifications
SMTP_EMAIL="noreply@yourdomain.com"
SMTP_PASSWORD="your-app-password"
ADMIN_EMAILS="admin1@domain.com,admin2@domain.com"

# WhatsApp Campaigns
ENABLE_WHATSAPP="true"
MSGPK_WHATSAPP_API_KEY="your-msgpk-key"
WHATSAPP_IMAGE_URL="https://yourdomain.com/images/logo.jpg"

# AI Features
OPENAI_API_KEY="sk-..."
OPENAI_MODEL="gpt-4-turbo"

# FBR Tax Authority (Pakistan)
FBR_INTEGRATION_ENABLED="true"

# Google Chat Notifications
WEBHOOK_URL="https://chat.googleapis.com/v1/spaces/..."
```

**Security**: `deployment-config.local.sh` is git-ignored automatically.

---

## DNS Configuration
├── Domain and tenant info
├── MySQL passwords
├── JWT secret
└── Access URLs
```

---

## Environment-Specific Configs

### Multiple Deployments

```bash
# Family Care production
deployment-config.familycare-prod.sh

# Medeast production
deployment-config.medeast-prod.sh

# Development/staging
deployment-config.dev.sh

# Deploy specific environment
./deploy.sh --config deployment-config.familycare-prod.sh
```

---

## Validation

The config file has built-in validation:

```bash
# Check your config without deploying
source deployment-config.local.sh
validate_config
```

Checks:
- ✓ `DEFAULT_TENANT_SUBDOMAIN` is not empty
- ✓ `DEPLOYMENT_MODE` is "http" or "https"
- ✓ HTTPS mode has a domain (not just IP)

---

## Integration Credentials

### Pre-configure Integrations (Optional)

```bash
# In deployment-config.local.sh

# WhatsApp
ENABLE_WHATSAPP="true"
MSGPK_WHATSAPP_API_KEY="your-key-here"
WHATSAPP_IMAGE_URL="https://yourdomain.com/images/logo.jpg"

# OpenAI
OPENAI_API_KEY="sk-..."
OPENAI_MODEL="gpt-4-turbo"

# FBR Tax Authority
FBR_INTEGRATION_ENABLED="true"

# Email
SMTP_EMAIL="noreply@yourdomain.com"
SMTP_PASSWORD="your-app-password"
ADMIN_EMAILS="admin1@domain.com,admin2@domain.com"
```

**Security Note**: Never commit `deployment-config.local.sh` to git (already in .gitignore).

---

## Troubleshooting

### Issue: Wrong tenant name after deployment

**Solution**: Delete and redeploy
```bash
docker-compose down -v  # Remove volumes
# Edit deployment-config.local.sh with correct DEFAULT_TENANT_SUBDOMAIN
./deploy.sh
```

### Issue: Can't access multi-tenant subdomains

**Solution**: Configure DNS wildcard
```dns
# In your DNS provider (Cloudflare, etc.)
Type: A
Name: familycare
Value: 192.168.1.100

Type: A
Name: *.familycare
Value: 192.168.1.100
```

### Issue: SSL certificate errors

**Symptom**: Browser shows "Not secure" or certificate mismatch

**Solution**: Verify certificate and restart
```bash
# Check current certificates
sudo ls -la /etc/letsencrypt/live/<domain>/

# Restart nginx
docker-compose restart nginx-reverse-proxy

# Verify
curl -I https://<domain>

# Check nginx logs for errors
docker-compose logs nginx-reverse-proxy | grep -i error
```

---

## CI/CD Integration

### GitLab CI Example

```yaml
# .gitlab-ci.yml
deploy:
  script:
    - cp deployment-config.familycare-prod.sh deployment-config.local.sh
    - ./deploy.sh
  only:
    - main
```

### GitHub Actions Example

```yaml
# .github/workflows/deploy.yml
- name: Deploy HMS
  run: |
    cp deployment-config.familycare-prod.sh deployment-config.local.sh
    ./deploy.sh
```

---

## Best Practices

1. **Keep sensitive configs private**
   - Use `deployment-config.local.sh` (git-ignored)
   - Never commit API keys or passwords

2. **Use presets for common deployments**
   - Uncomment preset sections in `deployment-config.sh`
   - Or create separate config files

3. **Document your tenant structure**
   ```
   familycare.nxtwebmasters.com          → Default tenant
   hospital1-familycare.nxtwebmasters.com → Hospital 1
   hospital2-familycare.nxtwebmasters.com → Hospital 2
   ```

4. **Test in staging first**
   ```bash
   # Use staging config
   ./deploy.sh --config deployment-config.staging.sh
   # Verify everything works
   # Then deploy to production
   ./deploy.sh --config deployment-config.prod.sh
   ```

---

## Reference: All Configuration Options

See `deployment-config.sh` for complete list with descriptions. Key sections:

- **Deployment Configuration**: Domain, tenant, mode
- **Credentials**: Email, database, JWT
- **Integrations**: WhatsApp, OpenAI, FBR, webhooks
- **Advanced Settings**: Docker images, patient defaults, reception share
- **Validation**: Built-in config validation

---

## Support

For questions or issues:

1. Check logs: `tail -f deployment_YYYYMMDD_HHMMSS.log`
2. Review docs: `docs/PRODUCTION_DEPLOYMENT.md`
3. Contact: nxtwebmasters@gmail.com
