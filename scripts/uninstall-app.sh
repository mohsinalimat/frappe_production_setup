#!/bin/bash

# ==============================================================================
# Frappe Docker - Uninstall App from Site
# ==============================================================================
# This script uninstalls an app from a site and optionally migrates
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "Frappe Docker - Uninstall App"
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
read -p "Select site number: " SITE_NUM

# Validate site number
if ! [[ "$SITE_NUM" =~ ^[0-9]+$ ]] || [ "$SITE_NUM" -lt 1 ] || [ "$SITE_NUM" -gt "${#SITE_ARRAY[@]}" ]; then
    echo "❌ Invalid site number"
    exit 1
fi

SITE_NAME="${SITE_ARRAY[$((SITE_NUM-1))]}"

echo ""
echo "✅ Selected site: $SITE_NAME"
echo ""

# Get installed apps on this site
echo "🔍 Getting installed apps on $SITE_NAME..."
echo ""

INSTALLED_APPS=$(docker compose exec -T backend bench --site "$SITE_NAME" list-apps 2>/dev/null || echo "")

if [ -z "$INSTALLED_APPS" ]; then
    echo "❌ Could not retrieve installed apps"
    exit 1
fi

echo "📦 Installed apps:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Create array of apps (excluding frappe as it cannot be uninstalled)
APP_ARRAY=()
i=1
while IFS= read -r app; do
    [ -z "$app" ] && continue
    # Skip frappe as it's the core and cannot be uninstalled
    if [ "$app" = "frappe" ]; then
        continue
    fi
    echo "  $i) $app"
    APP_ARRAY+=("$app")
    ((i++))
done <<< "$INSTALLED_APPS"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ ${#APP_ARRAY[@]} -eq 0 ]; then
    echo ""
    echo "ℹ️  Only 'frappe' is installed (cannot be uninstalled)"
    exit 0
fi

echo ""
echo "Note: 'frappe' cannot be uninstalled (core framework)"
echo ""

read -p "Select app number to uninstall: " APP_NUM

# Validate app number
if ! [[ "$APP_NUM" =~ ^[0-9]+$ ]] || [ "$APP_NUM" -lt 1 ] || [ "$APP_NUM" -gt "${#APP_ARRAY[@]}" ]; then
    echo "❌ Invalid app number"
    exit 1
fi

APP_NAME="${APP_ARRAY[$((APP_NUM-1))]}"

echo ""
echo "⚠️  WARNING: You are about to uninstall: $APP_NAME"
echo ""
echo "This will:"
echo "  • Remove the app from site: $SITE_NAME"
echo "  • Delete all app data (doctypes, records, etc.)"
echo "  • This action CANNOT be undone!"
echo ""

read -p "Do you want to backup before uninstalling? (Y/n): " -n 1 -r
echo ""
BACKUP_FIRST=${REPLY:-Y}

if [[ $BACKUP_FIRST =~ ^[Yy]$ ]]; then
    echo ""
    echo "📦 Creating backup before uninstalling..."
    
    BACKUP_DIR="backups"
    mkdir -p "$BACKUP_DIR"
    
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_FILE="${BACKUP_DIR}/${SITE_NAME}_before_uninstall_${APP_NAME}_${TIMESTAMP}.sql.gz"
    
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

read -p "Are you sure you want to uninstall '$APP_NAME'? (yes/NO): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Cancelled."
    exit 1
fi

echo ""
echo "🗑️  Uninstalling app: $APP_NAME from site: $SITE_NAME"
echo ""

# Uninstall the app
docker compose exec -T backend bench --site "$SITE_NAME" uninstall-app "$APP_NAME" --force

if [ $? -ne 0 ]; then
    echo ""
    echo "❌ Failed to uninstall app!"
    echo ""
    echo "This could be because:"
    echo "  • Other apps depend on this app"
    echo "  • App has active data/transactions"
    echo "  • Permission issues"
    echo ""
    exit 1
fi

echo ""
echo "✅ App uninstalled successfully!"
echo ""

# Ask about migration
read -p "Do you want to migrate the site now? (Y/n): " -n 1 -r
echo ""
MIGRATE=${REPLY:-Y}

if [[ $MIGRATE =~ ^[Yy]$ ]]; then
    echo ""
    echo "🔄 Running migration..."
    docker compose exec -T backend bench --site "$SITE_NAME" migrate
    
    echo ""
    echo "♻️  Clearing cache..."
    docker compose exec -T backend bench --site "$SITE_NAME" clear-cache
    
    echo ""
    echo "✅ Migration completed!"
fi

echo ""
echo "=========================================="
echo "✅ Operation Completed Successfully!"
echo "=========================================="
echo ""
echo "Site: $SITE_NAME"
echo "Uninstalled app: $APP_NAME"
if [[ $BACKUP_FIRST =~ ^[Yy]$ ]]; then
    echo "Backup: $BACKUP_FILE"
fi
echo ""
echo "Remaining installed apps:"
docker compose exec -T backend bench --site "$SITE_NAME" list-apps
echo ""
