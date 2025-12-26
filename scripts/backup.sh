#!/bin/bash

# ==============================================================================
# Frappe Docker - Backup Script
# ==============================================================================
# This script backs up all Frappe/ERPNext sites
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="$PROJECT_DIR/backups"

echo "=========================================="
echo "Frappe Docker - Backup Sites"
echo "=========================================="
echo ""

cd "$PROJECT_DIR"

# Check if services are running
if ! docker compose ps | grep -q "backend.*running"; then
    echo "❌ Services are not running!"
    exit 1
fi

# Create backup directory
mkdir -p "$BACKUP_DIR"

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

# Backup each site
for SITE in $SITES_LIST; do
    # Clean site name (remove carriage return)
    SITE=$(echo "$SITE" | tr -d '\r')
    
    if [ -z "$SITE" ]; then
        continue
    fi
    
    echo "💾 Backing up site: $SITE"
    
    # Create backup with database and files
    docker compose exec -T backend bench --site "$SITE" backup --with-files
    
    # Get the latest backup files
    echo "📦 Collecting backup files..."
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    SITE_BACKUP_DIR="$BACKUP_DIR/${SITE}_${TIMESTAMP}"
    mkdir -p "$SITE_BACKUP_DIR"
    
    # Copy backup files from container
    docker compose cp backend:/home/frappe/frappe-bench/sites/"$SITE"/private/backups/. "$SITE_BACKUP_DIR/"
    
    echo "✅ Backup completed: $SITE_BACKUP_DIR"
    echo ""
done

echo "=========================================="
echo "✅ All sites backed up successfully!"
echo "=========================================="
echo ""
echo "Backup location: $BACKUP_DIR"
echo ""
echo "💡 Tip: Copy backups to external storage for safety"
echo ""

# Clean old backups (optional)
if [ -n "$BACKUP_RETENTION_DAYS" ] && [ "$BACKUP_RETENTION_DAYS" -gt 0 ]; then
    echo "🧹 Cleaning backups older than $BACKUP_RETENTION_DAYS days..."
    find "$BACKUP_DIR" -type d -mtime +$BACKUP_RETENTION_DAYS -exec rm -rf {} + 2>/dev/null || true
    echo "✅ Old backups cleaned"
fi

echo ""
echo "Backup summary:"
du -sh "$BACKUP_DIR"
echo ""
