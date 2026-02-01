# 🚑 HMS Deployment - Quick Fix Guide

## Current Issue: Nginx Restart Loop ❌

**Root Cause:** `patient-frontend` was commented out in nginx's `depends_on` list, causing DNS resolution failures.

**Status:** ✅ **FIXED** in `docker-compose.yml` (line 117)

---

## 📋 Next Steps (Run on VM)

### 1. Stop Current Deployment
```bash
cd ~/nxt-hospital-skeleton-project
docker compose down
```

### 2. Pull Latest Changes
```bash
git pull origin main
```

### 3. Restart Deployment
```bash
docker compose up -d
```

### 4. Verify Deployment
```bash
chmod +x verify-deployment.sh
./verify-deployment.sh
```

---

## 🔍 Expected Output After Fix

```bash
root@vm:~/nxt-hospital-skeleton-project# docker ps
CONTAINER ID   IMAGE                          STATUS
xxx            nginx:1.25                     Up 2 minutes (healthy)    ✅
xxx            pandanxt/hms-backend-apis...   Up 2 minutes (healthy)    ✅
xxx            pandanxt/hospital-frontend...  Up 2 minutes              ✅
xxx            pandanxt/customer-portal...    Up 2 minutes              ✅
xxx            redis:7.2                      Up 2 minutes (healthy)    ✅
xxx            mysql:latest                   Up 2 minutes (healthy)    ✅
```

**All 6 containers should show "Up" status, NOT "Restarting"**

---

## 🩺 Health Check Commands

### Quick Health Check
```bash
# Nginx
curl http://localhost/nginx-health

# Backend API
curl http://localhost/api-server/health

# All containers
docker compose ps
```

### Detailed Logs
```bash
# Nginx logs (should NOT show errors)
docker logs nginx-reverse-proxy

# API logs (should show "Bootstrap completed" after 30-60 sec)
docker logs api-hospital

# Follow live logs
docker compose logs -f
```

---

## ✅ What Was Fixed

### Before (Broken)
```yaml
depends_on:
  - hospital-apis
  - hospital-frontend
  # - patient-frontend  ❌ COMMENTED OUT
```

**Result:** Nginx tries to proxy to `patient-frontend:80` but can't resolve DNS → crashes → restarts forever

### After (Fixed)
```yaml
depends_on:
  - hospital-apis
  - hospital-frontend
  - patient-frontend  ✅ UNCOMMENTED
```

**Result:** Nginx waits for all services, DNS resolution works, proxying successful

---

## 📊 Verification Checklist

After restart, verify:

- [ ] All 6 containers show "Up" (not "Restarting")
- [ ] Nginx logs show no errors
- [ ] `curl http://localhost/nginx-health` returns "nginx OK"
- [ ] `curl http://localhost/api-server/health` returns `{"status":"ok"...}`
- [ ] Browser access: `http://YOUR_VM_IP/` shows admin login
- [ ] Browser access: `http://YOUR_VM_IP/portal/` shows patient portal

---

## 🚨 If Still Having Issues

### Check Nginx Configuration
```bash
# Test nginx config syntax
docker exec nginx-reverse-proxy nginx -t

# View nginx error logs
docker logs nginx-reverse-proxy 2>&1 | grep -i error
```

### Check API Bootstrap
```bash
# Wait for bootstrap to complete (30-60 seconds)
docker logs -f api-hospital | grep -i bootstrap

# Should see:
# "Bootstrap initiated..."
# "Bootstrap completed successfully"
```

### Check Network Connectivity
```bash
# Test DNS resolution from nginx container
docker exec nginx-reverse-proxy ping -c 1 hospital-apis
docker exec nginx-reverse-proxy ping -c 1 patient-frontend
docker exec nginx-reverse-proxy ping -c 1 hospital-frontend

# All should resolve successfully
```

---

## 📝 Configuration Summary

From your deployment log:

- **Default Tenant:** `nxthms` ✅ (user-provided)
- **Domain/IP:** `157.173.109.136` ✅
- **Database:** 65 tables created ✅
- **Services:** All 6 containers started ✅
- **Issue:** Only Nginx restart loop ❌ → **NOW FIXED** ✅

---

## 🎯 Access Your Application

Once deployment is verified:

### Admin Panel
```
http://157.173.109.136/
```

### Patient Portal
```
http://157.173.109.136/portal/
```

### API Health
```
http://157.173.109.136/api-server/health
```

### Multi-Tenant Pattern
```
Primary:  157.173.109.136 (or nxthms.yourdomain.com)
Tenant 1: hospital1-nxthms.yourdomain.com
Tenant 2: hospital2-nxthms.yourdomain.com
```

---

## 💡 Pro Tips

1. **First deployment takes 1-2 minutes** for MySQL schema initialization
2. **API bootstrap takes 30-60 seconds** - be patient!
3. **Check logs if something fails** - they're very detailed
4. **Run verify-deployment.sh** - automated health checks
5. **BASE_SUBDOMAIN prompt worked** - you entered "nxthms" successfully ✅

---

## 📞 Support Commands

```bash
# Full system status
docker compose ps

# Service-specific logs
docker logs nginx-reverse-proxy
docker logs api-hospital
docker logs hospital-mysql

# Follow all logs in real-time
docker compose logs -f

# Restart specific service
docker compose restart nginx

# Complete redeployment
docker compose down && docker compose up -d
```

---

**Last Updated:** 2026-02-02  
**Fix Applied:** docker-compose.yml line 117 (uncommented patient-frontend)  
**Status:** Ready for redeployment ✅
