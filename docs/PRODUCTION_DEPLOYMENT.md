# Production Deployment Guide — Ubuntu VM (Contabo)

Complete step-by-step guide to deploy NXT HMS multi-tenant solution on a clean Ubuntu VM with Docker, Docker Compose, and Git already installed.

---

## Prerequisites Verification

Before starting, verify your VM setup:

```bash
# Check installed versions
docker --version          # Should be Docker 20.10+ or 24.x+
docker compose version    # Should be Docker Compose v2.x+
git --version            # Any recent version

# Check available disk space (need at least 20GB free)
df -h

# Check available RAM (recommended: 4GB+, minimum: 2GB)
free -h

# Check if ports 80 and 443 are available
sudo netstat -tlnp | grep -E ':80|:443'
```

**If ports are occupied:** Stop conflicting services (Apache, nginx, etc.):
```bash
sudo systemctl stop apache2  # or nginx
sudo systemctl disable apache2
```

---

## Phase 1: Initial VM Setup (5 minutes)

### 1.1 Update System & Install Dependencies

```bash
# Update package lists
sudo apt update

# Install essential utilities
sudo apt install -y curl wget nano htop net-tools ufw

# Install certbot for SSL (if planning HTTPS)
sudo apt install -y certbot
```

### 1.2 Configure Firewall (UFW)

```bash
# Enable firewall with SSH, HTTP, HTTPS access
sudo ufw allow 22/tcp      # SSH
sudo ufw allow 80/tcp      # HTTP
sudo ufw allow 443/tcp     # HTTPS
sudo ufw enable
sudo ufw status
```

### 1.3 Configure Docker User Permissions

```bash
# Add your user to docker group (to run docker without sudo)
sudo usermod -aG docker $USER

# Apply group changes (logout/login or use newgrp)
newgrp docker

# Verify docker works without sudo
docker ps
```

---

## Phase 2: Clone & Configure Repository (10 minutes)

### 2.1 Clone the Repository

```bash
# Navigate to deployment directory (choose your preferred location)
cd /opt  # or ~/projects or /var/www

# Clone the repository
sudo git clone https://github.com/your-org/nxt-hospital-skeleton-project.git
cd nxt-hospital-skeleton-project

# Set proper ownership (replace 'ubuntu' with your username if different)
sudo chown -R $USER:$USER /opt/nxt-hospital-skeleton-project
```

### 2.2 Create Images Directory

```bash
# Create images folder for tenant file storage
mkdir -p images
chmod 755 images

# Run cleanup script to prepare for production
chmod +x scripts/cleanup-for-production.sh
./scripts/cleanup-for-production.sh
```

### 2.3 Configure Environment Variables

**Critical:** Update `hms-backend.env` with production values:

```bash
# Edit environment file
nano hms-backend.env
```

**Required Changes for Production:**

```dotenv
# === SECURITY: Change ALL passwords and secrets ===
JWT_SECRET=<GENERATE_NEW_SECRET_256bit>

# MySQL credentials (must match docker-compose.yml)
MYSQL_ROOT_PASSWORD=<STRONG_ROOT_PASSWORD>
DB_PASSWORD=<STRONG_DB_PASSWORD>

# Email Configuration (use your SMTP)
EMAIL_USER=your-production-email@domain.com
EMAIL_PASSWORD=<APP_SPECIFIC_PASSWORD>
EMAIL_RECIPIENTS=["admin@yourhospital.com"]

# File Server URL (use your domain or VM IP)
FILE_SERVER_URL=https://yourhospital.com/images  # or http://YOUR_VM_IP/images

# CORS Configuration (add your domains)
ALLOWED_ORIGINS=["https://yourhospital.com","https://www.yourhospital.com"]

# === Optional: External Integrations ===
# FBR Integration (Pakistan Tax)
FBR_INTEGRATION_ENABLED=false  # Set true when ready with credentials

# WhatsApp Business API
ENABLE_WHATSAPP=true
MSGPK_WHATSAPP_API_KEY=<YOUR_KEY>

# OpenAI (for AI suggestions)
ENABLE_AI_SUGGESTION=false  # Set true when ready
OPENAI_API_KEY=<YOUR_KEY>
```

**Generate Strong Secrets:**
```bash
# Generate JWT secret (256-bit)
openssl rand -hex 32

# Generate strong passwords
openssl rand -base64 24
```

### 2.4 Update Docker Compose for Production

Edit `docker-compose.yml`:

```bash
nano docker-compose.yml
```

**Update MySQL passwords to match `hms-backend.env`:**

```yaml
  mysql:
    environment:
      MYSQL_ROOT_PASSWORD: "<YOUR_STRONG_ROOT_PASSWORD>"
      MYSQL_PASSWORD: "<YOUR_STRONG_DB_PASSWORD>"
```

**IMPORTANT:** Passwords in `docker-compose.yml` and `hms-backend.env` **MUST match**.

---

## Phase 3: First Deployment (15 minutes)

### 3.1 Pull Docker Images

```bash
# Pre-pull images to avoid timeout during startup
docker compose pull
```

**Expected output:**
```
✔ hospital-frontend Pulled
✔ patient-frontend Pulled
✔ hospital-apis Pulled
✔ mysql Pulled
✔ redis Pulled
✔ nginx Pulled
```

### 3.2 Start the Stack

```bash
# Start all services in detached mode
docker compose up -d

# Monitor startup logs (Ctrl+C to exit, containers keep running)
docker compose logs -f
```

**Watch for these success indicators:**
- ✅ MySQL: `mysqld: ready for connections`
- ✅ Redis: `Ready to accept connections`
- ✅ Backend API: `Server is listening on port 80`
- ✅ Nginx: `start worker processes`

**Startup typically takes 30-60 seconds.**

### 3.3 Verify Deployment

```bash
# Check all containers are running
docker compose ps

# Should show all services as "Up" and healthy:
# - nginx-reverse-proxy    Up      0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp
# - api-hospital           Up      (healthy)
# - nxt-hospital           Up
# - portal-hospital        Up
# - hospital-mysql         Up      (healthy)
# - hospital-redis         Up      (healthy)
```

```bash
# Run validation script
chmod +x scripts/check_images_and_nginx.sh
./scripts/check_images_and_nginx.sh
```

**Expected output:**
```
✓ Images directory exists and is writable
✓ Test file created: images/.agent-check/hello.txt
✓ Nginx is serving files correctly: http://localhost/images/.agent-check/hello.txt
```

### 3.4 Test System Health

```bash
# Test API health endpoint
curl http://localhost/api-server/health

# Expected: {"status":"ok","timestamp":"..."}

# Test nginx health
curl http://localhost/nginx-health

# Expected: nginx OK

# Test frontend (should return HTML)
curl -I http://localhost/

# Expected: HTTP/1.1 200 OK
```

---

## Phase 4: Database Initialization & Verification (5 minutes)

### 4.1 Verify Database Schema

```bash
# Connect to MySQL
docker exec -it hospital-mysql mysql -u nxt_user -p<YOUR_DB_PASSWORD> nxt-hospital

# Inside MySQL, run:
SHOW TABLES;
# Should show 58+ tables (patients, appointments, billing, etc.)

SELECT COUNT(*) FROM information_schema.tables 
WHERE table_schema = 'nxt-hospital';
# Should return ~58-60

# Check default tenant exists
SELECT * FROM nxt_tenant WHERE tenant_subdomain = 'hms';
# Should show system_default_tenant with subdomain='hms'

# Exit MySQL
EXIT;
```

### 4.2 Verify Initial Data Seeding

```bash
# Check users table
docker exec -it hospital-mysql mysql -u nxt_user -p<YOUR_DB_PASSWORD> nxt-hospital -e "SELECT COUNT(*) as user_count FROM nxt_users;"

# Check departments
docker exec -it hospital-mysql mysql -u nxt_user -p<YOUR_DB_PASSWORD> nxt-hospital -e "SELECT COUNT(*) as dept_count FROM nxt_department;"
```

---

## Phase 5: Access & First Login (5 minutes)

### 5.1 Get VM Public IP

```bash
# Get your VM's public IP
curl -4 ifconfig.me
# Example output: 203.0.113.45
```

### 5.2 Access the System

Open your browser and navigate to:

- **Admin Panel:** `http://YOUR_VM_IP/`
- **Patient Portal:** `http://YOUR_VM_IP/portal/`
- **API Health:** `http://YOUR_VM_IP/api-server/health`

### 5.3 Default Login Credentials

Check your database for default user or create one:

```bash
# List users
docker exec -it hospital-mysql mysql -u nxt_user -p<YOUR_DB_PASSWORD> nxt-hospital -e "SELECT user_name, user_permission FROM nxt_users WHERE user_permission='admin' LIMIT 1;"
```

**If no admin exists, create one:**
```bash
# The backend will hash the password on first login
# Insert admin user with a temporary plain password (backend will hash it)
docker exec -it hospital-mysql mysql -u nxt_user -p<YOUR_DB_PASSWORD> nxt-hospital -e "
INSERT INTO nxt_users (user_name, user_username, user_password, user_permission, tenant_id, created_at, created_by) 
VALUES ('System Admin', 'admin', 'ChangeMe123!', 'admin', 'system_default_tenant', NOW(), 'setup_script');
"
```

**Note:** Change the password immediately after first login via the UI.

---

## Phase 6: Production Hardening (15 minutes)

### 6.1 Enable HTTPS with Let's Encrypt (Recommended)

**Prerequisites:**
- Domain name pointing to your VM IP (e.g., `hms.yourhospital.com`)
- Port 80 open for Let's Encrypt validation

```bash
# Obtain SSL certificate
sudo certbot certonly --standalone -d hms.yourhospital.com

# Certificates will be saved to: /etc/letsencrypt/live/hms.yourhospital.com/
```

**Enable HTTPS in nginx:**

```bash
# Check if HTTPS config exists
ls nginx/conf.d/reverse-proxy-https.conf.disabled

# If it exists, enable it (rename)
cd nginx/conf.d
mv reverse-proxy-https.conf.disabled reverse-proxy-https.conf

# Edit and update server_name
nano reverse-proxy-https.conf
```

**Update:**
```nginx
server_name hms.yourhospital.com;

ssl_certificate /etc/letsencrypt/live/hms.yourhospital.com/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/hms.yourhospital.com/privkey.pem;
```

**Disable HTTP-only config and restart:**
```bash
mv reverse-proxy-http.conf reverse-proxy-http.conf.disabled

# Go back to repo root
cd /opt/nxt-hospital-skeleton-project

# Restart nginx
docker compose restart nginx
docker compose exec nginx nginx -t
```

### 6.2 Setup Automatic Certificate Renewal

```bash
# Test renewal
sudo certbot renew --dry-run

# Add cron job for auto-renewal
sudo crontab -e

# Add this line (runs daily at 2 AM):
0 2 * * * certbot renew --quiet --deploy-hook "docker compose -f /opt/nxt-hospital-skeleton-project/docker-compose.yml restart nginx"
```

### 6.3 Configure Backups

**Database Backup Script:**

```bash
# Create backup directory
sudo mkdir -p /opt/hms-backups

# Create backup script
sudo nano /usr/local/bin/hms-backup.sh
```

**Add:**
```bash
#!/bin/bash
BACKUP_DIR="/opt/hms-backups"
DATE=$(date +%Y%m%d_%H%M%S)
CONTAINER="hospital-mysql"
DB_USER="nxt_user"
DB_PASS="<YOUR_DB_PASSWORD>"
DB_NAME="nxt-hospital"
PROJECT_DIR="/opt/nxt-hospital-skeleton-project"

mkdir -p "$BACKUP_DIR"

# Backup database
docker exec $CONTAINER mysqldump -u $DB_USER -p$DB_PASS $DB_NAME | gzip > "$BACKUP_DIR/db_$DATE.sql.gz"

# Backup images folder
tar -czf "$BACKUP_DIR/images_$DATE.tar.gz" -C "$PROJECT_DIR" images/

# Keep only last 7 days of backups
find "$BACKUP_DIR" -type f -mtime +7 -delete

echo "Backup completed: $DATE"
```

```bash
# Make executable
sudo chmod +x /usr/local/bin/hms-backup.sh

# Test it
sudo /usr/local/bin/hms-backup.sh

# Add to crontab (daily at 3 AM)
sudo crontab -e
# Add:
0 3 * * * /usr/local/bin/hms-backup.sh >> /var/log/hms-backup.log 2>&1
```

### 6.4 Setup Monitoring

```bash
# Install monitoring tools
sudo apt install -y htop iotop

# Monitor docker containers
docker stats  # Real-time resource usage (Ctrl+C to exit)
```

**Create health check script:**
```bash
sudo nano /usr/local/bin/hms-health-check.sh
```

**Add:**
```bash
#!/bin/bash
PROJECT_DIR="/opt/nxt-hospital-skeleton-project"
LOG_FILE="/var/log/hms-health.log"

# Check if all containers are running
cd "$PROJECT_DIR"
RUNNING=$(docker compose ps -q | wc -l)
EXPECTED=6

if [ "$RUNNING" -lt "$EXPECTED" ]; then
    echo "$(date): ALERT - Only $RUNNING/$EXPECTED containers running. Restarting..." >> "$LOG_FILE"
    docker compose up -d >> "$LOG_FILE" 2>&1
fi

# Check API health
if ! curl -f http://localhost/api-server/health > /dev/null 2>&1; then
    echo "$(date): ALERT - API health check failed" >> "$LOG_FILE"
    docker compose restart hospital-apis >> "$LOG_FILE" 2>&1
fi
```

```bash
sudo chmod +x /usr/local/bin/hms-health-check.sh

# Run every 5 minutes
sudo crontab -e
# Add:
*/5 * * * * /usr/local/bin/hms-health-check.sh
```

---

## Phase 7: Multi-Tenant Setup (Optional, 10 minutes)

### 7.1 Create a New Tenant

```bash
# Connect to database
docker exec -it hospital-mysql mysql -u nxt_user -p<YOUR_DB_PASSWORD> nxt-hospital
```

**Run SQL:**
```sql
-- Insert new tenant
INSERT INTO nxt_tenant (
    tenant_id, 
    tenant_name, 
    tenant_subdomain, 
    tenant_status,
    subscription_plan,
    features,
    created_at,
    created_by
) VALUES (
    'tenant_hospital_a',
    'Hospital A',
    'hospitala',
    'active',
    'basic',
    '{"fbr":false,"campaigns":true}',
    NOW(),
    'admin'
);

-- Add tenant configurations
INSERT INTO nxt_tenant_config (tenant_id, config_key, config_value, config_type) VALUES
('tenant_hospital_a','hospital_name','Hospital A','string'),
('tenant_hospital_a','timezone','Asia/Karachi','string'),
('tenant_hospital_a','currency','PKR','string');

-- Verify
SELECT * FROM nxt_tenant WHERE tenant_id = 'tenant_hospital_a';

EXIT;
```

### 7.2 Verify Tenant Isolation

```bash
# Images folder should auto-create on first upload
ls -la images/
# Should show: system_default_tenant/

# After first file upload from new tenant:
# ls -la images/tenant_hospital_a/
# Will auto-create with proper structure
```

---

## Phase 8: Operations & Maintenance

### 8.1 Common Management Commands

```bash
# View logs
docker compose logs -f hospital-apis    # Backend logs
docker compose logs -f hospital-mysql   # Database logs
docker compose logs -f nginx            # Proxy logs
docker compose logs --tail=100          # Last 100 lines all services

# Restart specific service
docker compose restart hospital-apis

# Stop entire stack (keeps data)
docker compose down

# Start stack
docker compose up -d

# Update to latest images (when new versions released)
docker compose pull
docker compose up -d

# Clean up unused resources (be careful!)
docker system prune -a --volumes  # REMOVES EVERYTHING UNUSED
```

### 8.2 Database Maintenance

```bash
# Backup database manually
docker exec hospital-mysql mysqldump -u nxt_user -p<PASSWORD> nxt-hospital > backup_$(date +%Y%m%d).sql

# Restore database
cat backup_20260103.sql | docker exec -i hospital-mysql mysql -u nxt_user -p<PASSWORD> nxt-hospital

# Optimize tables (run monthly)
docker exec -it hospital-mysql mysql -u nxt_user -p<PASSWORD> nxt-hospital -e "
OPTIMIZE TABLE nxt_patient, nxt_appointment, nxt_bill, nxt_slip;
"

# Check database size
docker exec -it hospital-mysql mysql -u nxt_user -p<PASSWORD> nxt-hospital -e "
SELECT 
    table_schema AS 'Database',
    ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size (MB)'
FROM information_schema.tables 
WHERE table_schema = 'nxt-hospital'
GROUP BY table_schema;
"
```

### 8.3 Performance Tuning

**Increase MySQL connection pool (if needed):**

Edit `hms-backend.env`:
```dotenv
DB_CONNECTION_LIMIT=20  # Increase from 10 for high load
```

**Increase nginx worker processes:**

Edit `nginx/nginx.conf`:
```nginx
worker_processes auto;  # Use all CPU cores
worker_connections 2048;  # Increase from default
```

**Restart services:**
```bash
docker compose restart hospital-apis nginx
```

### 8.4 Troubleshooting

**Container won't start:**
```bash
docker compose logs <service-name>
docker compose ps -a
docker inspect <container-name>
```

**Database connection issues:**
```bash
# Check MySQL is accessible
docker exec -it hospital-mysql mysql -u nxt_user -p<PASSWORD> nxt-hospital -e "SELECT 1;"

# Check network connectivity
docker compose exec hospital-apis ping -c 3 mysql

# Restart both services
docker compose restart hospital-mysql hospital-apis
```

**Images not loading (404 errors):**
```bash
# Check images mount inside containers
docker compose exec nginx ls -la /usr/share/nginx/html/images/
docker compose exec hospital-apis ls -la /usr/share/nginx/html/images/

# Check host permissions
ls -la images/
sudo chown -R $USER:$USER images/
chmod -R 755 images/

# Check nginx config
docker compose exec nginx nginx -t
docker compose restart nginx

# Test direct file access
curl -I http://localhost/images/.agent-check/hello.txt
```

**High memory usage:**
```bash
# Check resource usage
docker stats --no-stream

# Identify memory hogs
docker stats --format "table {{.Container}}\t{{.MemUsage}}" --no-stream

# Restart services to clear memory
docker compose restart
```

**Port conflicts:**
```bash
# Check what's using ports 80/443
sudo netstat -tlnp | grep -E ':80|:443'
sudo lsof -i :80
sudo lsof -i :443

# Stop conflicting services
sudo systemctl stop apache2 nginx
```

---

## Phase 9: Production Checklist

Before going live, verify:

**Security:**
- [ ] All passwords changed from defaults in `docker-compose.yml` and `hms-backend.env`
- [ ] `JWT_SECRET` regenerated for production (256-bit random)
- [ ] HTTPS enabled with valid SSL certificate
- [ ] Firewall configured (UFW enabled, only ports 22/80/443 open)
- [ ] Database not exposed to public network (internal-net only)
- [ ] Redis not exposed to public network

**Backup & Recovery:**
- [ ] Automated database backups running (daily at minimum)
- [ ] Automated images folder backups configured
- [ ] Backup retention policy set (7 days minimum)
- [ ] Restore procedure tested at least once
- [ ] Off-site backup copy configured (optional but recommended)

**Monitoring:**
- [ ] Health check script running (every 5 minutes)
- [ ] Log rotation configured for docker logs
- [ ] Disk space monitoring in place
- [ ] Alert mechanism configured (email or SMS)

**Configuration:**
- [ ] Certificate auto-renewal configured and tested
- [ ] Domain name configured and DNS propagated
- [ ] Email SMTP configured and tested
- [ ] File server URL set correctly (domain or IP)
- [ ] CORS origins configured for your domains
- [ ] Timezone set correctly in `hms-backend.env`

**Application:**
- [ ] Default admin user created with secure password
- [ ] Admin password changed from temporary value
- [ ] Images folder exists and has correct permissions (755)
- [ ] Database schema verified (58+ tables)
- [ ] Default tenant exists in database
- [ ] All containers running and healthy
- [ ] API health endpoint returns OK

**Performance:**
- [ ] Database connection limits appropriate for expected load
- [ ] Nginx worker processes configured
- [ ] Redis memory limits set (if high traffic expected)
- [ ] MySQL query cache configured

**Optional (Multi-tenant):**
- [ ] All external integrations tested (FBR, WhatsApp, OpenAI)
- [ ] Multi-tenant subdomain routing configured (if using)
- [ ] Wildcard SSL certificate obtained (if using subdomains)
- [ ] Tenant isolation verified (file uploads, database queries)

---

## Quick Reference

### Service URLs (After Deployment)

- **Admin Panel:** `http://YOUR_VM_IP/` or `https://hms.yourdomain.com/`
- **Patient Portal:** `http://YOUR_VM_IP/portal/`
- **API Health:** `http://YOUR_VM_IP/api-server/health`
- **Nginx Health:** `http://YOUR_VM_IP/nginx-health`
- **Images:** `http://YOUR_VM_IP/images/<tenant_id>/<category>/file.png`

### Container Names

- `nginx-reverse-proxy` — Reverse proxy & static file server
- `api-hospital` — Backend API (Node.js)
- `nxt-hospital` — Admin frontend (Angular)
- `portal-hospital` — Patient portal (Angular)
- `hospital-mysql` — Database (MySQL)
- `hospital-redis` — Cache & sessions (Redis)

### Important Directories

- `/opt/nxt-hospital-skeleton-project/` — Application root
- `/opt/nxt-hospital-skeleton-project/images/` — Tenant file storage
- `/opt/hms-backups/` — Backup storage
- `/etc/letsencrypt/live/` — SSL certificates
- `/var/log/` — System and application logs

### Key Files

- `docker-compose.yml` — Service orchestration
- `hms-backend.env` — Backend configuration
- `nginx/conf.d/reverse-proxy-*.conf` — Routing rules
- `data/scripts/` — Database initialization SQL
- `images/` — Tenant file storage (bind mount)

### Useful Commands

```bash
# Quick health check
docker compose ps
curl http://localhost/api-server/health

# View recent logs
docker compose logs --tail=50 hospital-apis

# Restart everything
docker compose restart

# Update to latest code
cd /opt/nxt-hospital-skeleton-project
git pull
docker compose pull
docker compose up -d

# Database console
docker exec -it hospital-mysql mysql -u nxt_user -p<PASSWORD> nxt-hospital

# Backup now
sudo /usr/local/bin/hms-backup.sh

# Check disk space
df -h
du -sh /opt/nxt-hospital-skeleton-project/images/
```

---

## Troubleshooting: 404 Tenant Resolution Errors

### Problem: After Login, All API Calls Return 404 "Hospital not found"

**Symptoms:**
- Login works successfully
- Browser console shows multiple 404 errors
- Error message: "Hospital not found. Please check the URL or contact support."
- Dashboard widgets don't load

**Root Cause:**
The multi-tenant system extracts a subdomain from your domain to identify the tenant. For `hms.nxtwebmasters.com`, it extracts `'hms'` as the subdomain, but the database might have `subdomain='default'` causing a mismatch.

**Quick Fix:**

```bash
# 1. Check debug endpoint
curl https://hms.nxtwebmasters.com/api-server/tenant/debug

# Should show:
# "extractedSubdomain": "hms"
# "tenantFound": true

# 2. If tenantFound is false, fix database:
docker exec -i hospital-mysql mysql -u nxt_user -pNxtWebMasters464 nxt-hospital <<EOF
UPDATE nxt_tenant 
SET tenant_subdomain = 'hms' 
WHERE tenant_id = 'system_default_tenant';

SELECT tenant_id, tenant_subdomain, tenant_status 
FROM nxt_tenant 
WHERE tenant_id = 'system_default_tenant';
EOF

# 3. Clear Redis cache
docker exec -i hospital-redis redis-cli -n 2 FLUSHDB

# 4. Restart backend
docker compose restart hms-backend

# 5. Verify fix
curl https://hms.nxtwebmasters.com/api-server/tenant/debug
# Now tenantFound should be true
```

**Environment Configuration:**
Ensure `hms-backend.env` has:
```bash
BASE_SUBDOMAIN=hms
```

**Domain Structure:**
- Base domain: `hms.nxtwebmasters.com` → subdomain: `'hms'`
- New tenants: `hospital1-hms.nxtwebmasters.com` → subdomain: `'hospital1-hms'`

For more details, see the main repository's [PRODUCTION_DEPLOYMENT_FIX.md](../../docs/PRODUCTION_DEPLOYMENT_FIX.md).

---

## Support & Documentation

- **Main README:** `README.md`
- **AI Agent Instructions:** `.github/copilot-instructions.md`
- **Tenant Onboarding:** `docs/TENANT_ONBOARDING.md`
- **Nginx Configuration:** `nginx/conf.d/README.md`

---

## Time Estimate Summary

| Phase | Task | Time |
|-------|------|------|
| 1 | VM Setup & Dependencies | 5 min |
| 2 | Clone & Configure | 10 min |
| 3 | First Deployment | 15 min |
| 4 | Database Verification | 5 min |
| 5 | Access & Login | 5 min |
| 6 | Production Hardening | 15 min |
| 7 | Multi-Tenant Setup (Optional) | 10 min |
| 8 | Testing & Validation | 10 min |
| **Total** | **Basic Production Deploy** | **45-60 min** |
| **Total** | **With HTTPS & Full Hardening** | **75-90 min** |

---

**You're now production-ready!** 🚀

For ongoing questions or issues, refer to the troubleshooting section or review container logs with `docker compose logs -f`.
