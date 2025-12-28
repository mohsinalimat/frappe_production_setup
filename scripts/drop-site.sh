#!/bin/bash

# ==============================================================================
# Frappe Docker - Drop Site Script
# ==============================================================================
# This script removes a site from production
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "Frappe Docker - Drop Site"
echo "=========================================="
echo ""

cd "$PROJECT_DIR"

# Check if docker-compose.yml exists
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ docker-compose.yml not found!"
    echo "Please deploy first using: ./scripts/deploy-production.sh"
    exit 1
fi

# Check if services are running
if ! docker compose ps --status running | grep -q "backend"; then
    echo "❌ Services are not running!"
    echo "Please start services first: docker compose up -d"
    exit 1
fi

# Get list of sites
echo "📋 Available sites:"
echo ""
SITES_LIST=$(docker compose exec -T backend bash -c "ls -1 sites/*/site_config.json 2>/dev/null | cut -d'/' -f2" 2>/dev/null || echo "")

if [ -z "$SITES_LIST" ]; then
    echo "❌ No sites found!"
    exit 1
fi

# Display sites with numbering
SITE_ARRAY=()
i=1
while IFS= read -r site; do
    echo "  $i) $site"
    SITE_ARRAY+=("$site")
    ((i++))
done <<< "$SITES_LIST"

echo ""
echo "=========================================="
echo ""

read -p "Enter site name to drop: " SITE_NAME

if [ -z "$SITE_NAME" ]; then
    echo "❌ Site name cannot be empty"
    exit 1
fi

# Verify site exists
if ! echo "$SITES_LIST" | grep -q "^${SITE_NAME}$"; then
    echo "❌ Site '$SITE_NAME' not found!"
    exit 1
fi

echo ""
echo "⚠️  ⚠️  ⚠️  DANGER ZONE ⚠️  ⚠️  ⚠️"
echo ""
echo "You are about to DROP site: $SITE_NAME"
echo ""
echo "This will:"
echo "  • Delete the site and all its data"
echo "  • Remove the database"
echo "  • Delete all files for this site"
echo "  • This action CANNOT be undone!"
echo ""
echo "=========================================="
echo ""

read -p "Do you want to backup before dropping? (Y/n): " -n 1 -r
echo ""
BACKUP_FIRST=${REPLY:-Y}

if [[ $BACKUP_FIRST =~ ^[Yy]$ ]]; then
    echo ""
    echo "📦 Creating backup before dropping..."
    
    BACKUP_DIR="backups"
    mkdir -p "$BACKUP_DIR"
    
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_FILE="${BACKUP_DIR}/${SITE_NAME}_final_backup_${TIMESTAMP}.sql.gz"
    
    echo "Backing up to: $BACKUP_FILE"
    
    docker compose exec -T backend bench --site "$SITE_NAME" backup --with-files
    
    # Copy backup from container
    CONTAINER_BACKUP=$(docker compose exec -T backend bash -c "ls -t sites/${SITE_NAME}/private/backups/*.sql.gz | head -1" | tr -d '\r')
    
    if [ -n "$CONTAINER_BACKUP" ]; then
        docker compose cp backend:"$CONTAINER_BACKUP" "$BACKUP_FILE"
        echo "✅ Backup saved to: $BACKUP_FILE"
    else
        echo "⚠️  Could not locate backup file"
    fi
    
    echo ""
fi

echo "To confirm deletion, type the site name exactly: $SITE_NAME"
read -p "Site name: " CONFIRM_SITE_NAME

if [ "$CONFIRM_SITE_NAME" != "$SITE_NAME" ]; then
    echo "❌ Site name does not match. Cancelling."
    exit 1
fi

echo ""
read -p "Are you ABSOLUTELY sure? This cannot be undone! (yes/NO): " FINAL_CONFIRM

if [ "$FINAL_CONFIRM" != "yes" ]; then
    echo "Cancelled."
    exit 1
fi

echo ""
echo "🗑️  Dropping site: $SITE_NAME"
echo ""

# Drop the site
docker compose exec -T backend bench drop-site "$SITE_NAME" --force --no-backup

if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "✅ Site Dropped Successfully!"
    echo "=========================================="
    echo ""
    echo "Site: $SITE_NAME has been removed"
    if [[ $BACKUP_FIRST =~ ^[Yy]$ ]]; then
        echo "Backup: $BACKUP_FILE"
    fi
    echo ""
    echo "Remaining sites:"
    docker compose exec -T backend bash -c "ls -1 sites/*/site_config.json 2>/dev/null | cut -d'/' -f2" || echo "  No sites remaining"
    echo ""
else
    echo ""
    echo "❌ Failed to drop site!"
    echo "The site may still be active or in use."
    echo ""
    echo "Try:"
    echo "  1. Stop the site first"
    echo "  2. Check logs: docker compose logs backend"
    echo "  3. Manual drop: docker compose exec backend bench drop-site $SITE_NAME"
    exit 1
fi
