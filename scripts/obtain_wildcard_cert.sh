#!/bin/bash
# obtain_wildcard_cert.sh
# Helper to obtain a wildcard Let's Encrypt certificate using certbot (manual DNS-01)
# Intended to run on the Contabo Ubuntu host as root or via sudo.

set -euo pipefail

# Usage: sudo ./obtain_wildcard_cert.sh yourdomain.com youremail@domain.com
# Example: sudo ./obtain_wildcard_cert.sh example.com admin@example.com

DOMAIN="$1"
EMAIL="$2"

if [ -z "$DOMAIN" ] || [ -z "$EMAIL" ]; then
  echo "Usage: sudo $0 <yourdomain.com> <youremail@domain.com>"
  exit 1
fi

echo "This script will launch certbot in manual (DNS) mode for:\n  $DOMAIN and *.$DOMAIN"
echo "You will be prompted to create DNS TXT records at your DNS provider (HosterPK)."
read -p "Proceed? (y/N) " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
  echo "Aborted."
  exit 1
fi

# Ensure certbot is installed
if ! command -v certbot >/dev/null 2>&1; then
  echo "certbot not found. Installing certbot..."
  apt update
  apt install -y certbot
fi

# Run certbot in manual DNS mode
# Use --manual-public-ip-logging-ok to suppress warning about public IP logging
# certbot will print TXT values to add for _acme-challenge.<domain>

sudo certbot certonly --manual \
  --preferred-challenges dns \
  --manual-public-ip-logging-ok \
  -d "$DOMAIN" -d "*.$DOMAIN" \
  --agree-tos --no-eff-email \
  --email "$EMAIL"

CERT_PATH="/etc/letsencrypt/live/$DOMAIN"

if [ -d "$CERT_PATH" ]; then
  echo "\nCertificate obtained successfully for $DOMAIN"
  echo "Certificates are available under: $CERT_PATH"
  echo "Make sure your Dockerized nginx mounts /etc/letsencrypt (read-only) so the container can access certs." 
  echo "Example docker-compose mount already configured: - /etc/letsencrypt:/etc/letsencrypt:ro"
  echo "\nReload nginx inside docker compose to pick up new certs:" 
  echo "  docker compose -f /path/to/nxt-hospital-skeleton-project/docker-compose.yml exec nginx nginx -t && docker compose -f /path/to/nxt-hospital-skeleton-project/docker-compose.yml exec nginx nginx -s reload"
else
  echo "\nCertificate issuance did not produce expected cert files at $CERT_PATH"
  exit 1
fi

# Suggest renewal cron job
cat <<'EOF'

Next steps:
1) Add a renewal cron (run as root) to auto-renew certs twice daily and reload nginx on successful renew:

# Run with root privileges (crontab -e as root)
0 */12 * * * certbot renew --deploy-hook "docker compose -f /path/to/nxt-hospital-skeleton-project/docker-compose.yml exec nginx nginx -t && docker compose -f /path/to/nxt-hospital-skeleton-project/docker-compose.yml exec nginx nginx -s reload" >> /var/log/letsencrypt/renew.log 2>&1

2) When HosterPK asks for TXT records during certbot run, add a TXT record for _acme-challenge.<domain> with the value provided by certbot. Wait a few seconds for propagation and press Enter in the certbot prompt.

EOF
