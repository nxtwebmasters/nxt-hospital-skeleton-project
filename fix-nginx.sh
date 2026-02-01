#!/bin/bash
# Fix nginx crash loop by updating HTTPS config with actual domain

set -e

DOMAIN="nxthms.nxtwebmasters.com"

echo "🔧 Fixing nginx HTTPS configuration..."
echo "   Domain: $DOMAIN"

# Navigate to project directory
cd "$(dirname "$0")"

# Update HTTPS config with actual domain
HTTPS_CONFIG="nginx/conf.d/reverse-proxy-https.conf"

if [ -f "$HTTPS_CONFIG" ]; then
    echo "📝 Updating HTTPS config with domain: $DOMAIN"
    
    # Replace placeholder domain with actual domain
    sed -i "s/YOURDOMAIN\.COM/$DOMAIN/g" "$HTTPS_CONFIG"
    
    echo "✅ Updated certificate paths:"
    echo "   /etc/letsencrypt/live/$DOMAIN/fullchain.pem"
    echo "   /etc/letsencrypt/live/$DOMAIN/privkey.pem"
else
    echo "❌ ERROR: $HTTPS_CONFIG not found!"
    exit 1
fi

# Verify HTTP config exists
if [ ! -f "nginx/conf.d/reverse-proxy-http.conf" ]; then
    echo "❌ ERROR: reverse-proxy-http.conf not found!"
    exit 1
fi

echo "✅ Both HTTP and HTTPS configs are ready"

# Test nginx configuration
echo ""
echo "🔍 Testing nginx configuration..."
docker compose exec nginx nginx -t 2>&1 || {
    echo "❌ Nginx config test failed!"
    echo "Check the error above and verify SSL certificates exist:"
    echo "   ls -la /etc/letsencrypt/live/$DOMAIN/"
    exit 1
}

echo "✅ Nginx configuration is valid"

# Restart nginx container
echo ""
echo "🔄 Restarting nginx container..."
docker compose restart nginx

echo ""
echo "⏳ Waiting for nginx to start..."
sleep 5

# Check nginx status
if docker ps | grep -q "nginx-reverse-proxy.*Up"; then
    echo "✅ Nginx is now running with HTTPS enabled!"
    echo ""
    echo "🌐 Your application is accessible at:"
    echo "   🔓 HTTP:  http://$DOMAIN/"
    echo "   🔒 HTTPS: https://$DOMAIN/"
    echo "   👤 Portal: https://$DOMAIN/portal/"
    echo "   💚 API Health: https://$DOMAIN/api-server/health"
    echo ""
    echo "📝 HTTP traffic will redirect to HTTPS (see reverse-proxy-http.conf)"
else
    echo "❌ Nginx still not running. Check logs:"
    echo "   docker logs nginx-reverse-proxy"
    echo ""
    echo "If SSL certificate errors persist, verify certificates exist:"
    echo "   docker exec nginx-reverse-proxy ls -la /etc/letsencrypt/live/$DOMAIN/"
    exit 1
fi
