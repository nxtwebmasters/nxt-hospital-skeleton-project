# 🚀 HMS Automated Deployment Guide
## Complete Step-by-Step Walkthrough Using deploy.sh

---

## 📋 Table of Contents
1. [Pre-Deployment Requirements](#pre-deployment-requirements)
2. [DNS Configuration](#dns-configuration)
3. [Initial Server Setup](#initial-server-setup)
4. [Running the Deployment Script](#running-the-deployment-script)
5. [Interactive Prompts Guide](#interactive-prompts-guide)
6. [SSL Certificate Setup](#ssl-certificate-setup)
7. [Post-Deployment Configuration](#post-deployment-configuration)
8. [Creating Your First Tenant](#creating-your-first-tenant)
9. [Testing & Verification](#testing--verification)
10. [Troubleshooting](#troubleshooting)

---

## 📋 Pre-Deployment Requirements

### Server Requirements
- **OS:** Ubuntu 20.04+ or Debian-based Linux
- **RAM:** Minimum 4GB (8GB recommended)
- **Disk:** Minimum 40GB free space
- **CPU:** 2+ cores recommended
- **Network:** Public IP address with ports 22, 80, 443 accessible
- **Access:** Root or sudo user privileges

### Domain Requirements
- Domain name registered (e.g., `yourdomain.com`)
- Access to DNS management (cPanel, Cloudflare, etc.)
- Ability to add A records and TXT records

### Required Tools
- SSH client (PuTTY, Terminal, etc.)
- Git installed on server
- Docker and Docker Compose (script will install if missing)

---

## 🌐 DNS Configuration

### Step 1: Login to Your DNS Provider
Example: Hoster.pk cPanel, Cloudflare, etc.

### Step 2: Add DNS Records

**Replace with your values:**
- Base domain: `hms.yourdomain.com`
- Your VM IP: `YOUR_VM_IP`

**Required DNS Records:**

| Type | Name/Host | Value | TTL |
|------|-----------|-------|-----|
| A | `hms` | `YOUR_VM_IP` | 300 |
| A | `*.hms` | `YOUR_VM_IP` | 300 |
| A (optional) | `www.hms` | `YOUR_VM_IP` | 300 |

**Example for hms.nxtwebmasters.com:**
```
A    hms.nxtwebmasters.com           → 38.242.156.146
A    *.hms.nxtwebmasters.com         → 38.242.156.146
A    www.hms.nxtwebmasters.com       → 38.242.156.146
```

### Step 3: Verify DNS Propagation

Wait 5-15 minutes, then test:
```bash
# Test base domain
dig hms.yourdomain.com +short

# Test wildcard
dig hospital-a.hms.yourdomain.com +short
dig test.hms.yourdomain.com +short
```

All should return your VM IP address.

### Step 4: Disable Force HTTPS in cPanel (CRITICAL)

If using cPanel:
1. Go to **Domains** → **Manage**
2. Find subdomain: `hms.yourdomain.com`
3. **Turn OFF** "Force HTTPS Redirect"
4. Save changes

⚠️ **Why?** Our nginx will handle HTTPS redirects properly. cPanel's force redirect interferes with Let's Encrypt validation.

---

## 🔧 Initial Server Setup

### Step 1: Connect to Your Server

```bash
ssh root@YOUR_VM_IP
# OR
ssh root@your-server-hostname
```

### Step 2: Update System

```bash
apt update && apt upgrade -y
```

### Step 3: Install Docker & Docker Compose

```bash
# Quick install with official script
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Install Docker Compose plugin
apt install -y docker-compose-plugin

# Verify installation
docker --version
docker compose version

# Enable Docker service
systemctl enable docker
systemctl start docker
```

### Step 4: Install Git

```bash
apt install -y git
```

### Step 5: Clone Repository

```bash
cd ~
git clone https://github.com/YOUR_USERNAME/nxt-hospital-skeleton-project.git
cd nxt-hospital-skeleton-project
```

---

## 🚀 Running the Deployment Script

### Step 1: Make Script Executable

```bash
chmod +x deploy.sh
```

### Step 2: Start Deployment

```bash
./deploy.sh
```

The script will now guide you through the entire deployment process with interactive prompts.

---

## 💬 Interactive Prompts Guide

The deploy.sh script will ask you a series of questions. Here's what to expect and how to answer:

---

### **Phase 1: Pre-flight Checks**

**Banner Display:**
```
╔══════════════════════════════════════════════════════════╗
║        🏥 NXT HMS - Production Deployment 🏥             ║
║              Automated Setup Script v2.0                 ║
╚══════════════════════════════════════════════════════════╝

This script will deploy your HMS application automatically.

⏱️  Estimated time: 10-15 minutes
📝 Log file: deployment_YYYYMMDD_HHMMSS.log
```

**Prompt 1: Ready to begin deployment?**
```
Ready to begin deployment? (y/n): 
```
✅ **Answer:** `y`

**Automatic Checks:**
- ✓ Docker and Docker Compose installed
- ✓ Disk space (minimum 20GB)
- ✓ RAM (minimum 2GB)
- ✓ Ports 80 and 443 available

**If ports are in use:**
```
Ports 80 or 443 are already in use
Attempt to stop conflicting services (apache2/nginx)? (y/n):
```
✅ **Answer:** `y` (to stop Apache/nginx if running)

---

### **Phase 2: System Setup**

**Prompt 2: Configure UFW Firewall**
```
Configure UFW firewall (allow SSH, HTTP, HTTPS)? (y/n):
```
✅ **Answer:** `y` (recommended for security)

**What it does:**
- Opens port 22 (SSH)
- Opens port 80 (HTTP)
- Opens port 443 (HTTPS)
- Enables UFW firewall

---

### **Phase 3: Setup Directories**

Automatic - creates `images/` directory for file storage.

---

### **Phase 4: Environment Configuration**

**Prompt 3: Domain/IP Configuration**
```
Your VM IP: XX.XX.XX.XX
Enter your domain name (or press Enter to use VM IP):
```
✅ **Answer:** `hms.yourdomain.com`

**Example:**
```
Your VM IP: 38.242.156.146
Enter your domain name (or press Enter to use VM IP): hms.nxtwebmasters.com
```

---

**Prompt 4: SMTP Email Configuration**
```
SMTP Email (e.g., admin@yourdomain.com):
```
✅ **Answer:** Your email address for notifications

**Example:** `admin@yourdomain.com`

---

**Prompt 5: SMTP Password**
```
SMTP Password/App Key:
```
✅ **Answer:** Your email password or Gmail App Password

**For Gmail:**
1. Enable 2-Factor Authentication
2. Generate App Password: https://myaccount.google.com/apppasswords
3. Use that 16-character password

⚠️ **Note:** Password will be hidden while typing

---

**Prompt 6: Admin Email Recipients**
```
Admin Email Recipients (comma-separated, e.g., admin@domain.com,support@domain.com):
```
✅ **Answer:** 
- Press Enter to use SMTP email as default
- OR enter multiple emails: `admin@domain.com,support@domain.com`

---

**Automatic Security Configuration:**
The script will now:
- ✓ Generate secure MySQL root password
- ✓ Generate secure MySQL database password
- ✓ Generate secure JWT secret

**Display:**
```
✓ Generated secure credentials:
  - MySQL Root Password: xxxxxxxx...
  - MySQL DB Password:   xxxxxxxx...
  - JWT Secret:          xxxxxxxx...
```

⚠️ **Important:** These are saved to `/root/.hms_credentials_YYYYMMDD.txt`

---

**Prompt 7: WhatsApp Integration**
```
Enable WhatsApp integration now? (y/n):
```
✅ **Recommended Answer:** `n` (configure later if needed)

If you answer `y`:
```
WhatsApp API Key:
```
Enter your msgpk.com API key.

---

**Prompt 8: OpenAI Integration**
```
Enable OpenAI integration now? (y/n):
```
✅ **Recommended Answer:** `n` (configure later if needed)

If you answer `y`:
```
OpenAI API Key:
```
Enter your OpenAI API key.

---

**Prompt 9: Continue Deployment**
```
✓ Credentials saved to: /root/.hms_credentials_YYYYMMDD.txt

Press Enter to continue with deployment...
```
✅ **Action:** Press `Enter`

---

### **Phase 5: Application Deployment**

**Automatic Process:**
```
Pulling Docker images (this may take 5-10 minutes)...
```

**6 Docker images will be pulled:**
1. `nginx:1.25` - Reverse proxy
2. `mysql:latest` - Database
3. `redis:7.2` - Cache/sessions
4. `pandanxt/hospital-frontend` - Admin panel
5. `pandanxt/customer-portal` - Patient portal
6. `pandanxt/hms-backend-apis` - Backend API

**Then:**
```
Starting Docker containers...
This may take 5-10 minutes on first run (MySQL schema initialization)...
```

**Live Progress Display:**
```
[1/24] Containers running: 4/6  ⏳ Initializing...
[2/24] Containers running: 4/6  ⏳ Initializing...
[3/24] Containers running: 5/6  ⏳ Initializing...
...
[12/24] Containers running: 6/6  ✓ MySQL ready
```

**What's happening:**
- MySQL is creating 50+ database tables
- Redis is starting up
- Backend API is waiting for MySQL
- Nginx is waiting for backend API

⏱️ **Expected time:** 5-10 minutes on first run

**Container Status Display:**
```
Container Status:
─────────────────────────────────────────
NAME                  STATUS              PORTS
nginx-reverse-proxy   Up (healthy)        0.0.0.0:80->80/tcp
api-hospital          Up (healthy)        80/tcp
nxt-hospital          Up                  80/tcp
portal-hospital       Up                  80/tcp
hospital-mysql        Up (healthy)        3306/tcp
hospital-redis        Up (healthy)        6379/tcp
```

---

### **Phase 6: Deployment Verification**

**Automatic checks:**
- ✓ All 6 containers running
- ✓ MySQL database ready (50+ tables)
- ✓ Nginx health check passed
- ✓ Backend API health check passed

---

### **Phase 7: Production Hardening**

**Prompt 10: Automated Backups**
```
Setup automated backups and health checks (recommended)? (y/n):
```
✅ **Answer:** `y`

**What it creates:**
- Daily database backups at 3:00 AM
- Health checks every 5 minutes
- Backup script: `/usr/local/bin/hms-backup.sh`
- Health script: `/usr/local/bin/hms-health-check.sh`

---

**Prompt 11: SSL Certificate Setup**
```
Setup HTTPS with Let's Encrypt SSL certificate? (y/n):
```
✅ **Answer:** `y` (highly recommended for production)

⚠️ If you entered an IP address (not domain) in Phase 4, this will be skipped automatically.

---

## 🔐 SSL Certificate Setup

### Option Selection
```
Enter your BASE domain (e.g., hms.yourdomain.com): hms.yourdomain.com

Wildcard certificate will cover: hms.yourdomain.com AND *.hms.yourdomain.com

Select your DNS provider:
  1) Cloudflare (recommended)
  2) Manual DNS (you'll add TXT records manually)
  3) Skip wildcard - single domain only
Choice (1-3):
```

---

### **Option 1: Cloudflare (Automated) ✨ Easiest**

**Select:** `1`

**Prompt:**
```
You need Cloudflare API Token with Zone:DNS:Edit permissions
Get it from: https://dash.cloudflare.com/profile/api-tokens

Enter Cloudflare API Token:
```

**Steps to get token:**
1. Login to Cloudflare
2. Go to: https://dash.cloudflare.com/profile/api-tokens
3. Click "Create Token"
4. Use template: "Edit zone DNS"
5. Select your domain
6. Create token and copy it

**Then:**
- Paste token
- Wait 1-2 minutes for automatic DNS verification
- Certificate will be generated automatically

---

### **Option 2: Manual DNS (Hoster.pk, cPanel, etc.) 📝**

**Select:** `2`

**Instructions Display:**
```
═══════════════════════════════════════════════════════════════
  IMPORTANT: Manual DNS Challenge Instructions
═══════════════════════════════════════════════════════════════

Certbot will show you TWO TXT records that you need to add to
your DNS provider (Hoster.pk cPanel).

For each TXT record:
  1. DON'T press Enter when certbot shows the record
  2. Login to Hoster.pk cPanel → Zone Editor
  3. Add TXT record:
     Name:   _acme-challenge.hms
     Type:   TXT
     Record: [value shown by certbot]
     TTL:    300
  4. Verify with: dig _acme-challenge.hms.yourdomain.com TXT +short
  5. Only then press Enter in certbot

You'll need to add TWO records (same name, different values)

═══════════════════════════════════════════════════════════════

Press Enter when ready to start certificate request...
```

**Press Enter to continue**

---

### **First TXT Record Challenge**

**Certbot displays:**
```
Please deploy a DNS TXT record under the name:
_acme-challenge.hms.yourdomain.com

with the following value:
xYz123AbC456DeF789GhI012JkL345MnO678PqR901StU234VwX567YzA890BcD

Before continuing, verify the TXT record has been deployed.
Press Enter to Continue
```

⚠️ **STOP - DO NOT PRESS ENTER YET!**

**Action Required:**

1. **Open new browser tab**
2. **Login to Hoster.pk cPanel**
3. **Navigate to Zone Editor → Manage Zone**
4. **Select your domain:** `yourdomain.com`
5. **Click "Add Record"**

**Add TXT Record:**
```
Type:   TXT
Name:   _acme-challenge.hms
Record: xYz123AbC456DeF789GhI012JkL345MnO678PqR901StU234VwX567YzA890BcD
TTL:    300
```

6. **Click "Add Record"**

**Verify the record (in another terminal):**
```bash
dig _acme-challenge.hms.yourdomain.com TXT +short

# Should show: "xYz123AbC..."
```

⏱️ **Wait 2-5 minutes** if not visible yet.

**Or use online tool:**
https://toolbox.googleapps.com/apps/dig/#TXT/_acme-challenge.hms.yourdomain.com

**Once visible, press Enter in deployment terminal**

---

### **Second TXT Record Challenge**

**Certbot displays:**
```
Please deploy a DNS TXT record under the name:
_acme-challenge.hms.yourdomain.com

with the following value:
AbC789XyZ012DeF345GhI678JkL901MnO234PqR567StU890VwX123YzA456BcD
(This is DIFFERENT from the first value!)

Before continuing, verify the TXT record has been deployed.
Press Enter to Continue
```

⚠️ **STOP - DO NOT PRESS ENTER YET!**

**Action Required:**

1. **Go back to cPanel Zone Editor**
2. **Add SECOND TXT record with SAME name:**

```
Type:   TXT
Name:   _acme-challenge.hms
Record: AbC789XyZ012DeF345GhI678JkL901MnO234PqR567StU890VwX123YzA456BcD
TTL:    300
```

3. **Click "Add Record"**

**Now you should have TWO TXT records:**
```
_acme-challenge.hms → "xYz123AbC..." (first)
_acme-challenge.hms → "AbC789XyZ..." (second)
```

**Verify BOTH records:**
```bash
dig _acme-challenge.hms.yourdomain.com TXT +short

# Should show BOTH values:
# "xYz123AbC456..."
# "AbC789XyZ012..."
```

⏱️ **Wait 2-5 minutes** if both not visible.

**Once both visible, press Enter in deployment terminal**

---

### **Certificate Generation Success**

**Display:**
```
✓ Wildcard SSL certificate generated successfully
  Certificate covers: hms.yourdomain.com and *.hms.yourdomain.com
  Stored in: /etc/letsencrypt/live/hms.yourdomain.com/

✓ SSL auto-renewal configured (checks twice daily)
  Renewal logs: /var/log/certbot-renewal.log
```

---

### **Option 3: Single Domain (No Wildcard)**

**Select:** `3`

**What it does:**
- Generates certificate for `hms.yourdomain.com` only
- Uses HTTP-01 challenge (simpler, no DNS changes)
- Temporarily stops nginx for validation
- ⚠️ Does NOT cover subdomains (*.domain)

**Use case:** Testing or single-hospital deployment

---

## ✅ Deployment Summary

**Success Display:**
```
╔══════════════════════════════════════════════════════════╗
║      🎉 HMS DEPLOYMENT COMPLETED SUCCESSFULLY! 🎉       ║
╚══════════════════════════════════════════════════════════╝

📱 ACCESS YOUR APPLICATION
  🌐 Admin Panel:     http://hms.yourdomain.com/
  👤 Patient Portal:  http://hms.yourdomain.com/portal/
  💚 API Health:      http://hms.yourdomain.com/api-server/health

📋 IMPORTANT INFORMATION
  📁 Project Directory:  /root/nxt-hospital-skeleton-project
  🔑 Credentials File:   /root/.hms_credentials_YYYYMMDD.txt
  📝 Deployment Log:     deployment_YYYYMMDD_HHMMSS.log

🏢 MULTI-TENANT ARCHITECTURE
  This deployment supports UNLIMITED hospital tenants:
  
  • hospital-a.hms.yourdomain.com → Tenant A
  • hospital-b.hms.yourdomain.com → Tenant B
  • clinic-xyz.hms.yourdomain.com → Tenant XYZ
```

---

## 🔒 Post-Deployment Configuration

### Step 1: Save Your Credentials

**View credentials:**
```bash
cat /root/.hms_credentials_*.txt
```

**Copy to safe location (from your LOCAL machine):**
```bash
scp root@YOUR_VM_IP:/root/.hms_credentials_*.txt ./hms-credentials-backup.txt
```

**Delete from server after saving:**
```bash
rm /root/.hms_credentials_*.txt
```

⚠️ **CRITICAL:** Save these credentials securely! You cannot recover them later.

---

### Step 2: Enable HTTPS (If SSL was setup)

**Create HTTPS Nginx Configuration:**
```bash
cd ~/nxt-hospital-skeleton-project
nano nginx/conf.d/reverse-proxy-https.conf
```

**Paste this configuration:**
```nginx
# HTTPS Server - Multi-Tenant HMS
server {
    listen 443 ssl;
    http2 on;
    server_name hms.yourdomain.com *.hms.yourdomain.com;

    ssl_certificate /etc/letsencrypt/live/hms.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/hms.yourdomain.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;

    add_header Strict-Transport-Security "max-age=31536000" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;

    location /api-server/ {
        proxy_pass http://hospital-apis:80/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
    }

    location /portal/ {
        proxy_pass http://patient-frontend:80/portal/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
    }

    location /images/ {
        alias /usr/share/nginx/html/images/;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    location / {
        proxy_pass http://hospital-frontend:80/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
    }
}

# HTTP to HTTPS Redirect
server {
    listen 80;
    server_name hms.yourdomain.com *.hms.yourdomain.com;
    
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    
    location / {
        return 301 https://$host$request_uri;
    }
}
```

Save: `Ctrl+O`, Enter, `Ctrl+X`

**Update docker-compose.yml:**
```bash
nano docker-compose.yml
```

Find the nginx service volumes section and add:
```yaml
      - /etc/letsencrypt:/etc/letsencrypt:ro
```

Full nginx volumes section should look like:
```yaml
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/conf.d:/etc/nginx/conf.d:ro
      - /etc/letsencrypt:/etc/letsencrypt:ro
      - ./images:/usr/share/nginx/html/images:ro
```

**Test and restart nginx:**
```bash
# Test configuration
docker exec nginx-reverse-proxy nginx -t

# Should show: syntax is ok, test is successful

# Restart nginx
docker compose restart nginx

# Verify all containers
docker compose ps
```

---

### Step 3: Update Backend for HTTPS

```bash
nano ~/nxt-hospital-skeleton-project/hms-backend.env
```

**Update these lines:**
```env
# Change HTTP to HTTPS
EMAIL_IMAGE_PATH=https://hms.yourdomain.com/images/logo.png
ALLOWED_ORIGINS=["https://hms.yourdomain.com","https://*.hms.yourdomain.com"]
```

**Restart backend:**
```bash
docker compose restart hospital-apis
```

---

## 🏥 Creating Your First Tenant

### Step 1: Connect to MySQL

```bash
cd ~/nxt-hospital-skeleton-project

# Get DB password
DB_PASS=$(grep "DB_PASSWORD=" hms-backend.env | cut -d'=' -f2)

# Connect to MySQL
docker exec -it hospital-mysql mysql -u nxt_user -p"$DB_PASS" nxt-hospital
```

### Step 2: Insert Tenant Record

```sql
-- Create first hospital tenant
INSERT INTO nxt_tenant (
    tenant_id,
    tenant_name,
    tenant_subdomain,
    tenant_status,
    tenant_email,
    tenant_phone,
    tenant_address,
    created_at,
    updated_at
) VALUES (
    'tenant_demo_hospital',
    'Demo Hospital',
    'demo',
    'active',
    'admin@demo-hospital.com',
    '+92-300-1234567',
    '123 Medical Street, City',
    NOW(),
    NOW()
);

-- Verify tenant created
SELECT * FROM nxt_tenant WHERE tenant_id = 'tenant_demo_hospital';

-- Exit MySQL
EXIT;
```

### Step 3: Create File Storage

```bash
cd ~/nxt-hospital-skeleton-project

# Create directories
mkdir -p images/tenant_demo_hospital/{patients,reports,prescriptions,lab-results,invoices,profile-pictures}

# Set permissions
chmod -R 755 images/tenant_demo_hospital

# Verify
ls -la images/
```

### Step 4: Access Your Tenant

**Open browser:**
```
https://demo.hms.yourdomain.com/
```

✅ Your first tenant is live!

---

## 🧪 Testing & Verification

### Test 1: Check Container Status

```bash
docker compose ps

# All containers should show "Up" and "healthy"
```

**Expected output:**
```
NAME                  STATUS              PORTS
nginx-reverse-proxy   Up (healthy)        0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp
api-hospital          Up (healthy)        80/tcp
nxt-hospital          Up                  80/tcp
portal-hospital       Up                  80/tcp
hospital-mysql        Up (healthy)        3306/tcp
hospital-redis        Up (healthy)        6379/tcp
```

---

### Test 2: HTTP to HTTPS Redirect

```bash
curl -I http://hms.yourdomain.com
```

**Expected output:**
```
HTTP/1.1 301 Moved Permanently
Location: https://hms.yourdomain.com/
```

---

### Test 3: HTTPS Access

```bash
curl -I https://hms.yourdomain.com
```

**Expected output:**
```
HTTP/2 200
server: nginx/1.25
```

---

### Test 4: API Health Check

```bash
curl https://hms.yourdomain.com/api-server/health
```

**Expected output:**
```json
{"status":"ok"}
```

---

### Test 5: Database Verification

```bash
DB_PASS=$(grep "DB_PASSWORD=" hms-backend.env | cut -d'=' -f2)

docker exec hospital-mysql mysql -u nxt_user -p"$DB_PASS" nxt-hospital -e "SELECT COUNT(*) as table_count FROM information_schema.tables WHERE table_schema='nxt-hospital';"
```

**Expected output:**
```
table_count
53
```

(Should show 50+ tables)

---

### Test 6: Browser Access

**Open these URLs in browser:**

1. **Main Admin Panel:**
   ```
   https://hms.yourdomain.com/
   ```
   ✅ Should load admin login page with green padlock

2. **Patient Portal:**
   ```
   https://hms.yourdomain.com/portal/
   ```
   ✅ Should load patient portal login

3. **Tenant Subdomain:**
   ```
   https://demo.hms.yourdomain.com/
   ```
   ✅ Should load tenant-specific admin panel

4. **API Health:**
   ```
   https://hms.yourdomain.com/api-server/health
   ```
   ✅ Should show: `{"status":"ok"}`

---

### Test 7: Wildcard SSL Verification

```bash
# Test various subdomains
curl -I https://hospital-a.hms.yourdomain.com
curl -I https://clinic-xyz.hms.yourdomain.com
curl -I https://test.hms.yourdomain.com
```

**All should return:**
```
HTTP/2 200
```

---

## 🛠️ Troubleshooting

### Issue: MySQL Container Unhealthy

**Symptoms:**
- MySQL shows "unhealthy" in `docker compose ps`
- nginx and api containers stuck in "Created" state

**Diagnosis:**
```bash
# Check MySQL logs
docker logs hospital-mysql --tail 50

# Look for "ready for connections"
```

**Fix:**
```bash
# The deploy.sh script should have fixed this, but verify:
grep "MYSQL_PASSWORD" docker-compose.yml

# Should show $$MYSQL_PASSWORD in healthcheck, not hardcoded password
```

**If still broken:**
```bash
docker compose down -v
./deploy.sh  # Re-run deployment
```

---

### Issue: Containers Not Starting

**Check logs:**
```bash
docker compose logs [container-name]

# Examples:
docker compose logs hospital-mysql
docker compose logs hospital-apis
docker compose logs nginx-reverse-proxy
```

**Restart specific container:**
```bash
docker compose restart [container-name]
```

**Restart all containers:**
```bash
docker compose restart
```

---

### Issue: SSL Certificate Validation Failed

**If manual DNS challenge failed:**

**Check TXT records:**
```bash
dig _acme-challenge.hms.yourdomain.com TXT +short
```

Should show TWO TXT records with different values.

**Retry certificate generation:**
```bash
certbot certonly \
  --manual \
  --preferred-challenges dns \
  -d "hms.yourdomain.com" \
  -d "*.hms.yourdomain.com" \
  --agree-tos \
  --email your-email@domain.com
```

---

### Issue: Cannot Access via HTTPS

**Check nginx configuration:**
```bash
docker exec nginx-reverse-proxy nginx -t
```

**Check if SSL files exist:**
```bash
ls -la /etc/letsencrypt/live/hms.yourdomain.com/
```

Should show:
- `fullchain.pem`
- `privkey.pem`

**Check nginx logs:**
```bash
docker logs nginx-reverse-proxy --tail 50
```

---

### Issue: API Returns 502 Bad Gateway

**Check backend logs:**
```bash
docker logs api-hospital --tail 50
```

**Verify backend is running:**
```bash
docker compose ps | grep api-hospital
```

**Restart backend:**
```bash
docker compose restart hospital-apis
```

---

### Issue: Database Connection Failed

**Check MySQL is running:**
```bash
docker compose ps | grep mysql
```

**Test MySQL connection:**
```bash
DB_PASS=$(grep "DB_PASSWORD=" hms-backend.env | cut -d'=' -f2)
docker exec hospital-mysql mysql -u nxt_user -p"$DB_PASS" -e "SELECT 1;"
```

**Check database exists:**
```bash
docker exec hospital-mysql mysql -u nxt_user -p"$DB_PASS" -e "SHOW DATABASES;"
```

---

### Issue: DNS Not Resolving

**Test DNS propagation:**
```bash
# From server
dig hms.yourdomain.com +short

# From your local machine
nslookup hms.yourdomain.com
```

**Clear DNS cache (local machine):**
- **Windows:** `ipconfig /flushdns`
- **Linux:** `sudo systemd-resolve --flush-caches`
- **Mac:** `sudo dscacheutil -flushcache`

**Wait time:** DNS changes can take 5-60 minutes to propagate globally.

---

## 📊 Useful Commands

### Container Management

```bash
# View all containers
docker compose ps

# View logs
docker compose logs -f
docker compose logs -f [service-name]

# Restart service
docker compose restart [service-name]

# Stop all
docker compose down

# Start all
docker compose up -d

# Rebuild specific service
docker compose up -d --force-recreate [service-name]
```

### Database Operations

```bash
# Connect to MySQL
DB_PASS=$(grep "DB_PASSWORD=" hms-backend.env | cut -d'=' -f2)
docker exec -it hospital-mysql mysql -u nxt_user -p"$DB_PASS" nxt-hospital

# Backup database
docker exec hospital-mysql mysqldump -u nxt_user -p"$DB_PASS" nxt-hospital > backup_$(date +%Y%m%d).sql

# Restore database
docker exec -i hospital-mysql mysql -u nxt_user -p"$DB_PASS" nxt-hospital < backup.sql

# Run manual backup
/usr/local/bin/hms-backup.sh
```

### SSL Certificate Management

```bash
# List certificates
certbot certificates

# Renew certificates (manual test)
certbot renew --dry-run

# Force renewal
certbot renew --force-renewal

# View certificate details
openssl x509 -in /etc/letsencrypt/live/hms.yourdomain.com/fullchain.pem -text -noout
```

### System Monitoring

```bash
# View resource usage
docker stats

# Check disk space
df -h

# Check memory
free -h

# View backup logs
tail -f /var/log/hms-backup.log

# View health check logs
tail -f /var/log/hms-health.log

# View deployment log
tail -f deployment_*.log
```

---

## 📚 Next Steps

### 1. Security Hardening
- [ ] Change default database passwords
- [ ] Configure firewall rules
- [ ] Enable fail2ban for SSH protection
- [ ] Setup regular security updates

### 2. Monitoring Setup
- [ ] Configure email alerts for backups
- [ ] Setup monitoring dashboard
- [ ] Configure log rotation

### 3. Tenant Management
- [ ] Create admin users for default tenant
- [ ] Add additional hospital tenants
- [ ] Setup tenant-specific configurations

### 4. Integration Configuration
- [ ] Configure FBR integration (if needed)
- [ ] Setup WhatsApp notifications
- [ ] Configure OpenAI integration
- [ ] Setup SMTP email properly

### 5. Documentation
- [ ] Document tenant-specific configurations
- [ ] Create user guides
- [ ] Document custom modifications

---

## 🎯 Deployment Checklist

**Pre-Deployment:**
- [ ] Server meets requirements (4GB RAM, 40GB disk)
- [ ] Domain registered and accessible
- [ ] DNS records configured (A and wildcard A)
- [ ] SSH access to server
- [ ] Docker and Git installed

**During Deployment:**
- [ ] Run `./deploy.sh` script
- [ ] Answer all prompts correctly
- [ ] Wait for MySQL initialization (10-15 minutes)
- [ ] Setup SSL certificate (Cloudflare or Manual DNS)
- [ ] Save credentials file securely

**Post-Deployment:**
- [ ] Save credentials to password manager
- [ ] Delete credentials file from server
- [ ] Create HTTPS nginx configuration
- [ ] Test HTTPS access
- [ ] Verify all containers healthy
- [ ] Test API health endpoint
- [ ] Create first hospital tenant
- [ ] Test tenant subdomain access
- [ ] Setup monitoring and alerts
- [ ] Configure automated backups

---

## 🆘 Getting Help

**Documentation:**
- Main README: `README.md`
- Production Deployment: `docs/PRODUCTION_DEPLOYMENT.md`
- Tenant Onboarding: `docs/TENANT_ONBOARDING.md`
- Multi-Tenant DNS: `docs/MULTI_TENANT_DNS_SETUP.md`
- Developer Guide: `.github/copilot-instructions.md`

**Common Issues:**
- Check deployment log: `deployment_YYYYMMDD_HHMMSS.log`
- View container logs: `docker compose logs -f`
- Check backup logs: `/var/log/hms-backup.log`
- Check health logs: `/var/log/hms-health.log`

---

## ✅ Success Criteria

Your deployment is successful when:

✅ All 6 containers are running and healthy
✅ HTTPS access works with valid SSL certificate
✅ API health endpoint returns `{"status":"ok"}`
✅ Admin panel loads at `https://hms.yourdomain.com/`
✅ Patient portal loads at `https://hms.yourdomain.com/portal/`
✅ Wildcard subdomains work: `https://demo.hms.yourdomain.com/`
✅ Database has 50+ tables
✅ Automated backups configured
✅ SSL auto-renewal configured
✅ First tenant created and accessible

---

## 🎉 Congratulations!

Your multi-tenant Hospital Management System is now deployed and ready for production use!

**Deployment Time:** ~15-20 minutes
**Uptime Target:** 99.9%
**Scalability:** Unlimited tenants
**Security:** SSL encrypted, JWT authentication, tenant isolation

**Your HMS can now serve unlimited hospitals with:**
- Individual subdomains per hospital
- Isolated data and file storage
- Centralized management
- Automated backups
- Health monitoring
- SSL certificate auto-renewal

---

*Last Updated: January 4, 2026*
*Script Version: 2.0*
*HMS Version: Production Release*
