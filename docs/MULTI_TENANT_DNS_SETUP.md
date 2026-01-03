# Multi-Tenant DNS & Domain Configuration Guide

Complete guide for configuring DNS, subdomains, and tenant routing for NXT HMS multi-tenant deployment.

---

## Understanding Multi-Tenancy Architecture

### **Legacy vs New Architecture**

#### **❌ OLD: Port-Based Routing (Legacy)**
```
hospital1.yourdomain.com → 203.0.113.45:5001
hospital2.yourdomain.com → 203.0.113.45:5002
hospital3.yourdomain.com → 203.0.113.45:5003
```

**Problems:**
- Separate deployment per hospital
- Multiple backend instances
- Port management complexity
- No shared database/resources
- Difficult to maintain

#### **✅ NEW: Path-Based Multi-Tenancy (Current)**
```
yourdomain.com → 203.0.113.45:80 (Single IP, Single Deployment)

Tenant isolation via:
- Database: tenant_id column in all tables
- Files: /images/<tenant_id>/
- Backend: X-Tenant-Id header from JWT token
```

**Benefits:**
- Single deployment for all hospitals
- Shared infrastructure
- Centralized management
- Easy tenant onboarding
- Cost-effective

---

## How Tenant Access Works (3 Methods)

### **Method 1: Path-Based Access (Current Default)**

**Single Domain, Tenant ID in URL:**
```
Admin Panel:    http://hms.yourdomain.com/?tenant=hospital_a
Patient Portal: http://hms.yourdomain.com/portal/?tenant=hospital_b
```

**How it works:**
1. User accesses with tenant parameter
2. Frontend stores tenant in localStorage/session
3. All API calls include tenant context
4. Backend filters all queries by `tenant_id`

**Pros:** Simple, works immediately with IP address  
**Cons:** Tenants share same URL, tenant ID visible in URL

---

### **Method 2: Subdomain-Based Access (Recommended for Production)**

**Each Hospital Gets Own Subdomain:**
```
http://hospital-a.hms.yourdomain.com  → Tenant: hospital_a
http://hospital-b.hms.yourdomain.com  → Tenant: hospital_b
http://hospital-c.hms.yourdomain.com  → Tenant: hospital_c
```

**How it works:**
1. Nginx extracts subdomain from request
2. Backend middleware maps subdomain → tenant_id
3. All queries automatically filtered by tenant
4. Each hospital feels like independent system

**Pros:** Professional, branded URLs per hospital  
**Cons:** Requires wildcard DNS configuration

---

### **Method 3: Custom Domain per Tenant (Enterprise)**

**Each Hospital Uses Own Domain:**
```
http://cityhospital.com      → Tenant: tenant_city_hospital
http://caremedical.com        → Tenant: tenant_care_medical
http://familyclinic.pk        → Tenant: tenant_family_clinic
```

**How it works:**
1. CNAME points custom domain to your server
2. Nginx virtual host configuration per domain
3. Backend maps domain → tenant_id
4. Fully branded experience

**Pros:** Complete white-labeling, hospital owns domain  
**Cons:** Requires custom nginx configs per tenant

---

## DNS Configuration with cPanel (Hoster.pk)

### **Step 1: Setup Main Domain**

1. **Login to cPanel** at Hoster.pk
2. **Navigate to**: Zone Editor or DNS Zone Editor
3. **Add A Record** for main domain:

```
Type:  A
Host:  @ (or yourdomain.com)
Value: 203.0.113.45  (Your Contabo VM IP)
TTL:   14400 (4 hours)
```

4. **Add A Record** for HMS subdomain:

```
Type:  A
Host:  hms (or hms.yourdomain.com)
Value: 203.0.113.45
TTL:   14400
```

**Result:** `http://hms.yourdomain.com` points to your VM

---

### **Step 2: Setup Wildcard Subdomain (For Multi-Tenancy)**

**Option A: Wildcard A Record (Recommended)**

```
Type:  A
Host:  *.hms (matches hospital-a.hms.yourdomain.com, hospital-b.hms.yourdomain.com)
Value: 203.0.113.45
TTL:   14400
```

**Result:** All subdomains under `*.hms.yourdomain.com` point to your VM

**Option B: Individual A Records per Tenant**

```
Type:  A
Host:  hospital-a.hms
Value: 203.0.113.45

Type:  A
Host:  hospital-b.hms
Value: 203.0.113.45

Type:  A
Host:  hospital-c.hms
Value: 203.0.113.45
```

**Result:** Only defined hospitals accessible

---

### **Step 3: Verify DNS Propagation**

```bash
# Check DNS resolution
nslookup hms.yourdomain.com

# Check wildcard
nslookup hospital-a.hms.yourdomain.com

# Check from your VM
dig hms.yourdomain.com

# Test with curl
curl -I http://hms.yourdomain.com
```

**DNS propagation takes 5 minutes to 48 hours** (usually 15-30 minutes)

---

## Nginx Configuration for Subdomain Routing

### **Enable Subdomain-Based Tenant Detection**

Edit `nginx/conf.d/reverse-proxy-http.conf`:

```nginx
# Map subdomain to tenant_id
map $host $tenant_subdomain {
    default                           "default";
    ~^(?<subdomain>[^.]+)\.hms\.yourdomain\.com$  $subdomain;
}

server {
    listen 80;
    server_name *.hms.yourdomain.com hms.yourdomain.com;
    
    # ... existing configuration ...

    # API proxy with tenant header
    location /api-server/ {
        proxy_pass http://hospital-apis:80;
        
        # Pass subdomain to backend
        proxy_set_header X-Tenant-Subdomain $tenant_subdomain;
        proxy_set_header X-Original-Host $host;
        
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Frontend proxies remain same
    # ... rest of config ...
}
```

**Restart Nginx:**
```bash
docker compose restart nginx
```

---

## Backend Tenant Resolution (Already Implemented)

The backend already supports tenant resolution from:

1. **JWT Token** (primary method)
   - User logs in with subdomain
   - JWT contains `tenant_id`
   - All requests validated

2. **X-Tenant-Subdomain Header** (from nginx)
   - Nginx extracts subdomain
   - Backend looks up `tenant_id` from `nxt_tenant` table
   - Validates and applies filter

3. **Query Parameter Fallback**
   - `?tenant=hospital_a`
   - For public endpoints without auth

---

## Complete Tenant Onboarding with DNS

### **Scenario: Add "City Hospital" as New Tenant**

#### **Step 1: Create Tenant in Database**

```sql
INSERT INTO nxt_tenant (
    tenant_id,
    tenant_name,
    tenant_subdomain,
    tenant_status,
    subscription_plan,
    features
) VALUES (
    'tenant_city_hospital',
    'City Hospital',
    'city-hospital',  -- This becomes: city-hospital.hms.yourdomain.com
    'active',
    'premium',
    '{"fbr":true,"campaigns":true,"ai":true}'
);
```

#### **Step 2: Configure DNS (cPanel)**

**Option A: Using Wildcard (No Action Needed)**
- If you already have `*.hms.yourdomain.com` → VM IP
- **Nothing to do!** New subdomain works automatically

**Option B: Individual Record**
```
Type:  A
Host:  city-hospital.hms
Value: 203.0.113.45
TTL:   14400
```

#### **Step 3: Create Tenant Admin User**

```sql
INSERT INTO nxt_user (
    tenant_id,
    username,
    email,
    password_hash,
    full_name,
    role,
    status
) VALUES (
    'tenant_city_hospital',
    'admin',
    'admin@cityhospital.com',
    '$2b$10$X8Z9YqJ5KqP4LmN6RqD7eOZjQwK5gM3hF2pV4xW8nY7zT6uE5sA9C',  -- Password: NxtHospital123
    'City Hospital Admin',
    'admin',
    'active'
);
```

#### **Step 4: Create File Storage**

```bash
mkdir -p images/tenant_city_hospital/{patients,reports,prescriptions,lab-results}
chmod -R 755 images/tenant_city_hospital
```

#### **Step 5: Test Access**

```bash
# Wait 5-15 minutes for DNS propagation
# Then test:

curl -I http://city-hospital.hms.yourdomain.com

# Should return: HTTP/1.1 200 OK
```

**Access in Browser:**
```
http://city-hospital.hms.yourdomain.com/
```

#### **Step 6: Verify Tenant Isolation**

```sql
-- Login as City Hospital admin
-- Try to access patients - should only see City Hospital patients
SELECT COUNT(*) FROM nxt_patient WHERE tenant_id = 'tenant_city_hospital';

-- Should NOT see other tenants
SELECT COUNT(*) FROM nxt_patient WHERE tenant_id != 'tenant_city_hospital';
-- Should return 0 (if backend properly filters)
```

---

## SSL/HTTPS Configuration for Multi-Tenant

### **Option 1: Wildcard SSL Certificate (Recommended)**

```bash
# Install certbot
sudo apt install certbot

# Obtain wildcard certificate
sudo certbot certonly --manual --preferred-challenges=dns \
  -d hms.yourdomain.com -d *.hms.yourdomain.com

# Follow prompts to add TXT records in cPanel DNS
# Certificate saved to: /etc/letsencrypt/live/hms.yourdomain.com/
```

**Update Nginx for HTTPS:**

```nginx
server {
    listen 443 ssl http2;
    server_name *.hms.yourdomain.com hms.yourdomain.com;
    
    ssl_certificate /etc/letsencrypt/live/hms.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/hms.yourdomain.com/privkey.pem;
    
    # ... rest of config same as HTTP ...
}

# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name *.hms.yourdomain.com hms.yourdomain.com;
    return 301 https://$host$request_uri;
}
```

### **Option 2: Individual Certificates per Subdomain**

```bash
# For each tenant
sudo certbot certonly --standalone -d city-hospital.hms.yourdomain.com
sudo certbot certonly --standalone -d care-medical.hms.yourdomain.com
```

**Not recommended:** Too many certificates to manage

---

## Quick Reference: IP vs Domain Access

### **Using IP Address (Development/Testing)**

```
Deployment:    http://203.0.113.45/
Admin Panel:   http://203.0.113.45/?tenant=hospital_a
Patient Portal: http://203.0.113.45/portal/?tenant=hospital_a

File Access:   http://203.0.113.45/images/tenant_hospital_a/patients/file.jpg
```

**Pros:** Works immediately, no DNS needed  
**Cons:** Not professional, tenants share URL

### **Using Domain (Production)**

```
Deployment:    http://hms.yourdomain.com/
Admin Panel:   http://hospital-a.hms.yourdomain.com/
Patient Portal: http://hospital-a.hms.yourdomain.com/portal/

File Access:   http://hospital-a.hms.yourdomain.com/images/tenant_hospital_a/patients/file.jpg
```

**Pros:** Professional, branded per tenant  
**Cons:** Requires DNS configuration

---

## Automated Tenant Creation Script

Create `scripts/add-tenant.sh`:

```bash
#!/bin/bash

# Usage: ./scripts/add-tenant.sh "City Hospital" "city-hospital"

TENANT_NAME=$1
TENANT_SUBDOMAIN=$2
TENANT_ID="tenant_${TENANT_SUBDOMAIN//-/_}"

echo "Creating tenant: $TENANT_NAME"
echo "Subdomain: $TENANT_SUBDOMAIN.hms.yourdomain.com"
echo "Tenant ID: $TENANT_ID"
echo ""

# 1. Create tenant in database
docker exec -i hospital-mysql mysql -u nxt_user -pYOUR_PASSWORD nxt-hospital << EOF
INSERT INTO nxt_tenant (tenant_id, tenant_name, tenant_subdomain, tenant_status, created_by)
VALUES ('$TENANT_ID', '$TENANT_NAME', '$TENANT_SUBDOMAIN', 'trial', 'script');
EOF

# 2. Create file storage
mkdir -p images/$TENANT_ID/{patients,reports,prescriptions,lab-results}
chmod -R 755 images/$TENANT_ID

# 3. Create admin user
echo "Tenant created successfully!"
echo ""
echo "Next steps:"
echo "1. Access: http://$TENANT_SUBDOMAIN.hms.yourdomain.com/"
echo "2. Create admin user via UI or SQL"
echo "3. Configure tenant settings"
```

**Usage:**
```bash
chmod +x scripts/add-tenant.sh
./scripts/add-tenant.sh "Care Medical Center" "care-medical"
```

---

## Troubleshooting

### **Problem: Subdomain Not Resolving**

**Check DNS:**
```bash
nslookup hospital-a.hms.yourdomain.com
```

**Solution:**
- Wait 15-30 minutes for DNS propagation
- Verify wildcard or A record in cPanel
- Clear DNS cache: `sudo systemd-resolve --flush-caches`

### **Problem: Wrong Tenant Data Showing**

**Cause:** Backend not properly filtering by tenant_id

**Check:**
```sql
-- Verify tenant exists
SELECT * FROM nxt_tenant WHERE tenant_subdomain = 'hospital-a';

-- Check if backend is setting tenant context
-- Enable debug logging in hms-backend.env:
LOG_LEVEL=debug
```

### **Problem: SSL Certificate Not Working**

**For Wildcard:**
```bash
# Verify certificate includes wildcard
sudo certbot certificates

# Check nginx config
docker compose exec nginx nginx -t

# Restart nginx
docker compose restart nginx
```

---

## Best Practices

1. **Use Wildcard DNS** for easier tenant onboarding
2. **Get Wildcard SSL** for all subdomains
3. **Standardize Subdomain Format**: `hospital-name.hms.domain.com`
4. **Document Tenant Mapping**: Keep spreadsheet of subdomain → tenant_id
5. **Test Isolation**: Always verify new tenants can't access other tenant data
6. **Backup Before Adding Tenants**: Database corruption affects all tenants
7. **Monitor DNS**: Set up alerts for DNS issues

---

## Migration from Legacy (Port-Based) to New (Multi-Tenant)

### **Step 1: Export Legacy Data**

```bash
# Export each hospital database
mysqldump -u root -p hospital1_db > hospital1_backup.sql
mysqldump -u root -p hospital2_db > hospital2_backup.sql
```

### **Step 2: Create Tenants**

```sql
INSERT INTO nxt_tenant VALUES ('tenant_hospital1', 'Hospital 1', 'hospital1', 'active');
INSERT INTO nxt_tenant VALUES ('tenant_hospital2', 'Hospital 2', 'hospital2', 'active');
```

### **Step 3: Import with Tenant ID**

```sql
-- Modify backup SQL to add tenant_id
UPDATE nxt_patient SET tenant_id = 'tenant_hospital1' WHERE ...;
UPDATE nxt_appointment SET tenant_id = 'tenant_hospital1' WHERE ...;
-- etc.
```

### **Step 4: Update DNS**

**Old:**
```
hospital1.yourdomain.com → 203.0.113.45:5001
hospital2.yourdomain.com → 203.0.113.45:5002
```

**New:**
```
hospital1.hms.yourdomain.com → 203.0.113.45:80
hospital2.hms.yourdomain.com → 203.0.113.45:80
```

---

## Summary

✅ **Current Setup:** Single IP, path-based tenancy with `?tenant=xxx` parameter  
✅ **Production Setup:** Subdomain-based with `hospital.hms.yourdomain.com`  
✅ **DNS Config:** Wildcard A record `*.hms.yourdomain.com` → VM IP  
✅ **New Tenant:** Just add to database, subdomain works automatically  
✅ **No Port Mapping Needed:** Single nginx on port 80/443 handles all tenants  

For questions, refer to:
- [TENANT_ONBOARDING.md](TENANT_ONBOARDING.md) - Tenant creation steps
- [PRODUCTION_DEPLOYMENT.md](PRODUCTION_DEPLOYMENT.md) - Initial deployment
- [README.md](../README.md) - Architecture overview
