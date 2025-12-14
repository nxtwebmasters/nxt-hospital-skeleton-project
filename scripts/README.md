# Deployment Scripts

Automation scripts for HMS deployment, verification, and multi-tenancy testing.

## Available Scripts

### 📋 Pre-Deployment

#### `pre-flight-check.sh`
Validates prerequisites before deployment.

**Usage:**
```bash
bash scripts/pre-flight-check.sh
```

**Checks:**
- Docker Engine installed and running
- Docker Compose v2 available
- Port 80/443 availability
- Required config files present
- Disk space and memory
- Configuration validation

**Exit Codes:**
- `0` = All checks passed, ready to deploy
- `1` = Some checks failed, fix issues first

---

### 🚀 Post-Deployment

#### `verify-deployment.sh`
Comprehensive health check after deployment.

**Usage:**
```bash
# After docker compose up -d
bash scripts/verify-deployment.sh
```

**Checks:**
- All 6 containers running
- HTTP endpoints responding
- MySQL connectivity
- Redis connectivity
- Tenant table initialized
- Multi-tenant schema ready

**Exit Codes:**
- `0` = Deployment healthy
- `1` = Issues detected, check logs

---

### 🧪 Multi-Tenancy Testing

#### `demo-multi-tenancy.sh`
Interactive demonstration of tenant isolation.

**Usage:**
```bash
bash scripts/demo-multi-tenancy.sh
```

**Demonstrates:**
1. Multi-tenant schema (50+ tables with tenant_id)
2. Creating multiple tenants
3. Inserting tenant-isolated data
4. Query isolation with/without tenant_id filters
5. Tenant data counts

**Creates Demo Data:**
- `tenant_demo_hospital_a` - Demo Hospital A
- `tenant_demo_clinic_b` - Demo Clinic B
- Test patients for each tenant

**Clean Up:**
```bash
# Remove demo data
docker exec hospital-mysql mysql -u nxt_user -pNxtWebMasters464 \
  -e "DELETE FROM nxt_patient WHERE patient_mrid LIKE 'MR-%-%'" nxt-hospital
docker exec hospital-mysql mysql -u nxt_user -pNxtWebMasters464 \
  -e "DELETE FROM nxt_tenant WHERE tenant_id LIKE 'tenant_demo_%'" nxt-hospital
```

---

### 🔐 TLS/HTTPS Setup

#### `obtain_wildcard_cert.sh`
Helper for obtaining Let's Encrypt wildcard certificates.

**Usage:**
```bash
sudo bash scripts/obtain_wildcard_cert.sh yourdomain.com you@email.com
```

**Process:**
1. Runs certbot in manual DNS mode
2. Prompts for TXT record creation
3. Validates certificates
4. Stores in `/etc/letsencrypt/`

**Requirements:**
- certbot installed (`apt install certbot`)
- DNS access to create TXT records
- Domain pointing to server IP

**After Success:**
```bash
# Enable HTTPS config
cd nginx/conf.d
mv reverse-proxy-https.conf.disabled reverse-proxy.conf
rm reverse-proxy-http.conf

# Reload nginx
docker compose restart nginx
```

---

## Common Workflows

### First-Time Deployment
```bash
# 1. Pre-flight check
bash scripts/pre-flight-check.sh

# 2. Deploy
docker compose up -d

# 3. Wait for initialization
sleep 30

# 4. Verify
bash scripts/verify-deployment.sh

# 5. Test multi-tenancy
bash scripts/demo-multi-tenancy.sh
```

### Troubleshooting Deployment Issues
```bash
# Run health check with detailed output
bash scripts/verify-deployment.sh

# Check specific service
docker compose logs api-hospital

# Restart services
docker compose restart

# Full rebuild
docker compose down -v
docker compose up -d --build
```

### Production Migration (HTTP → HTTPS)
```bash
# 1. Obtain certificates
sudo bash scripts/obtain_wildcard_cert.sh yourdomain.com admin@yourdomain.com

# 2. Enable HTTPS nginx config
cd nginx/conf.d
mv reverse-proxy-https.conf.disabled reverse-proxy.conf
rm reverse-proxy-http.conf

# 3. Update docker-compose.yml (mount certs)
# Already configured: - /etc/letsencrypt:/etc/letsencrypt:ro

# 4. Reload nginx
docker compose restart nginx

# 5. Verify HTTPS
curl -I https://yourdomain.com/nginx-health
```

---

## Script Permissions

Make scripts executable:
```bash
chmod +x scripts/*.sh
```

Or run with bash explicitly:
```bash
bash scripts/verify-deployment.sh
```

---

## Environment Variables

Scripts use these defaults (from docker-compose.yml):

```bash
DB_USER="nxt_user"
DB_PASS="NxtWebMasters464"
DB_NAME="nxt-hospital"
MYSQL_CONTAINER="hospital-mysql"
REDIS_CONTAINER="hospital-redis"
```

To customize, edit the scripts or set environment variables:
```bash
export DB_USER="custom_user"
bash scripts/verify-deployment.sh
```

---

## Continuous Integration

Example CI/CD pipeline:

```yaml
# .github/workflows/deploy.yml
name: Deploy HMS
on: [push]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Pre-flight check
        run: bash scripts/pre-flight-check.sh
      
      - name: Deploy
        run: docker compose up -d
      
      - name: Wait for initialization
        run: sleep 30
      
      - name: Verify deployment
        run: bash scripts/verify-deployment.sh
      
      - name: Test multi-tenancy
        run: bash scripts/demo-multi-tenancy.sh
```

---

## Support

If scripts fail:
1. Check logs: `docker compose logs`
2. Verify prerequisites: `bash scripts/pre-flight-check.sh`
3. Check container status: `docker compose ps`
4. Review README.md and QUICK_START.md
