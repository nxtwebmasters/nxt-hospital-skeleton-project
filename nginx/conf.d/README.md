# Nginx Reverse Proxy Configuration

## Active Configuration

**Current Mode:** HTTP-only (Testing/Development)

**Active File:** `reverse-proxy-http.conf`
- ✅ No TLS certificates required
- ✅ Works out of the box after deployment
- ✅ Suitable for IP-based access and local testing
- ⚠️ All traffic unencrypted (not for production)

## Configuration Files

| File | Purpose | Status | Use For |
|------|---------|--------|---------|
| `reverse-proxy-http.conf` | HTTP-only | ✅ Active | Dev/Testing/Internal |
| `reverse-proxy-https.conf` | HTTPS with SSL | 📝 Template | Production |

---

## Quick Start (HTTP Mode - Current)

**Access URLs after deployment:**
```
Admin:   http://YOUR_SERVER_IP/
Patient: http://YOUR_SERVER_IP/portal/
API:     http://YOUR_SERVER_IP/api-server/health
```

**Example:** `http://157.173.109.136/`

---

## Production Setup (HTTPS Mode)

### Step 1: Update HTTPS Configuration

Edit `reverse-proxy-https.conf` and replace placeholder:

```nginx
# FIND:
server_name YOURDOMAIN.COM *.YOURDOMAIN.COM;
ssl_certificate /etc/letsencrypt/live/YOURDOMAIN.COM/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/YOURDOMAIN.COM/privkey.pem;

# REPLACE WITH YOUR ACTUAL DOMAIN:
server_name hms.example.com *.hms.example.com;
ssl_certificate /etc/letsencrypt/live/hms.example.com/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/hms.example.com/privkey.pem;
```

### Step 2: Obtain Wildcard SSL Certificate

```bash
cd ~/nxt-hospital-skeleton-project/scripts
sudo bash obtain_wildcard_cert.sh example.com admin@example.com
```

**Or manually with certbot:**
```bash
sudo certbot certonly --dns-cloudflare \
  -d hms.example.com \
  -d *.hms.example.com
```

### Step 3: Switch to HTTPS Configuration

```bash
cd ~/nxt-hospital-skeleton-project/nginx/conf.d

# Disable HTTP-only config
mv reverse-proxy-http.conf reverse-proxy-http.conf.disabled

# Enable HTTPS config
mv reverse-proxy-https.conf reverse-proxy-https.conf

# Restart nginx
cd ~/nxt-hospital-skeleton-project
docker compose restart nginx
```

### Step 4: Verify HTTPS Access

```bash
# Test health endpoint
curl https://hms.example.com/nginx-health

# Check certificate
openssl s_client -connect hms.example.com:443 -servername hms.example.com
```

**Access URLs (HTTPS Mode):**
```
Admin:   https://hms.example.com/
Patient: https://hms.example.com/portal/
API:     https://hms.example.com/api-server/health

Multi-tenant:
Tenant 1: https://hospital1.hms.example.com/
Tenant 2: https://hospital2.hms.example.com/
```

---

## How It Works

### URL Routing Pattern

Both configs route requests to Docker internal services:

| Path | Backend Service | Container Port |
|------|----------------|----------------|
| `/` | Hospital Admin UI | `hospital-frontend:80` |
| `/portal/` | Patient Portal UI | `patient-frontend:80` |
| `/api-server/` | Backend API | `hospital-apis:80` |
| `/images/` | Static Files | `hospital-apis:80` |
| `/nginx-health` | Nginx Health Check | (nginx internal) |

### Multi-Tenant URL Structure

**With wildcard SSL (HTTPS mode):**
- Base: `https://BASE_SUBDOMAIN.yourdomain.com/`
- Tenants: `https://<tenant>-BASE_SUBDOMAIN.yourdomain.com/`

**Example with BASE_SUBDOMAIN="hms":**
- System: `https://hms.example.com/`
- Hospital A: `https://hospitalA-hms.example.com/`
- Hospital B: `https://hospitalB-hms.example.com/`

Backend extracts tenant from subdomain and enforces data isolation.

---

## Certificate Management

### Location on Host

Certbot stores certificates at:
```
/etc/letsencrypt/live/hms.example.com/
├── fullchain.pem   → Public certificate + intermediates
├── privkey.pem     → Private key
├── cert.pem        → Public certificate only
└── chain.pem       → Intermediate certificates
```

### Docker Volume Mount

Docker compose mounts certificates into nginx container:
```yaml
volumes:
  - /etc/letsencrypt:/etc/letsencrypt:ro
```

**Note:** Read-only mount (`ro`) for security.

### Auto-Renewal

Certbot auto-renews via systemd timer:
```bash
# Check renewal status
sudo certbot renew --dry-run

# Manual renewal
sudo certbot renew

# After renewal, reload nginx
docker compose exec nginx nginx -s reload
```

---

## Testing & Validation

### Test Configuration Syntax

```bash
# Before restarting nginx
docker compose exec nginx nginx -t
```

### Test Health Endpoint

```bash
# HTTP mode
curl http://localhost/nginx-health

# HTTPS mode
curl https://hms.example.com/nginx-health
```

**Expected response:** `"nginx OK"`

### Test Backend Connectivity

```bash
# From host
docker compose exec nginx ping -c 1 hospital-apis
docker compose exec nginx ping -c 1 patient-frontend
docker compose exec nginx ping -c 1 hospital-frontend
```

### Monitor Nginx Logs

```bash
# Follow all logs
docker logs -f nginx-reverse-proxy

# Access logs only
docker exec nginx-reverse-proxy tail -f /var/log/nginx/access.log

# Error logs only
docker exec nginx-reverse-proxy tail -f /var/log/nginx/error.log
```

---

## Troubleshooting

### Nginx Fails to Start

**Check configuration syntax:**
```bash
docker compose exec nginx nginx -t
```

**View error logs:**
```bash
docker logs nginx-reverse-proxy --tail 50
```

**Common issues:**
- ❌ Placeholder `YOURDOMAIN.COM` not replaced
- ❌ SSL certificate files don't exist
- ❌ Both HTTP and HTTPS configs active (port conflict)
- ❌ Syntax error in config file

### 502 Bad Gateway

**Verify backend services running:**
```bash
docker compose ps
# All should show "Up" status
```

**Test backend health:**
```bash
curl http://localhost/api-server/health
```

**Check nginx can resolve backend hostnames:**
```bash
docker exec nginx-reverse-proxy getent hosts hospital-apis
docker exec nginx-reverse-proxy getent hosts patient-frontend
```

### SSL Certificate Errors

**Verify certificates exist:**
```bash
sudo ls -la /etc/letsencrypt/live/hms.example.com/
```

**Check certificate validity:**
```bash
sudo openssl x509 -in /etc/letsencrypt/live/hms.example.com/fullchain.pem -text -noout
```

**Test SSL handshake:**
```bash
openssl s_client -connect hms.example.com:443 -servername hms.example.com
```

### Can't Access from Browser

**Firewall issues:**
```bash
# Check ports open
sudo netstat -tulpn | grep -E ':(80|443)'

# Allow ports (Ubuntu/Debian)
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

**DNS issues:**
```bash
# Test DNS resolution
nslookup hms.example.com

# Flush local DNS cache
sudo systemd-resolve --flush-caches
```

---

## Security Notes

### HTTP Mode (Development Only)

⚠️ **Security Warnings:**
- All traffic transmitted in plain text
- Passwords visible to network sniffers
- Session tokens can be intercepted
- **DO NOT use for production deployments**

### HTTPS Mode (Production)

✅ **Security Features:**
- TLS 1.2+ only (secure protocols)
- Modern cipher suites (no weak ciphers)
- HSTS header (force HTTPS for 1 year)
- HTTP → HTTPS automatic redirect
- Secure session cookies

---

## Advanced Configuration

### Custom Headers

Add custom headers in the `location` blocks:
```nginx
location / {
    proxy_pass http://hospital-frontend:80;
    proxy_set_header X-Custom-Header "value";
}
```

### Rate Limiting

Add rate limiting to prevent abuse:
```nginx
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;

location /api-server/ {
    limit_req zone=api burst=20;
    proxy_pass http://hospital-apis:80/api-server/;
}
```

### IP Whitelisting

Restrict access to specific IPs:
```nginx
location /admin/ {
    allow 192.168.1.0/24;
    deny all;
    proxy_pass http://hospital-frontend:80/admin/;
}
```

---

## Quick Reference

### Switch HTTP → HTTPS
```bash
cd ~/nxt-hospital-skeleton-project/nginx/conf.d
mv reverse-proxy-http.conf reverse-proxy-http.conf.disabled
mv reverse-proxy-https.conf reverse-proxy-https.conf
docker compose restart nginx
```

### Switch HTTPS → HTTP
```bash
cd ~/nxt-hospital-skeleton-project/nginx/conf.d
mv reverse-proxy-https.conf reverse-proxy-https.conf.disabled
mv reverse-proxy-http.conf.disabled reverse-proxy-http.conf
docker compose restart nginx
```

### Reload Without Restart
```bash
docker compose exec nginx nginx -s reload
```

### View Active Config
```bash
docker exec nginx-reverse-proxy cat /etc/nginx/conf.d/reverse-proxy-*.conf
```

---

**For deployment guide, see:** `docs/GENERIC_DEPLOYMENT_GUIDE.md`
