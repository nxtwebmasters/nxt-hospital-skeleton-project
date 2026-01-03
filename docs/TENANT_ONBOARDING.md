# Tenant Onboarding Guide

Complete guide for adding new hospital tenants to the NXT HMS multi-tenant system.

---

## Prerequisites

- Docker stack running (`docker compose up -d`)
- MySQL container healthy and accessible
- Understanding of tenant isolation requirements
- Tenant details: name, subdomain, subscription plan

---

## Quick Start: Add a New Tenant

### Step 1: Insert Tenant Record

```sql
-- Replace values with actual tenant information
INSERT INTO nxt_tenant (
    tenant_id,
    tenant_name,
    tenant_subdomain,
    tenant_status,
    subscription_plan,
    subscription_start_date,
    subscription_end_date,
    max_users,
    max_patients,
    features,
    created_by
) VALUES (
    'tenant_demo_hospital',                    -- Unique ID (use tenant_<slug> pattern)
    'Demo Hospital',                            -- Display name
    'demo',                                     -- Subdomain (demo.yourdomain.com)
    'active',                                   -- Status: active, trial, suspended, expired
    'premium',                                  -- Plan: basic, premium, enterprise
    CURDATE(),                                  -- Subscription start
    DATE_ADD(CURDATE(), INTERVAL 1 YEAR),      -- Subscription end (1 year)
    100,                                        -- Max users
    50000,                                      -- Max patients
    '{"fbr":true,"campaigns":true,"ai":true}', -- Feature flags (JSON)
    'admin'                                     -- Created by
);
```

### Step 2: Verify Tenant Creation

```powershell
# PowerShell (Windows)
docker exec -i hospital-mysql mysql -u nxt_user -pNxtWebMasters464 nxt-hospital -e "SELECT tenant_id, tenant_name, tenant_subdomain, tenant_status FROM nxt_tenant WHERE tenant_id='tenant_demo_hospital';"
```

```bash
# Bash (Linux/Mac)
docker exec -i hospital-mysql mysql -u nxt_user -pNxtWebMasters464 nxt-hospital -e "SELECT tenant_id, tenant_name, tenant_subdomain, tenant_status FROM nxt_tenant WHERE tenant_id='tenant_demo_hospital';"
```

### Step 3: Create Tenant-Specific Configuration

```sql
-- Hospital basic settings
INSERT INTO nxt_tenant_config (tenant_id, config_key, config_value, config_type) VALUES
('tenant_demo_hospital', 'hospital_name', 'Demo Hospital', 'string'),
('tenant_demo_hospital', 'hospital_address', '123 Medical St, Healthcare City', 'string'),
('tenant_demo_hospital', 'hospital_phone', '+92-300-1234567', 'string'),
('tenant_demo_hospital', 'hospital_email', 'info@demohospital.com', 'string'),
('tenant_demo_hospital', 'timezone', 'Asia/Karachi', 'string'),
('tenant_demo_hospital', 'currency', 'PKR', 'string'),
('tenant_demo_hospital', 'date_format', 'DD/MM/YYYY', 'string'),
('tenant_demo_hospital', 'time_format', '24h', 'string');

-- Billing & tax settings
INSERT INTO nxt_tenant_config (tenant_id, config_key, config_value, config_type) VALUES
('tenant_demo_hospital', 'tax_rate', '17', 'number'),
('tenant_demo_hospital', 'fbr_pos_id', '', 'string'),
('tenant_demo_hospital', 'fbr_api_token', '', 'string'),
('tenant_demo_hospital', 'enable_fbr_integration', 'false', 'boolean');
```

### Step 4: Create Tenant File Storage Directory

```powershell
# PowerShell (Windows)
mkdir -p images/tenant_demo_hospital
mkdir -p images/tenant_demo_hospital/patients
mkdir -p images/tenant_demo_hospital/reports
mkdir -p images/tenant_demo_hospital/prescriptions
mkdir -p images/tenant_demo_hospital/lab-results
```

```bash
# Bash (Linux/Mac)
mkdir -p images/tenant_demo_hospital/{patients,reports,prescriptions,lab-results}
chmod -R 755 images/tenant_demo_hospital
```

### Step 5: Create Initial Admin User

```sql
-- Create tenant admin user (password: NxtHospital123)
-- Password hash is bcrypt for 'NxtHospital123'
INSERT INTO nxt_user (
    tenant_id,
    username,
    email,
    password_hash,
    full_name,
    role,
    status,
    created_by
) VALUES (
    'tenant_demo_hospital',
    'admin',
    'admin@demohospital.com',
    '$2b$10$X8Z9YqJ5KqP4LmN6RqD7eOZjQwK5gM3hF2pV4xW8nY7zT6uE5sA9C',
    'Admin User',
    'admin',
    'active',
    'system'
);
```

### Step 6: Verify Complete Setup

```sql
-- Check tenant record
SELECT * FROM nxt_tenant WHERE tenant_id='tenant_demo_hospital'\G

-- Check tenant configurations
SELECT * FROM nxt_tenant_config WHERE tenant_id='tenant_demo_hospital';

-- Check tenant admin user
SELECT user_id, username, email, role, status 
FROM nxt_user 
WHERE tenant_id='tenant_demo_hospital';

-- Verify file storage
```

```bash
ls -la images/tenant_demo_hospital/
```

---

## Production Considerations

### DNS Configuration

For subdomain-based tenant access (e.g., `demo.yourdomain.com`):

1. **Add DNS A Record**:
   ```
   demo.yourdomain.com  →  <server_IP>
   ```

2. **Update Nginx for Subdomain Routing** (optional):
   - Currently uses path-based routing via `/api-server/` and `/portal/`
   - For subdomain routing, create tenant-specific nginx configs in `nginx/conf.d/`

### SSL Certificate (Let's Encrypt)

If using HTTPS with subdomain routing:

```bash
# Install certbot (if not already installed)
sudo apt-get install certbot python3-certbot-nginx

# Obtain wildcard certificate
sudo certbot certonly --manual --preferred-challenges=dns \
  -d yourdomain.com -d *.yourdomain.com

# Certificates will be stored in:
# /etc/letsencrypt/live/yourdomain.com/fullchain.pem
# /etc/letsencrypt/live/yourdomain.com/privkey.pem
```

### Tenant Status Management

```sql
-- Suspend tenant (e.g., payment failure)
UPDATE nxt_tenant 
SET tenant_status='suspended', updated_by='admin' 
WHERE tenant_id='tenant_demo_hospital';

-- Reactivate tenant
UPDATE nxt_tenant 
SET tenant_status='active', updated_by='admin' 
WHERE tenant_id='tenant_demo_hospital';

-- Mark as expired (subscription ended)
UPDATE nxt_tenant 
SET tenant_status='expired', updated_by='admin' 
WHERE tenant_id='tenant_demo_hospital';

-- Extend subscription
UPDATE nxt_tenant 
SET subscription_end_date=DATE_ADD(subscription_end_date, INTERVAL 1 YEAR),
    updated_by='admin'
WHERE tenant_id='tenant_demo_hospital';
```

---

## Tenant Isolation Checklist

Before deploying to production, verify tenant isolation:

### Database Level
- [x] All tables have `tenant_id` column (50+ tables)
- [ ] All API queries include `WHERE tenant_id = ?` filter
- [ ] Foreign key relationships preserve tenant boundaries
- [ ] Database indexes include `tenant_id` for performance

### File Storage Level
- [x] Files stored in tenant-specific directories (`/images/<tenant_id>/`)
- [ ] File access endpoints verify tenant ownership before serving
- [ ] File deletion operations validate tenant_id match
- [ ] Nginx serves files with proper path validation

### Application Level
- [ ] JWT tokens include `tenant_id` claim
- [ ] Middleware extracts and validates `tenant_id` on every request
- [ ] Controllers never accept `tenant_id` from request body/query
- [ ] API responses don't leak cross-tenant data

### Configuration Level
- [x] Tenant-specific configs in `nxt_tenant_config` table
- [ ] Feature flags respected per tenant
- [ ] Rate limiting applied per tenant
- [ ] Background jobs include tenant context

---

## Bulk Tenant Seeding (Development/Testing)

For seeding multiple test tenants:

```sql
-- Seed 5 test tenants
INSERT INTO nxt_tenant (tenant_id, tenant_name, tenant_subdomain, tenant_status, created_by) VALUES
('tenant_hospital_a', 'Hospital A', 'hospitala', 'trial', 'system'),
('tenant_hospital_b', 'Hospital B', 'hospitalb', 'trial', 'system'),
('tenant_hospital_c', 'Hospital C', 'hospitalc', 'trial', 'system'),
('tenant_hospital_d', 'Hospital D', 'hospitald', 'trial', 'system'),
('tenant_hospital_e', 'Hospital E', 'hospitale', 'trial', 'system');

-- Verify
SELECT tenant_id, tenant_name, tenant_subdomain, tenant_status FROM nxt_tenant;
```

---

## Tenant Removal (Caution)

**WARNING**: This permanently deletes all tenant data. Always backup first.

```sql
-- Backup tenant data first
CREATE DATABASE backup_tenant_demo_hospital;
-- (Manual export or mysqldump required)

-- Delete tenant configurations
DELETE FROM nxt_tenant_config WHERE tenant_id='tenant_demo_hospital';

-- Delete tenant users
DELETE FROM nxt_user WHERE tenant_id='tenant_demo_hospital';

-- Delete tenant data (cascade through all tenant-aware tables)
-- WARNING: Verify foreign key constraints before running
DELETE FROM nxt_tenant WHERE tenant_id='tenant_demo_hospital';
```

```bash
# Remove tenant files
rm -rf images/tenant_demo_hospital
```

---

## Troubleshooting

### Issue: Tenant Not Found Error

**Symptoms**: API returns "Tenant not found" or 404

**Diagnosis**:
```sql
-- Check if tenant exists and is active
SELECT tenant_id, tenant_status FROM nxt_tenant WHERE tenant_id='tenant_demo_hospital';
```

**Solution**: Verify tenant_id matches exactly (case-sensitive) and status is 'active'

### Issue: File Upload Fails

**Symptoms**: 500 error on file upload, "ENOENT" errors in logs

**Diagnosis**:
```bash
# Check if directory exists and has correct permissions
ls -la images/tenant_demo_hospital/
```

**Solution**: Create missing directories:
```bash
mkdir -p images/tenant_demo_hospital/{patients,reports,prescriptions,lab-results}
chmod -R 755 images/tenant_demo_hospital
```

### Issue: Cross-Tenant Data Leakage

**Symptoms**: Users see data from other tenants

**Diagnosis**: Enable query logging and check for missing `tenant_id` filters

**Solution**: Review and update all queries to include proper tenant filtering

---

## Best Practices

1. **Naming Convention**: Use `tenant_<slug>` pattern for tenant IDs (e.g., `tenant_citycare_hospital`)
2. **Subdomain Format**: Keep subdomains short, alphanumeric, no special characters
3. **Feature Flags**: Use JSON format in `features` column for flexibility
4. **Subscription Dates**: Always set both start and end dates for active tenants
5. **File Organization**: Maintain consistent subdirectories across all tenants
6. **Backup Strategy**: Regular tenant-specific backups before major changes
7. **Testing**: Test new tenant in trial mode before activating

---

## DNS Configuration (Optional - For Subdomain Access)

After creating tenant in database, you can configure subdomain access:

### **Access Methods**

**Method 1: Path-Based (Default)**
```
http://yourdomain.com/?tenant=tenant_demo_hospital
http://yourdomain.com/portal/?tenant=tenant_demo_hospital
```

**Method 2: Subdomain-Based (Recommended)**
```
http://demo.hms.yourdomain.com/
http://demo.hms.yourdomain.com/portal/
```

**Setup Subdomain Access:**
1. **In cPanel** (Hoster.pk or your DNS provider):
   - Add wildcard A record: `*.hms.yourdomain.com` → Your VM IP
   - OR add specific A record: `demo.hms.yourdomain.com` → Your VM IP

2. **Verify DNS propagation** (5-30 minutes):
   ```bash
   nslookup demo.hms.yourdomain.com
   ```

3. **Access tenant**:
   ```
   http://demo.hms.yourdomain.com/
   ```

**For detailed DNS configuration**, see [MULTI_TENANT_DNS_SETUP.md](MULTI_TENANT_DNS_SETUP.md)

---

## Next Steps

After onboarding a new tenant:

1. ✅ Verify tenant can log in via admin credentials
2. ✅ Test basic workflows (patient creation, appointment booking)
3. ✅ Verify file uploads work and are isolated
4. ✅ Configure DNS/subdomain (see [MULTI_TENANT_DNS_SETUP.md](MULTI_TENANT_DNS_SETUP.md))
5. ✅ Configure tenant-specific integrations (FBR, WhatsApp, email)
6. ✅ Set up monitoring and alerts for the tenant
7. ✅ Provide onboarding documentation to tenant admin
8. ✅ Schedule follow-up training sessions

For questions or issues, refer to:
- [PRODUCTION_DEPLOYMENT.md](PRODUCTION_DEPLOYMENT.md) for infrastructure setup
- [MULTI_TENANT_DNS_SETUP.md](MULTI_TENANT_DNS_SETUP.md) for DNS and subdomain configuration
- [README.md](../README.md) for architecture overview
- Backend source repository for query patterns and middleware implementation
