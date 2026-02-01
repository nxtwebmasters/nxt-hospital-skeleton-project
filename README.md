# NXT HMS - Multi-Tenant Hospital Management System
## Production Deployment Skeleton

[![License](https://img.shields.io/badge/license-ISC-blue.svg)](LICENSE)
[![Docker](https://img.shields.io/badge/docker-compose-blue.svg)](docker-compose.yml)
[![Production Ready](https://img.shields.io/badge/production-ready-green.svg)]()

A complete, production-ready Docker Compose deployment for the NXT Hospital Management System. Designed for multi-tenant SaaS hospital networks with tenant isolation, automated deployments, and enterprise features.

---

## 🚀 Quick Start (5 Minutes)

```bash
# 1. Clone and navigate
git clone <repository-url>
cd nxt-hospital-skeleton-project

# 2. Configure deployment
cp deployment-config.sh deployment-config.local.sh
nano deployment-config.local.sh
# Set: DEPLOYMENT_DOMAIN and DEFAULT_TENANT_SUBDOMAIN

# 3. Deploy
chmod +x deploy.sh
./deploy.sh

# 4. Access
# Open: https://<your-domain>/
```

**That's it!** The deployment script handles everything: Docker setup, database initialization, SSL certificates, and health monitoring.

---

## 📋 What's Included

### Core Services
- **Backend API** (`hms-backend`) - Node.js/Express with cluster mode, BullMQ workers, schedulers
- **Admin Frontend** (`hospital-frontend`) - Angular 13 SPA for hospital staff
- **Patient Portal** (`customer-portal`) - Angular 13 portal for patients
- **Database** (MySQL 8.0) - Multi-tenant schema with automatic initialization
- **Cache/Queue** (Redis 7.2) - Session management and job queues
- **Reverse Proxy** (Nginx 1.25) - SSL termination, routing, static files

### Key Features
✅ **Multi-Tenant Architecture** - Complete tenant isolation (data, files, users)  
✅ **Automated Deployment** - Single script deploys entire stack  
✅ **Generic Configuration** - Deploy to any domain/tenant without code changes  
✅ **SSL/TLS Ready** - Automatic Let's Encrypt wildcard certificates  
✅ **Health Monitoring** - Built-in health checks and auto-restart  
✅ **Automated Backups** - Daily database backups with email notifications  
✅ **Background Jobs** - Campaign processing, expiry checks, stock alerts  
✅ **Production Hardening** - Firewall, security headers, rate limiting

---

## 🎯 Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Nginx (Reverse Proxy)                    │
│          SSL Termination | Static Files | Routing           │
└────────────┬──────────────────────┬────────────┬────────────┘
             │                      │            │
    ┌────────▼────────┐   ┌────────▼──────┐   ┌▼──────────┐
    │ Admin Frontend  │   │ Patient Portal│   │ Backend API│
    │   (Angular 13)  │   │  (Angular 13) │   │  (Node.js) │
    └─────────────────┘   └───────────────┘   └─────┬──────┘
                                                     │
                                    ┌────────────────┼───────────────┐
                                    │                │               │
                              ┌─────▼────┐    ┌─────▼────┐   ┌─────▼────┐
                              │  MySQL   │    │  Redis   │   │  Workers │
                              │ Database │    │  Cache   │   │ (BullMQ) │
                              └──────────┘    └──────────┘   └──────────┘
```

### Multi-Tenancy Model

```
Domain Structure:
  hms.yourdomain.com                → Default Tenant (hms)
  hospital1-hms.yourdomain.com      → Tenant: hospital1-hms
  citycare-hms.yourdomain.com       → Tenant: citycare-hms

Isolation:
  ✓ Database: tenant_id column in all tables
  ✓ Files: /images/<tenant_id>/<category>/
  ✓ Users: Scoped to tenant_id
  ✓ API: Middleware enforces tenant context
```

---

## 🔧 Configuration

### Deployment Configuration

The system uses a simple configuration file for all deployment settings:

**File**: `deployment-config.local.sh` (git-ignored)

```bash
# Required: Domain and Tenant
DEPLOYMENT_DOMAIN="hms.yourdomain.com"  # Your domain (or empty for IP)
DEFAULT_TENANT_SUBDOMAIN="hms"           # Your base tenant identifier

# Deployment Mode
DEPLOYMENT_MODE="https"  # http or https

# Email (for notifications and SSL)
SMTP_EMAIL="noreply@yourdomain.com"
SMTP_PASSWORD="your-app-password"
ADMIN_EMAILS="admin1@domain.com,admin2@domain.com"

# Optional: Pre-configure integrations
ENABLE_WHATSAPP="true"
MSGPK_WHATSAPP_API_KEY="your-key"
OPENAI_API_KEY="sk-..."
FBR_INTEGRATION_ENABLED="true"
```

**Security**: Passwords and JWT secrets are auto-generated securely.

### Configuration for Different Environments

```bash
# Production
deployment-config.local.sh
  DEPLOYMENT_DOMAIN="hms.yourdomain.com"
  DEFAULT_TENANT_SUBDOMAIN="hms"
  DEPLOYMENT_MODE="https"

# Staging
deployment-config.staging.sh
  DEPLOYMENT_DOMAIN="staging.yourdomain.com"
  DEFAULT_TENANT_SUBDOMAIN="hms-staging"
  DEPLOYMENT_MODE="https"

# Development
deployment-config.dev.sh
  DEPLOYMENT_DOMAIN=""  # Uses VM IP
  DEFAULT_TENANT_SUBDOMAIN="hms-dev"
  DEPLOYMENT_MODE="http"
```

---

## 📦 Deployment Options

### Option 1: Automated (Recommended)

```bash
# One-time setup
cp deployment-config.sh deployment-config.local.sh
nano deployment-config.local.sh  # Configure once

# Deploy anytime
./deploy.sh
```

### Option 2: Custom Config

```bash
# Use environment-specific configs
./deploy.sh --config deployment-config.production.sh
./deploy.sh --config deployment-config.staging.sh
```

### Option 3: Interactive

```bash
# Prompts for all settings
./deploy.sh  # Run without config file
```

---

## 🌐 DNS Configuration

### Wildcard DNS (Required for Multi-Tenant)

Configure these records in your DNS provider:

```dns
Type: A
Name: hms
Value: <your-server-ip>

Type: A  
Name: *.hms
Value: <your-server-ip>
```

**Result**: All subdomains automatically route to your server
- `hms.yourdomain.com` ✅
- `hospital1-hms.yourdomain.com` ✅
- `citycare-hms.yourdomain.com` ✅

---

## 🔐 SSL/TLS Certificates

### Automatic (Let's Encrypt)

The deployment script offers automated SSL setup:

**Option 1: Cloudflare DNS (Recommended)**
- Wildcard certificate covering `*.yourdomain.com`
- Automatic renewal
- No downtime

**Option 2: Manual DNS Challenge**
- Step-by-step prompts for DNS TXT records
- Suitable for any DNS provider

**Option 3: HTTP Challenge**
- Single-domain certificates
- Simple but requires separate cert per subdomain

---

## 📊 Monitoring & Health

### Built-in Endpoints

```bash
# System health
curl http://localhost/api-server/health
curl http://localhost/nginx-health

# Status dashboard
http://localhost/status

# Queue monitoring (Bullboard)
http://localhost/admin/queues
```

### Automated Monitoring

The deployment configures:
- ✅ Health check cron (every 5 minutes)
- ✅ Auto-restart failed containers
- ✅ Daily database backups (3 AM)
- ✅ Low disk space alerts

---

## 🗄️ Database Management

### Automatic Initialization

The system automatically:
1. Creates database schema (tables, indexes, views)
2. Sets up permissions and roles
3. Creates stored procedures
4. Initializes bootstrap data

**SQL Files** (auto-executed in order):
- `data/scripts/1-schema.sql` - Table definitions
- `data/scripts/2-permissions.sql` - Access control
- `data/scripts/3-procedures.sql` - Stored procedures
- `data/scripts/4-views.sql` - Database views

### Bootstrap Data

Backend automatically loads:
- Default permissions and user roles
- Hospital departments
- Lab test types
- Service categories
- Tax configurations
- Message templates

```bash
# Check bootstrap status
docker exec api-hospital npm run bootstrap:status

# Force re-bootstrap (caution!)
docker exec api-hospital npm run bootstrap:force
```

---

## 👥 Multi-Tenant Management

### Creating New Tenants

**Via API:**
```bash
curl -X POST https://hms.yourdomain.com/api-server/tenant/create \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <admin-token>" \
  -d '{
    "tenant_name": "City Care Hospital",
    "tenant_subdomain": "citycare-hms",
    "subscription_plan": "premium"
  }'
```

**Response includes:**
- Tenant credentials
- Access URL
- File directory path

**Access**: `https://citycare-hms.yourdomain.com`

### Tenant Isolation

Each tenant gets:
- ✅ Separate data (database rows filtered by `tenant_id`)
- ✅ Isolated files (`/images/<tenant_id>/`)
- ✅ Separate users and permissions
- ✅ Independent configuration (FBR, WhatsApp, etc.)

---

## 🔄 Maintenance Operations

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f hospital-apis
docker-compose logs -f mysql
```

### Restart Services

```bash
# Restart all
docker-compose restart

# Specific service
docker-compose restart hospital-apis

# Full rebuild
docker-compose down
docker-compose up -d
```

### Database Backup

```bash
# Manual backup
sudo /usr/local/bin/hms-backup.sh

# Restore from backup
docker exec -i hospital-mysql mysql -u root -p'<password>' nxt-hospital < backup.sql
```

### Update Deployment

```bash
# Pull latest code
git pull origin main

# Update config if needed
nano deployment-config.local.sh

# Redeploy
./deploy.sh
```

---

## 📁 Directory Structure

```
nxt-hospital-skeleton-project/
├── deploy.sh                          # Main deployment script
├── deployment-config.sh               # Configuration template
├── deployment-config.local.sh         # Your config (git-ignored)
├── docker-compose.yml                 # Service orchestration
├── hms-backend.env                    # Backend environment (auto-generated)
│
├── data/scripts/                      # Database initialization
│   ├── 1-schema.sql
│   ├── 2-permissions.sql
│   ├── 3-procedures.sql
│   └── 4-views.sql
│
├── nginx/                             # Reverse proxy configuration
│   ├── nginx.conf
│   └── conf.d/
│       ├── reverse-proxy-http.conf
│       └── reverse-proxy-https.conf
│
├── images/                            # Tenant file storage (auto-created)
│   └── <tenant_id>/
│
└── docs/                              # Documentation
    ├── GENERIC_DEPLOYMENT_GUIDE.md    # Complete step-by-step guide
    └── (Production documentation)
```

---

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [GENERIC_DEPLOYMENT_GUIDE.md](docs/GENERIC_DEPLOYMENT_GUIDE.md) | Complete step-by-step deployment guide with all scenarios |
| [PRODUCTION-CHECKLIST.md](PRODUCTION-CHECKLIST.md) | Pre/post deployment validation checklist (100+ checks) |

---

## 🛠️ Troubleshooting

### Common Issues

**Issue**: Can't access the application
```bash
# Check services are running
docker-compose ps

# Check logs
docker-compose logs -f hospital-apis

# Verify ports
sudo netstat -tlnp | grep -E ':80|:443'
```

**Issue**: Tenant not found
```bash
# Verify tenant exists
docker exec -it hospital-mysql mysql -u root -p
> USE `nxt-hospital`;
> SELECT * FROM nxt_tenant;

# Check BASE_SUBDOMAIN matches
cat hms-backend.env | grep BASE_SUBDOMAIN
```

**Issue**: SSL certificate errors
```bash
# Verify certificate files
sudo ls -la /etc/letsencrypt/live/<your-domain>/

# Restart nginx
docker-compose restart nginx-reverse-proxy

# Check nginx logs
docker-compose logs nginx-reverse-proxy
```

**Issue**: Database connection errors
```bash
# Check MySQL is ready
docker exec hospital-mysql mysqladmin ping

# Verify credentials match
cat hms-backend.env | grep DB_PASSWORD
cat docker-compose.yml | grep MYSQL_PASSWORD
```

---

## 🔐 Security Best Practices

✅ **Generated Credentials**
- Deploy script auto-generates secure passwords
- JWT secrets are 32-byte random hex
- Credentials saved to `~/.hms_credentials_YYYYMMDD.txt`

✅ **Configuration Security**
- `deployment-config.local.sh` is git-ignored
- Never commit API keys or passwords
- Use environment-specific configs

✅ **SSL/TLS**
- HTTPS enforced in production mode
- Automatic HTTP → HTTPS redirect
- Modern TLS protocols (1.2, 1.3)
- HSTS headers enabled

✅ **Firewall**
- UFW configured automatically
- Only ports 22, 80, 443 open
- Rate limiting on API endpoints

✅ **Database**
- Root password required
- Separate application user
- No remote root access

---

## 📈 Performance & Scalability

### Current Capacity (Single Server)
- **Concurrent Users**: 100-500
- **Database Size**: Up to 100GB
- **File Storage**: Limited by disk
- **Tenants**: 20-50 hospitals

### Scaling Options

**Vertical Scaling**
- Increase VM RAM/CPU
- Add more Redis/MySQL resources

**Horizontal Scaling** (Future)
- Load balancer → Multiple API servers
- Read replicas for MySQL
- Redis cluster for sessions
- S3/MinIO for file storage
- CDN for static assets

---

## 🤝 Support & Contact

- **Email**: nxtwebmasters@gmail.com
- **Phone**: +92 312 8776604
- **GitHub Issues**: [Create an issue](../../issues)

For production deployments, enterprise support, and custom integrations, contact us directly.

---

## 📄 License

ISC License - See [LICENSE](LICENSE) file for details.

---

## 🎉 Quick Success Checklist

After deployment, verify:

- [ ] Can access admin panel: `https://<domain>/`
- [ ] Can access patient portal: `https://<domain>/portal/`
- [ ] Health check passes: `https://<domain>/api-server/health`
- [ ] Can create admin user
- [ ] Can create first patient
- [ ] Can create appointment
- [ ] Queue monitoring accessible: `https://<domain>/admin/queues`
- [ ] SSL certificate valid (if HTTPS)
- [ ] Wildcard DNS resolving (test subdomain)
- [ ] Database backup cron configured
- [ ] Credentials file saved securely

**All green?** 🎉 You're production-ready!

---

## 🚦 Getting Started

For detailed deployment instructions, configuration options, and troubleshooting:

1. **Quick Setup**: Follow the 5-minute quick start above
2. **Complete Guide**: Read [GENERIC_DEPLOYMENT_GUIDE.md](docs/GENERIC_DEPLOYMENT_GUIDE.md)
3. **Production Validation**: Use [PRODUCTION-CHECKLIST.md](PRODUCTION-CHECKLIST.md)

---

**Built with ❤️ by NXT WebMasters**  
*Production-ready multi-tenant hospital management system*
