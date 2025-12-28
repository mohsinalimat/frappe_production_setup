#!/bin/bash

# ==============================================================================
# Frappe Docker - Fix HTTPS/SSL Configuration
# ==============================================================================
# This script diagnoses and fixes HTTPS/SSL issues
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "Frappe Docker - Fix HTTPS/SSL"
echo "=========================================="
echo ""

cd "$PROJECT_DIR"

# Check if docker-compose.yml exists
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ docker-compose.yml not found!"
    exit 1
fi

# Check if services are running
if ! docker compose ps --status running | grep -q "backend"; then
    echo "❌ Services are not running!"
    exit 1
fi

# Get list of sites
echo "🔍 Detecting sites..."
SITES_LIST=$(docker compose exec -T backend bash -c "ls -1 sites/*/site_config.json 2>/dev/null | cut -d'/' -f2" 2>/dev/null || echo "")

if [ -z "$SITES_LIST" ]; then
    echo "❌ No sites found!"
    exit 1
fi

echo "📋 Available sites:"
echo ""
SITE_ARRAY=()
i=1
while IFS= read -r site; do
    echo "  $i) $site"
    SITE_ARRAY+=("$site")
    ((i++))
done <<< "$SITES_LIST"

echo ""
read -p "Select site number to fix: " SITE_NUM

if ! [[ "$SITE_NUM" =~ ^[0-9]+$ ]] || [ "$SITE_NUM" -lt 1 ] || [ "$SITE_NUM" -gt "${#SITE_ARRAY[@]}" ]; then
    echo "❌ Invalid site number"
    exit 1
fi

SITE_NAME="${SITE_ARRAY[$((SITE_NUM-1))]}"

echo ""
echo "✅ Selected site: $SITE_NAME"
echo ""

# Check current configuration
echo "🔍 Checking current configuration..."
echo ""

echo "Current site_config.json:"
docker compose exec -T backend cat "sites/${SITE_NAME}/site_config.json" | grep -E "host_name|db_name" || echo "Could not read config"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check SSL certificates
echo "🔍 Checking SSL certificates..."
if docker compose exec -T proxy ls /etc/traefik/certs 2>/dev/null | grep -q "$SITE_NAME"; then
    echo "✅ SSL certificate found for $SITE_NAME"
else
    echo "⚠️  SSL certificate not found for $SITE_NAME"
    echo ""
    echo "This could mean:"
    echo "  • Let's Encrypt is still processing"
    echo "  • DNS not pointing to this server"
    echo "  • Port 80/443 not accessible"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "🔧 Applying HTTPS fixes..."
echo ""

# Fix 1: Set host_name to https://
echo "1️⃣  Setting host_name to https://${SITE_NAME}..."
docker compose exec -T backend bench --site "$SITE_NAME" set-config host_name "https://${SITE_NAME}"

# Fix 2: Enable SSL preference
echo "2️⃣  Enabling SSL preference..."
docker compose exec -T backend bench --site "$SITE_NAME" set-config ssl 1

# Fix 3: Clear cache
echo "3️⃣  Clearing cache..."
docker compose exec -T backend bench --site "$SITE_NAME" clear-cache

# Fix 4: Clear website cache
echo "4️⃣  Clearing website cache..."
docker compose exec -T backend bench --site "$SITE_NAME" clear-website-cache

echo ""
echo "✅ Configuration updated!"
echo ""

# Check if we need to restart
read -p "Restart containers to apply changes? (Y/n): " -n 1 -r
echo ""
RESTART=${REPLY:-Y}

if [[ $RESTART =~ ^[Yy]$ ]]; then
    echo ""
    echo "♻️  Restarting containers..."
    docker compose restart backend frontend
    
    echo ""
    echo "⏳ Waiting for services to be ready..."
    sleep 10
fi

echo ""
echo "=========================================="
echo "🔍 Diagnostics"
echo "=========================================="
echo ""

echo "✅ Site configuration:"
docker compose exec -T backend bench --site "$SITE_NAME" get-config host_name || echo "Could not get config"

echo ""
echo "✅ SSL setting:"
docker compose exec -T backend bench --site "$SITE_NAME" get-config ssl || echo "SSL config not set"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "📋 Troubleshooting checklist:"
echo ""
echo "1. DNS Configuration:"
echo "   • Verify DNS: dig $SITE_NAME +short"
echo "   • Should point to this server's IP"
echo ""
echo "2. Firewall:"
echo "   • Port 80 open: sudo ufw allow 80/tcp"
echo "   • Port 443 open: sudo ufw allow 443/tcp"
echo ""
echo "3. Let's Encrypt:"
echo "   • Check logs: docker compose logs proxy | grep $SITE_NAME"
echo "   • Wait 2-3 minutes for certificate generation"
echo ""
echo "4. Force HTTPS in browser:"
echo "   • Clear browser cache"
echo "   • Try incognito/private mode"
echo "   • Access: https://$SITE_NAME (with https://)"
echo ""
echo "5. Check Traefik certificates:"
echo "   • docker compose exec proxy ls -la /etc/traefik/certs"
echo ""

echo "=========================================="
echo "✅ HTTPS Configuration Applied!"
echo "=========================================="
echo ""
echo "Access your site at: https://$SITE_NAME"
echo ""
echo "If still having issues:"
echo "  • Check proxy logs: docker compose logs proxy"
echo "  • Verify DNS propagation: dig $SITE_NAME"
echo "  • Wait a few minutes for SSL cert generation"
echo ""
