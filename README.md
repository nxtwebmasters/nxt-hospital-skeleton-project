# nxt-hospital-skeleton-project

## 🚀 Quick Start (Testing/Development)

**Clone and run on Ubuntu VM in under 5 minutes:**

```bash
# 1. Clone the repository
git clone <your-repo-url>
cd nxt-hospital-skeleton-project

# 2. Start all services
docker compose up -d

# 3. Wait for services to initialize (~30 seconds)
docker compose ps

# 4. Verify deployment health
bash scripts/verify-deployment.sh

# 5. Access the application
# Admin Interface:  http://localhost/
# Patient Portal:   http://localhost/portal/
# API Health:       http://localhost/api-server/health
```

**Default Configuration:**
- All services run in HTTP-only mode (no TLS certificates required)
- Internal communication uses Docker service names (hospital-apis:80, patient-frontend:80, etc.)
- MySQL initializes with multi-tenant schema (58 tables with `tenant_id` columns)
- Default tenant: `system_default_tenant` (subdomain: `default`)
- Bootstrap data auto-seeded on first start
- Services accessible only via nginx reverse proxy (ports 5001/6001/8001 not exposed)

**Prerequisites:**
- Docker Engine 20.10+
- Docker Compose v2.0+
- Minimum 4GB RAM
- 10GB disk space

**For Production Deployment:**
See "Wildcard TLS (Let's Encrypt)" section below for HTTPS setup.

---

## Overview

This repository contains a small Docker Compose skeleton used to run the HMS services locally or on a VM. It includes an `nginx` reverse-proxy service that expects host-managed TLS certificates (Let’s Encrypt wildcard) mounted into the container at `/etc/letsencrypt`.

## Wildcard TLS (Let’s Encrypt) — quick guide

These instructions explain how to obtain a wildcard certificate via DNS-01 (manual TXT) and make it available to the Dockerized `nginx` service. The repository includes a helper script at `scripts/obtain_wildcard_cert.sh` to run `certbot` in manual DNS mode.

Prerequisites:
- A domain managed in HosterPK (or another DNS provider where you can add TXT records).
- A server (e.g., Contabo VM) with a public IP reachable from the internet.
- `certbot` installed on the host where you will request the certificate.

Steps:

1. Add a wildcard A record for your domain in your DNS panel:

	- Host: `*`
	- Value: your server IP (e.g., `203.0.113.45`)

2. On the VM (one-time, interactive) run the helper to request a wildcard certificate:

```bash
cd /opt/nxt-hms/nxt-hospital-skeleton-project/scripts
sudo bash ./obtain_wildcard_cert.sh example.com you@example.com
```

	- Replace `example.com` and `you@example.com` with your domain and email.
	- The script calls `certbot` in manual DNS mode and will prompt you with one or more `_acme-challenge` TXT records to add to your DNS.
	- Add the TXT records in HosterPK (or your DNS provider), wait for propagation, then press Enter to allow certbot to validate.

3. After successful issuance, cert files will be under `/etc/letsencrypt/live/example.com/` on the host. The Compose file mounts `/etc/letsencrypt` into the `nginx` container (read-only). Restart or bring up the stack so `nginx` picks up the certificates:

```bash
cd /opt/nxt-hms/nxt-hospital-skeleton-project
docker compose up -d
docker compose exec nginx nginx -t
docker compose exec nginx nginx -s reload
```

4. Renewals

 - Use `certbot renew` on the host. You can schedule a daily or weekly cron. When renewal succeeds, run a deploy-hook to reload the containerized `nginx` so it picks up new certs.

Example cron entry (edit to match your paths):

```cron
# Run renewal daily at 02:00 and reload nginx in the compose stack when a cert is renewed
0 2 * * * /usr/bin/certbot renew --deploy-hook "docker compose -f /opt/nxt-hms/nxt-hospital-skeleton-project/docker-compose.yml exec nginx nginx -s reload" >> /var/log/certbot-renew.log 2>&1
```

Notes and gotchas:
- The helper uses the manual DNS flow: you must add TXT records yourself in the DNS panel during the interactive request. DNS-API automation is intentionally avoided here.
- Ensure ports `80` and `443` on the VM are reachable from the internet while performing issuance.
- The `nginx` container expects the certificates to be present at `/etc/letsencrypt`. The Compose service mounts the host path into the container as read-only.
- If you prefer automated DNS updates, replace the manual certbot flow with an appropriate DNS plugin and adjust the script accordingly.

---

## 🧪 Testing Multi-Tenancy

The deployment includes a **default tenant** (`system_default_tenant`) ready for testing. Here's how to verify multi-tenancy is working:

### Quick Verification

```bash
# 1. Check default tenant exists
docker exec hospital-mysql mysql -u nxt_user -pNxtWebMasters464 \
  -e "SELECT tenant_id, tenant_name, tenant_subdomain FROM nxt_tenant" nxt-hospital

# Expected output:
# tenant_id              | tenant_name            | tenant_subdomain
# system_default_tenant  | System Default Hospital| default

# 2. Verify all tables have tenant_id column
docker exec hospital-mysql mysql -u nxt_user -pNxtWebMasters464 \
  -e "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.COLUMNS 
      WHERE TABLE_SCHEMA='nxt-hospital' AND COLUMN_NAME='tenant_id'" nxt-hospital

# Expected: 50+ tables listed

# 3. Test tenant isolation in patient table
docker exec hospital-mysql mysql -u nxt_user -pNxtWebMasters464 \
  -e "DESCRIBE nxt_patient" nxt-hospital | grep tenant_id

# Expected: tenant_id | varchar(50) | NO | | system_default_tenant
```

### Create a Test Tenant

```bash
# Add a second tenant for isolation testing
docker exec hospital-mysql mysql -u nxt_user -pNxtWebMasters464 nxt-hospital <<EOF
INSERT INTO nxt_tenant (
  tenant_id, 
  tenant_name, 
  tenant_subdomain, 
  tenant_status
) VALUES (
  'tenant_test_clinic', 
  'Test Clinic Hospital', 
  'test-clinic', 
  'active'
);
EOF

# Verify it was created
docker exec hospital-mysql mysql -u nxt_user -pNxtWebMasters464 \
  -e "SELECT * FROM nxt_tenant WHERE tenant_id='tenant_test_clinic'" nxt-hospital
```

### Test Data Isolation

```bash
# Create a patient in default tenant
docker exec hospital-mysql mysql -u nxt_user -pNxtWebMasters464 nxt-hospital <<EOF
INSERT INTO nxt_patient (tenant_id, patient_name, patient_mobile, patient_mrid)
VALUES ('system_default_tenant', 'John Doe', '1234567890', 'MR-00001');
EOF

# Create a patient in test tenant
docker exec hospital-mysql mysql -u nxt_user -pNxtWebMasters464 nxt-hospital <<EOF
INSERT INTO nxt_patient (tenant_id, patient_name, patient_mobile, patient_mrid)
VALUES ('tenant_test_clinic', 'Jane Smith', '9876543210', 'MR-00002');
EOF

# Query with tenant isolation
docker exec hospital-mysql mysql -u nxt_user -pNxtWebMasters464 \
  -e "SELECT patient_name, tenant_id FROM nxt_patient WHERE tenant_id='system_default_tenant'" nxt-hospital

# Should only show John Doe, not Jane Smith
```

### Monitor Tenant Queries

```bash
# Watch backend logs for tenant-aware queries
docker compose logs -f api-hospital | grep "tenant_id"

# You should see queries like:
# SELECT * FROM nxt_patient WHERE tenant_id = 'system_default_tenant' AND ...
```

### Known Limitations (Testing Mode)

⚠️ **Current deployment has 65 tenant-isolation vulnerabilities** in the application layer (controllers/services). While the database schema is multi-tenant ready, some queries don't enforce `tenant_id` filters.

**Tables with known isolation issues:**
- `nxt_bed` - 13 queries missing tenant_id
- `nxt_bill` - 8 queries missing tenant_id  
- `nxt_slip` - 8 queries missing tenant_id
- `nxt_user` - 8 queries missing tenant_id

**For production use**, these must be fixed. For testing tenant schema/flows, the default tenant works fine.

---

## Multi-Tenant Image Storage

### Overview

The HMS deployment uses **tenant-isolated folder structure** on the host for storing patient images, reports, X-rays, and other files. Each tenant's files are stored under a separate directory to ensure data isolation and security.

### Folder Structure

On the Contabo VM (or any host running the stack):

```
/opt/nxt-hms/images/
 ├── tenant_a/
 │    ├── patients/
 │    ├── reports/
 │    └── profile/
 ├── tenant_b/
 │    ├── patients/
 │    └── bills/
 └── tenant_c/
      └── xrays/
```

### How It Works

1. **Backend writes files** using `tenant_id` derived from subdomain/JWT (see `hms-backend/examples/tenant-aware-upload-example.js`)
2. **Nginx serves files** via `/images/` location with 30-day caching
3. **URLs are tenant-scoped**: `https://tenant.yourdomain.com/images/tenant_a/patients/xray_123.png`

### Security Rules

**❌ CRITICAL - DO NOT:**
- Accept `tenant_id` from request body or query parameters
- Allow cross-tenant file access via URL manipulation
- Store tenant files in a shared root folder

**✅ ALWAYS:**
- Derive `tenant_id` from `req.tenant_id` (set by `tenantMiddleware`)
- Validate file paths contain the current tenant's ID before deletion
- Use read-only mount for nginx (`/opt/nxt-hms/images:/usr/share/nginx/html/images:ro`)

### Migration from Single-Tenant Setup

If you have existing images in `/usr/share/nginx/html/images`, migrate them to the new structure:

```bash
# Create base directory
sudo mkdir -p /opt/nxt-hms/images

# Set ownership (adjust UID/GID to match container user)
sudo chown -R 1000:1000 /opt/nxt-hms/images

# Move existing images to default tenant folder
sudo rsync -av /usr/share/nginx/html/images/ /opt/nxt-hms/images/default_tenant/

# Verify structure
ls -la /opt/nxt-hms/images/

# Update database paths (if needed - adjust table/column names)
mysql -u root -p nxt-hospital -e "UPDATE nxt_patient SET patient_image = REPLACE(patient_image, '/images/', '/images/default_tenant/');"
```

After migration, restart the stack:

```bash
cd /opt/nxt-hms/nxt-hospital-skeleton-project
docker compose down
docker compose up -d
docker compose exec nginx nginx -s reload
```

### Backup Strategy

**Option 1: Daily tar.gz archive**

```bash
# Add to crontab
0 3 * * * tar -czf /backups/nxt-hms-images-$(date +\%F).tar.gz /opt/nxt-hms/images >> /var/log/image-backup.log 2>&1
```

**Option 2: Contabo disk snapshot**

Use Contabo panel to create weekly snapshots of the entire disk (recommended for production).

### When to Move to MinIO/S3

Consider migrating to object storage when:
- File sizes exceed 100GB total
- You need CDN integration
- Horizontal scaling across multiple backend servers
- DICOM images or video files (large medical imaging)

**Migration will be easy** because the folder structure (`<tenant_id>/category/file`) maps 1:1 to S3 object keys.

---

## Backend Implementation

See `hms-backend/examples/tenant-aware-upload-example.js` for complete code examples including:
- Multer configuration with tenant isolation
- Secure file upload controller
- File deletion with tenant verification
- Router setup with middleware

Key points:
- Always apply `tenantMiddleware` before upload routes
- Generate public URLs using `/images/<tenant_id>/...` format
- Validate tenant ownership before file deletion