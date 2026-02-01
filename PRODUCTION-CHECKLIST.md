# 🎯 Production Readiness Checklist

This checklist ensures your HMS deployment is production-ready, secure, and properly configured.

---

## ✅ Pre-Deployment Checks

### Infrastructure
- [ ] Server meets minimum requirements (4GB RAM, 40GB disk, 2 CPU cores)
- [ ] Ubuntu 20.04+ or compatible Linux distribution
- [ ] Public IP address with static assignment
- [ ] Ports 22, 80, 443 accessible from internet
- [ ] SSH key-based authentication configured
- [ ] Root or sudo access available

### Domain & DNS
- [ ] Domain registered and under your control
- [ ] Wildcard DNS configured (`*.yourdomain.com`)
- [ ] DNS propagation verified (`nslookup`, `dig`)
- [ ] SSL email address configured for Let's Encrypt

### Configuration
- [ ] `deployment-config.local.sh` created and configured
- [ ] `DEPLOYMENT_DOMAIN` set correctly
- [ ] `DEFAULT_TENANT_SUBDOMAIN` set correctly
- [ ] `DEPLOYMENT_MODE` set to `https` for production
- [ ] SMTP credentials configured (if email needed)
- [ ] Admin email addresses set

---

## ✅ Deployment Validation

### Script Execution
- [ ] `./deploy.sh` completed without errors
- [ ] All Docker containers started successfully
- [ ] MySQL health check passed
- [ ] Redis health check passed
- [ ] API health check passed (`/api-server/health`)

### Service Accessibility
- [ ] Admin panel accessible: `https://<domain>/`
- [ ] Patient portal accessible: `https://<domain>/portal/`
- [ ] API responding: `https://<domain>/api-server/health`
- [ ] Status monitor: `https://<domain>/status`
- [ ] Queue dashboard: `https://<domain>/admin/queues`

### SSL/TLS (Production Only)
- [ ] SSL certificate installed correctly
- [ ] Certificate covers wildcard domain (`*.domain.com`)
- [ ] HTTP automatically redirects to HTTPS
- [ ] No SSL warnings in browser
- [ ] Certificate auto-renewal configured

### Database
- [ ] MySQL container running
- [ ] Database schema initialized (tables created)
- [ ] Bootstrap data loaded (departments, permissions, etc.)
- [ ] Test connection from backend successful
- [ ] Passwords match between `docker-compose.yml` and `hms-backend.env`

---

## ✅ Security Hardening

### Firewall
- [ ] UFW enabled and configured
- [ ] Only ports 22, 80, 443 open
- [ ] SSH rate limiting configured
- [ ] DDoS protection enabled (if available)

### Credentials
- [ ] Strong passwords generated (not defaults)
- [ ] JWT secret is 32+ character random string
- [ ] MySQL root password is strong and unique
- [ ] Database user password is strong
- [ ] Credentials file saved securely (`~/.hms_credentials_*.txt`)
- [ ] `deployment-config.local.sh` NOT committed to git

### Application Security
- [ ] Rate limiting enabled on API
- [ ] CORS properly configured
- [ ] Security headers present (HSTS, X-Frame-Options, etc.)
- [ ] File upload limits set (50MB)
- [ ] No debug endpoints exposed in production

---

## ✅ Multi-Tenant Configuration

### Default Tenant
- [ ] `BASE_SUBDOMAIN` matches `DEFAULT_TENANT_SUBDOMAIN` in config
- [ ] Default tenant accessible at main domain
- [ ] Can create admin user in default tenant
- [ ] Can login to admin panel

### Tenant Isolation
- [ ] File storage creates tenant directories automatically
- [ ] API requests include tenant context
- [ ] Database queries filter by `tenant_id`
- [ ] Subdomain routing works (test with fake subdomain)

### Tenant Creation
- [ ] Tenant creation API endpoint works
- [ ] New tenant gets database record
- [ ] New tenant gets file directory
- [ ] New tenant subdomain resolves correctly

---

## ✅ Monitoring & Maintenance

### Health Monitoring
- [ ] Health check cron job configured
- [ ] Auto-restart on failure enabled
- [ ] Log rotation configured
- [ ] Disk space monitoring active
- [ ] Email alerts configured (optional)

### Backup System
- [ ] Daily database backup cron configured (3 AM)
- [ ] Backup directory exists and is writable
- [ ] Backup retention policy set (7+ days recommended)
- [ ] Backup restoration tested
- [ ] File storage backup strategy defined

### Logging
- [ ] Application logs accessible (`docker-compose logs`)
- [ ] Log files not filling disk
- [ ] Important events logged (errors, auth failures)
- [ ] Log monitoring solution (optional: ELK, Loki)

---

## ✅ Performance & Scalability

### Resource Allocation
- [ ] Docker containers have resource limits set
- [ ] MySQL configured with appropriate memory
- [ ] Redis configured with appropriate memory
- [ ] Nginx worker processes configured

### Database Optimization
- [ ] Indexes created on frequently queried columns
- [ ] Connection pooling configured (10 connections)
- [ ] Query optimization verified
- [ ] Slow query log enabled for monitoring

### Caching
- [ ] Redis used for session storage
- [ ] API response caching configured (where appropriate)
- [ ] Static files cached by nginx (30 days)

---

## ✅ Integration Testing

### Core Functionality
- [ ] User registration works
- [ ] User login works
- [ ] Patient creation works
- [ ] Appointment booking works
- [ ] Billing/invoice generation works
- [ ] File upload works (images, documents)
- [ ] Lab test creation works
- [ ] Prescription creation works

### Background Jobs
- [ ] Campaign queue processing works
- [ ] Email sending works (if configured)
- [ ] WhatsApp sending works (if configured)
- [ ] Pharmacy expiry check runs daily
- [ ] Low stock alerts work
- [ ] Scheduler jobs run on schedule

### External Integrations
- [ ] FBR integration works (if enabled)
- [ ] WhatsApp API connected (if enabled)
- [ ] Email SMTP working (if configured)
- [ ] OpenAI API working (if configured)

---

## ✅ Documentation & Handover

### Documentation
- [ ] README.md reviewed and accurate
- [ ] Deployment config documented
- [ ] Admin credentials documented securely
- [ ] DNS configuration documented
- [ ] SSL renewal process documented

### Access & Credentials
- [ ] Admin user credentials provided to client
- [ ] Database credentials stored securely
- [ ] Server SSH access documented
- [ ] Domain/DNS access documented
- [ ] Integration API keys documented

### Training
- [ ] Admin panel walkthrough completed
- [ ] Tenant management explained
- [ ] Basic troubleshooting guide provided
- [ ] Support contact information provided

---

## ✅ Go-Live Preparation

### Final Checks (Day Before)
- [ ] Full system backup created
- [ ] All credentials verified
- [ ] DNS propagation complete (24+ hours)
- [ ] SSL certificates valid and trusted
- [ ] Load testing completed (if applicable)
- [ ] Rollback plan documented

### Go-Live Day
- [ ] Announce maintenance window (if switching from old system)
- [ ] Final data migration (if applicable)
- [ ] Monitor logs for errors
- [ ] Test critical workflows
- [ ] Verify email notifications
- [ ] Check background jobs running

### Post Go-Live (First Week)
- [ ] Monitor system performance daily
- [ ] Check error logs frequently
- [ ] Verify backup jobs running
- [ ] Monitor disk space usage
- [ ] Collect user feedback
- [ ] Address any issues immediately

---

## ✅ Ongoing Maintenance Tasks

### Daily
- [ ] Check health endpoints
- [ ] Review error logs
- [ ] Monitor disk space

### Weekly
- [ ] Review backup success
- [ ] Check SSL certificate expiry (90 days warning)
- [ ] Review system performance metrics
- [ ] Update Docker images if needed

### Monthly
- [ ] Security updates (OS packages)
- [ ] Docker image updates
- [ ] Database optimization (ANALYZE, OPTIMIZE)
- [ ] Cleanup old logs and backups
- [ ] Review user feedback

---

## 🆘 Emergency Contacts

**System Issues:**
- Support Email: nxtwebmasters@gmail.com
- Phone: +92 312 8776604

**Critical Commands:**
```bash
# View logs
docker-compose logs -f

# Restart all services
docker-compose restart

# Stop system
docker-compose down

# Start system
docker-compose up -d

# Database backup
sudo /usr/local/bin/hms-backup.sh
```

---

## 📊 Production Status Summary

**Status Indicators:**
- 🟢 **Ready**: All checks passed, ready for production
- 🟡 **Warning**: Minor issues, can proceed with caution
- 🔴 **Not Ready**: Critical issues, must fix before production

**Sign-Off:**
- [ ] Infrastructure team approved
- [ ] Development team approved
- [ ] Security team approved
- [ ] Client approval received
- [ ] Go-live date scheduled: _______________

---

**Last Updated**: February 2026  
**Version**: 1.0  
**Next Review**: [Schedule quarterly reviews]
