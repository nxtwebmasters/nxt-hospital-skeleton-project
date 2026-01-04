#!/bin/bash
# Frontend Performance Fix Deployment Script
# Run this on production server after rebuilding frontend image

set -e  # Exit on error

echo "=========================================="
echo "Frontend Performance Fix Deployment"
echo "=========================================="
echo ""

# Check if running on production server
if [ ! -d ~/nxt-hospital-skeleton-project ]; then
    echo "❌ Error: Not in production environment"
    echo "Expected directory: ~/nxt-hospital-skeleton-project"
    exit 1
fi

cd ~/nxt-hospital-skeleton-project

echo "Step 1: Pulling latest configuration changes..."
git pull origin main || {
    echo "⚠️  Git pull failed - continuing with local changes"
}

echo ""
echo "Step 2: Backing up current docker-compose.yml..."
cp docker-compose.yml docker-compose.yml.backup-$(date +%Y%m%d-%H%M%S)

echo ""
echo "Step 3: Updating frontend image version..."
echo "Current frontend image:"
grep "pandanxt/hospital-frontend" docker-compose.yml | head -1

echo ""
echo "⚠️  MANUAL ACTION REQUIRED:"
echo "Edit docker-compose.yml and update hospital-frontend image to:"
echo "  image: pandanxt/hospital-frontend:performance-fix-v1"
echo ""
read -p "Press Enter after updating the image tag..."

echo ""
echo "Step 4: Testing nginx configuration..."
docker exec nginx-reverse-proxy nginx -t || {
    echo "❌ Nginx config test failed!"
    echo "Run: docker exec nginx-reverse-proxy nginx -t"
    exit 1
}

echo ""
echo "Step 5: Restarting nginx reverse proxy..."
docker compose restart nginx

echo ""
echo "Step 6: Pulling new frontend image..."
docker compose pull hospital-frontend

echo ""
echo "Step 7: Restarting frontend container..."
docker compose up -d hospital-frontend

echo ""
echo "Step 8: Waiting for frontend to be healthy..."
sleep 10

echo ""
echo "Step 9: Verifying deployment..."
echo ""

# Check if gzip is enabled
echo "Testing gzip compression..."
GZIP_CHECK=$(curl -sI -H "Accept-Encoding: gzip" https://hms.nxtwebmasters.com/ | grep -i "content-encoding: gzip" || echo "NOT FOUND")

if [ "$GZIP_CHECK" != "NOT FOUND" ]; then
    echo "✅ Gzip compression: ENABLED"
else
    echo "⚠️  Gzip compression: NOT DETECTED (may need container rebuild)"
fi

# Check container status
echo ""
echo "Container status:"
docker compose ps hospital-frontend

echo ""
echo "Recent logs:"
docker compose logs --tail 20 hospital-frontend

echo ""
echo "=========================================="
echo "Deployment Summary"
echo "=========================================="
echo ""
echo "✅ Nginx configuration updated"
echo "✅ Frontend container restarted"
echo ""
echo "Next Steps:"
echo "1. Test in browser: https://hms.nxtwebmasters.com/"
echo "2. Open DevTools → Network tab"
echo "3. Verify main.*.js shows 'gzip' encoding"
echo "4. Verify load time < 10 seconds"
echo ""
echo "If issues persist:"
echo "- Check logs: docker compose logs hospital-frontend"
echo "- Verify nginx: docker exec nginx-reverse-proxy nginx -t"
echo "- Check gzip: curl -I -H 'Accept-Encoding: gzip' https://hms.nxtwebmasters.com/"
echo ""
echo "For Phase 2 (bundle size reduction), see:"
echo "docs/FRONTEND_LOADING_ISSUE_CRITICAL_FIX.md"
echo ""
