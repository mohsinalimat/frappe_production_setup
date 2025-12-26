#!/bin/bash

# ==============================================================================
# Frappe Docker - Restore Script
# ==============================================================================
# This script restores a Frappe/ERPNext site from backup
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="$PROJECT_DIR/backups"

echo "=========================================="
echo "Frappe Docker - Restore Site"
echo "=========================================="
echo ""

cd "$PROJECT_DIR"

# Check if services are running
if ! docker compose ps | grep -q "backend.*running"; then
    echo "❌ Services are not running!"
    echo "Start services first: docker compose up -d"
    exit 1
fi

# List available backups
echo "📋 Available backups:"
echo ""

if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A $BACKUP_DIR)" ]; then
    echo "❌ No backups found in $BACKUP_DIR"
    exit 1
fi

# List backup directories
BACKUP_DIRS=($(ls -dt "$BACKUP_DIR"/*/ 2>/dev/null | head -20))

if [ ${#BACKUP_DIRS[@]} -eq 0 ]; then
    echo "❌ No backup directories found"
    exit 1
fi

for i in "${!BACKUP_DIRS[@]}"; do
    BACKUP_NAME=$(basename "${BACKUP_DIRS[$i]}")
    BACKUP_SIZE=$(du -sh "${BACKUP_DIRS[$i]}" | cut -f1)
    echo "  [$i] $BACKUP_NAME ($BACKUP_SIZE)"
done

echo ""
read -p "Select backup number to restore: " BACKUP_INDEX

if [ -z "$BACKUP_INDEX" ] || [ "$BACKUP_INDEX" -ge ${#BACKUP_DIRS[@]} ]; then
    echo "❌ Invalid selection"
    exit 1
fi

SELECTED_BACKUP="${BACKUP_DIRS[$BACKUP_INDEX]}"
echo ""
echo "Selected backup: $(basename "$SELECTED_BACKUP")"
echo ""

# Extract site name from backup directory
BACKUP_NAME=$(basename "$SELECTED_BACKUP")
SITE_NAME=$(echo "$BACKUP_NAME" | sed 's/_[0-9]*$//')

echo "Site name: $SITE_NAME"
echo ""

# Find database and files backup
DB_BACKUP=$(find "$SELECTED_BACKUP" -name "*database.sql.gz" -type f | head -1)
FILES_BACKUP=$(find "$SELECTED_BACKUP" -name "*-files.tar" -type f | head -1)
PRIVATE_FILES=$(find "$SELECTED_BACKUP" -name "*-private-files.tar" -type f | head -1)

if [ -z "$DB_BACKUP" ]; then
    echo "❌ Database backup not found"
    exit 1
fi

echo "Found:"
echo "  Database: $(basename "$DB_BACKUP")"
[ -n "$FILES_BACKUP" ] && echo "  Files: $(basename "$FILES_BACKUP")"
[ -n "$PRIVATE_FILES" ] && echo "  Private Files: $(basename "$PRIVATE_FILES")"
echo ""

read -p "⚠️  This will overwrite existing site data. Continue? (y/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Restore cancelled."
    exit 1
fi

# Copy backup files to container
echo "📦 Copying backup files to container..."
TEMP_BACKUP_DIR="/tmp/restore_$(date +%s)"

docker compose exec -T backend mkdir -p "$TEMP_BACKUP_DIR"
docker compose cp "$DB_BACKUP" backend:"$TEMP_BACKUP_DIR/"

if [ -n "$FILES_BACKUP" ]; then
    docker compose cp "$FILES_BACKUP" backend:"$TEMP_BACKUP_DIR/"
fi

if [ -n "$PRIVATE_FILES" ]; then
    docker compose cp "$PRIVATE_FILES" backend:"$TEMP_BACKUP_DIR/"
fi

# Get MariaDB password
if [ -f ".env" ]; then
    source .env
    DB_PASS="$DB_PASSWORD"
fi

if [ -z "$DB_PASS" ]; then
    read -sp "Database root password: " DB_PASS
    echo ""
fi

# Restore database
echo ""
echo "🔄 Restoring database..."
docker compose exec -T backend bench --site "$SITE_NAME" \
    --force restore \
    --mariadb-root-password "$DB_PASS" \
    "$TEMP_BACKUP_DIR/$(basename "$DB_BACKUP")"

# Restore files if available
if [ -n "$FILES_BACKUP" ]; then
    echo "🔄 Restoring files..."
    docker compose exec -T backend bench --site "$SITE_NAME" \
        restore \
        --with-public-files "$TEMP_BACKUP_DIR/$(basename "$FILES_BACKUP")"
fi

if [ -n "$PRIVATE_FILES" ]; then
    echo "🔄 Restoring private files..."
    docker compose exec -T backend bench --site "$SITE_NAME" \
        restore \
        --with-private-files "$TEMP_BACKUP_DIR/$(basename "$PRIVATE_FILES")"
fi

# Clean up
echo "🧹 Cleaning up..."
docker compose exec -T backend rm -rf "$TEMP_BACKUP_DIR"

echo ""
echo "=========================================="
echo "✅ Site restored successfully!"
echo "=========================================="
echo ""
echo "Site: $SITE_NAME"
echo ""
echo "🔄 Rebuilding cache and assets..."
docker compose exec -T backend bench --site "$SITE_NAME" migrate
docker compose exec -T backend bench --site "$SITE_NAME" clear-cache
docker compose exec -T backend bench --site "$SITE_NAME" build

echo ""
echo "✅ Restore completed!"
echo ""
