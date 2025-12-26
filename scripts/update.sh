#!/bin/bash

# ==============================================================================
# Frappe Docker - Update Script
# ==============================================================================
# This script updates Frappe/ERPNext to the latest version
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "Frappe Docker - Update Frappe/ERPNext"
echo "=========================================="
echo ""

cd "$PROJECT_DIR"

# Check if services are running
if ! docker compose ps | grep -q "backend.*running"; then
    echo "❌ Services are not running!"
    exit 1
fi

echo "⚠️  IMPORTANT: Before updating:"
echo "1. Make sure you have a recent backup"
echo "2. Test updates on staging environment first"
echo "3. Plan for downtime during update"
echo ""

read -p "Have you backed up your sites? (y/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Please backup first: ./scripts/backup.sh"
    exit 1
fi

# Load environment
if [ -f ".env" ]; then
    source .env
fi

echo "📋 Current configuration:"
echo "  Image: ${CUSTOM_IMAGE:-frappe/erpnext}"
echo "  Tag: ${CUSTOM_TAG:-$ERPNEXT_VERSION}"
echo ""

read -p "Update to latest version? (y/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Update cancelled."
    exit 1
fi

echo ""
echo "🔄 Pulling latest images..."
docker compose pull

echo ""
echo "🔄 Restarting containers with new images..."
docker compose up -d

echo ""
echo "⏳ Waiting for services to be ready..."
sleep 10

# Get list of sites
echo "📋 Detecting sites..."
SITES_LIST=$(docker compose exec -T backend ls sites | grep -v "apps.txt\|assets\|common_site_config.json" || true)

if [ -z "$SITES_LIST" ]; then
    echo "❌ No sites found!"
    exit 1
fi

echo "Found sites:"
echo "$SITES_LIST"
echo ""

# Migrate each site
for SITE in $SITES_LIST; do
    # Clean site name
    SITE=$(echo "$SITE" | tr -d '\r')
    
    if [ -z "$SITE" ]; then
        continue
    fi
    
    echo "🔄 Migrating site: $SITE"
    
    # Run migrate
    docker compose exec -T backend bench --site "$SITE" migrate
    
    # Clear cache
    docker compose exec -T backend bench --site "$SITE" clear-cache
    
    # Build assets
    docker compose exec -T backend bench --site "$SITE" build --force
    
    echo "✅ Migration completed: $SITE"
    echo ""
done

echo ""
echo "=========================================="
echo "✅ Update completed successfully!"
echo "=========================================="
echo ""
echo "🔄 Restarting services..."
docker compose restart

echo ""
echo "✅ All services restarted"
echo ""
echo "🌐 Check your sites to verify everything works correctly"
echo ""
