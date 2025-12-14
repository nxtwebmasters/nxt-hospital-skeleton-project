# Nginx Reverse Proxy Configuration

## Active Configuration

**Current Mode:** HTTP-only (Testing/Development)

**Active File:** `reverse-proxy-http.conf`
- No TLS certificates required
- Suitable for local testing and internal deployments
- All traffic served over HTTP on port 80

## Configuration Files

| File | Purpose | Status |
|------|---------|--------|
| `reverse-proxy-http.conf` | HTTP-only mode | ✅ Active |
| `reverse-proxy-https.conf.disabled` | HTTPS with TLS certificates | ⏸️ Disabled |

## Enable HTTPS for Production

1. Obtain wildcard TLS certificates:
   ```bash
   cd ../../scripts
   sudo bash obtain_wildcard_cert.sh yourdomain.com admin@yourdomain.com
   ```

2. Enable HTTPS configuration:
   ```bash
   cd ../nginx/conf.d
   mv reverse-proxy-https.conf.disabled reverse-proxy-https.conf
   rm reverse-proxy-http.conf
   ```

3. Reload nginx:
   ```bash
   docker compose restart nginx
   ```

## Certificate Location

TLS certificates should be on the **host** at:
- `/etc/letsencrypt/live/yourdomain.com/fullchain.pem`
- `/etc/letsencrypt/live/yourdomain.com/privkey.pem`

Docker compose mounts `/etc/letsencrypt` into the nginx container (read-only).

## Testing Configuration

Before restarting nginx, validate configuration:
```bash
docker compose exec nginx nginx -t
```

## Troubleshooting

**Issue:** nginx fails to start  
**Solution:** Check logs: `docker compose logs nginx`

**Issue:** 502 Bad Gateway  
**Solution:** Verify backend services are running: `docker compose ps`

**Issue:** TLS certificate errors  
**Solution:** Ensure certificates exist at `/etc/letsencrypt/live/yourdomain.com/`
