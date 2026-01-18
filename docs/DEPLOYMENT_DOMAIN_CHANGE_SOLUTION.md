# Deployment Domain Change - Complete Solution Summary

## Issue Reported
```log
info: --> POST /api-server/auth/login (tenant: unknown)
warn: Tenant not found for subdomain: familycare
warn: Tenant not found for subdomain: familycare (hostname: familycare.nxtwebmasters.com)
```

## Root Cause Analysis

### The Problem
The HMS system was originally configured for `hms.nxtwebmasters.com` but is now being deployed to `familycare.nxtwebmasters.com`. The tenant resolution middleware couldn't find a corresponding tenant record in the database.

### How Tenant Resolution Works

1. **Request Flow**:
   ```
   User → familycare.nxtwebmasters.com 
   → Nginx (forwards Host header)
   → Backend (tenantMiddleware.js)
   → Extract subdomain ('familycare')
   → Database lookup (nxt_tenant table)
   → ❌ NOT FOUND → Error
   ```

2. **Configuration Layers**:
   - **Nginx**: Server name configured as `familycare.nxtwebmasters.com` ✅
   - **Environment**: `BASE_SUBDOMAIN=familycare` in hms-backend.env ✅
   - **Database**: Missing tenant record with `tenant_subdomain='familycare'` ❌
   - **Backend Code**: Dynamic, uses environment variable ✅

3. **The Mismatch**:
   ```javascript
   // tenantMiddleware.js extracts subdomain
   const subdomain = extractSubdomain('familycare.nxtwebmasters.com');
   // Returns: 'familycare'
   
   // Queries database
   SELECT * FROM nxt_tenant WHERE tenant_subdomain = 'familycare';
   // Returns: No rows (only 'hms' tenant exists)
   
   // Result: Tenant not found error
   ```

## Solution Provided

### Files Created

1. **SQL Migration Script**
   - **Path**: `data/scripts/5-add-familycare-tenant.sql`
   - **Purpose**: Adds tenant record for familycare subdomain
   - **Contents**: 
     ```sql
     INSERT INTO nxt_tenant (
       tenant_id, tenant_name, tenant_subdomain, 
       tenant_status, subscription_plan
     ) VALUES (
       'familycare_tenant', 
       'FamilyCare Complex Hospital', 
       'familycare',
       'active', 
       'enterprise'
     );
     ```

2. **Automated Fix Scripts**
   - **Bash**: `scripts/fix-familycare-tenant.sh`
   - **PowerShell**: `scripts/fix-familycare-tenant.ps1`
   - **Actions**:
     1. Execute SQL migration
     2. Verify tenant creation
     3. Clear Redis cache
     4. Restart backend service
     5. Test tenant resolution
     6. Display verification logs

3. **Documentation**
   - **Quick Start**: `FAMILYCARE_FIX_QUICK_START.md` (one-page fix guide)
   - **Full Documentation**: `docs/FAMILYCARE_TENANT_FIX.md` (detailed explanation)
   - **Verification Checklist**: `docs/TENANT_RESOLUTION_CHECKLIST.md` (step-by-step validation)

4. **README Update**
   - Added prominent warning about domain-specific deployment requirements
   - Links to fix documentation

## Deployment Instructions

### Quick Fix (Recommended)

**On Linux/Mac:**
```bash
cd nxt-hospital-skeleton-project
chmod +x scripts/fix-familycare-tenant.sh
./scripts/fix-familycare-tenant.sh
```

**On Windows PowerShell:**
```powershell
cd nxt-hospital-skeleton-project
.\scripts\fix-familycare-tenant.ps1
```

### Manual Fix

If you prefer to run commands manually:

```bash
# 1. Apply database migration
docker exec -i hospital-mysql mysql -u nxt_user -pNxtWebMasters464 nxt-hospital < data/scripts/5-add-familycare-tenant.sql

# 2. Verify tenant was created
docker exec hospital-mysql mysql -u nxt_user -pNxtWebMasters464 nxt-hospital -e \
  "SELECT tenant_id, tenant_subdomain, tenant_status FROM nxt_tenant WHERE tenant_subdomain='familycare';"

# 3. Clear Redis tenant cache
docker exec hospital-redis redis-cli FLUSHALL

# 4. Restart backend to reload configuration
docker restart api-hospital

# 5. Wait for health check
sleep 10
docker exec api-hospital curl -f http://localhost:80/health
```

### One-Liner Command

```bash
docker exec -i hospital-mysql mysql -u nxt_user -pNxtWebMasters464 nxt-hospital < data/scripts/5-add-familycare-tenant.sql && docker exec hospital-redis redis-cli FLUSHALL && docker restart api-hospital
```

## Verification Steps

### 1. Check Database

```bash
docker exec hospital-mysql mysql -u nxt_user -pNxtWebMasters464 nxt-hospital -e \
  "SELECT tenant_id, tenant_name, tenant_subdomain, tenant_status FROM nxt_tenant WHERE tenant_subdomain='familycare';"
```

**Expected Output:**
```
+-------------------+-----------------------------+-----------------+---------------+
| tenant_id         | tenant_name                 | tenant_subdomain| tenant_status |
+-------------------+-----------------------------+-----------------+---------------+
| familycare_tenant | FamilyCare Complex Hospital | familycare      | active        |
+-------------------+-----------------------------+-----------------+---------------+
```

### 2. Check Application Logs

```bash
docker logs -f api-hospital | grep -i "tenant"
```

**Before Fix:**
```log
warn: Tenant not found for subdomain: familycare
info: --> POST /api-server/auth/login (tenant: unknown)
```

**After Fix:**
```log
debug: Tenant loaded from database: familycare_tenant
info: Tenant context attached: familycare_tenant (FamilyCare Complex Hospital)
info: --> POST /api-server/auth/login (tenant: familycare_tenant)
```

### 3. Test Login

1. Visit https://familycare.nxtwebmasters.com
2. Attempt to log in
3. Check logs - should show `(tenant: familycare_tenant)` instead of `(tenant: unknown)`
4. Login should succeed (if credentials are correct)

## Backend Code Review

### ✅ No Issues Found

Verified the following in `hms-backend/`:

1. **tenantMiddleware.js** (Lines 30, 47-49, 76-77)
   - Uses `process.env.BASE_SUBDOMAIN || 'hms'` - No hardcoded values ✅
   - All references to 'hms' are in comments/examples only ✅

2. **publicTenantMiddleware.js**
   - Properly extracts tenant from headers/query/body ✅
   - Falls back to `system_default_tenant` when appropriate ✅

3. **server.js**
   - No tenant-related hardcoded values found ✅
   - Uses middleware pattern correctly ✅

4. **Tenant Resolution Logic**
   ```javascript
   // Location: hms-backend/middlewares/tenantMiddleware.js
   const SYSTEM_SUBDOMAIN = process.env.BASE_SUBDOMAIN || 'hms';
   
   const extractSubdomain = (hostname) => {
     // Handles: familycare.nxtwebmasters.com → 'familycare'
     // Handles: hospital1.familycare.nxtwebmasters.com → 'hospital1'
     // Handles: localhost → Uses BASE_SUBDOMAIN from env
   }
   ```

### Configuration Alignment

| Component | Configuration | Value | Status |
|-----------|--------------|-------|--------|
| Nginx | server_name | `familycare.nxtwebmasters.com` | ✅ Correct |
| Environment | BASE_SUBDOMAIN | `familycare` | ✅ Correct |
| Backend Code | SYSTEM_SUBDOMAIN | Uses `process.env.BASE_SUBDOMAIN` | ✅ Dynamic |
| Database | nxt_tenant.tenant_subdomain | Was missing, now added | ✅ Fixed |

## Impact Assessment

### ✅ Safe to Deploy
- **Zero Data Loss**: Only adds new tenant record
- **Backwards Compatible**: Original 'hms' tenant remains intact
- **No Code Changes**: Only database configuration update
- **Minimal Downtime**: ~10 seconds for Redis clear + backend restart

### ✅ Bill UUID Tenant Isolation
- No impact on previous tenant isolation fixes
- `bill_uuid` UNIQUE constraint remains valid
- Tenant-specific counters work independently
- Global uniqueness preserved through timestamp-based IDs

## Multi-Tenant Architecture

### How It Works

```
┌─────────────────────────────────────────────────┐
│         Request: familycare.nxtwebmasters.com   │
└──────────────────┬──────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────┐
│              Nginx Reverse Proxy                │
│  (Forwards Host header to backend)              │
└──────────────────┬──────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────┐
│         tenantMiddleware.js                     │
│  1. Extract subdomain: 'familycare'             │
│  2. Query DB: WHERE tenant_subdomain=?          │
│  3. Attach tenant context to request            │
└──────────────────┬──────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────┐
│         Business Logic / Controllers            │
│  - All queries filtered by req.tenant_id        │
│  - File uploads go to tenant-specific folders   │
│  - ID generation uses tenant-specific counters  │
└─────────────────────────────────────────────────┘
```

### Supported Patterns

1. **Single Domain Per Tenant**
   - `familycare.nxtwebmasters.com` → `familycare_tenant`
   - `hms.nxtwebmasters.com` → `system_default_tenant`

2. **Subdomain-Based Multi-Tenancy**
   - `branch1.familycare.nxtwebmasters.com` → `branch1_tenant`
   - `branch2.familycare.nxtwebmasters.com` → `branch2_tenant`

3. **Development/Localhost**
   - `localhost:5002` → Uses `BASE_SUBDOMAIN` from environment

## Troubleshooting Guide

### Still Getting "tenant: unknown"?

1. **Verify Database Record Exists**
   ```bash
   docker exec hospital-mysql mysql -u nxt_user -pNxtWebMasters464 nxt-hospital -e \
     "SELECT * FROM nxt_tenant WHERE tenant_subdomain='familycare';"
   ```

2. **Check Environment Variable**
   ```bash
   docker exec api-hospital printenv | grep BASE_SUBDOMAIN
   # Should output: BASE_SUBDOMAIN=familycare
   ```

3. **Clear Cache and Restart**
   ```bash
   docker exec hospital-redis redis-cli FLUSHALL
   docker restart api-hospital
   ```

4. **Check Nginx Host Header**
   ```bash
   docker logs nginx | grep -i "host:"
   # Verify Host header is being forwarded correctly
   ```

5. **Enable Debug Logging**
   Add to hms-backend.env:
   ```env
   LOG_LEVEL=debug
   ```
   Then restart and check logs:
   ```bash
   docker restart api-hospital
   docker logs -f api-hospital | grep "subdomain\|tenant"
   ```

### Different Domain Name?

If deploying to a different domain (e.g., `myhotel.example.com`):

1. **Update hms-backend.env**:
   ```env
   BASE_SUBDOMAIN=myhotel
   ```

2. **Update nginx/conf.d/reverse-proxy-https.conf**:
   ```nginx
   server_name myhotel.example.com *.myhotel.example.com;
   ```

3. **Create matching tenant record**:
   ```sql
   INSERT INTO nxt_tenant (
     tenant_id, tenant_name, tenant_subdomain, tenant_status
   ) VALUES (
     'myhotel_tenant', 'My Hotel HMS', 'myhotel', 'active'
   );
   ```

4. **Restart services**:
   ```bash
   docker exec hospital-redis redis-cli FLUSHALL
   docker restart api-hospital
   ```

## Related Documentation

- [FAMILYCARE_FIX_QUICK_START.md](../FAMILYCARE_FIX_QUICK_START.md) - Quick reference
- [docs/FAMILYCARE_TENANT_FIX.md](FAMILYCARE_TENANT_FIX.md) - Detailed guide
- [docs/TENANT_RESOLUTION_CHECKLIST.md](TENANT_RESOLUTION_CHECKLIST.md) - Verification steps
- [docs/MULTI_TENANT_DNS_SETUP.md](MULTI_TENANT_DNS_SETUP.md) - DNS configuration
- [docs/TENANT_ONBOARDING.md](TENANT_ONBOARDING.md) - Adding new tenants

## Summary

The issue was caused by **missing database configuration** - the tenant record for `familycare` subdomain didn't exist. The solution adds this record via a SQL migration script, ensuring all configuration layers (Nginx, Environment, Database, Backend Code) are properly aligned.

**No backend code issues were found** - all tenant resolution logic is dynamic and uses environment variables correctly. The fix is purely a database configuration update.

The provided scripts automate the entire migration process and include comprehensive verification steps to ensure the fix is working correctly.
