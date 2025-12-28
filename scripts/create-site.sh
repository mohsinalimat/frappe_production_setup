#!/bin/bash

# ==============================================================================
# Frappe Docker - Create Site Script
# ==============================================================================
# This script creates a new Frappe/ERPNext site
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "Frappe Docker - Create New Site"
echo "=========================================="
echo ""

cd "$PROJECT_DIR"

# Check if docker-compose.yml exists
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ docker-compose.yml not found!"
    echo "Please deploy first using:"
    echo "  ./scripts/deploy-production.sh"
    echo "  or"
    echo "  ./scripts/deploy-development.sh"
    exit 1
fi

# Check if services are running
if ! docker compose ps --status running | grep -q "backend"; then
    echo "❌ Services are not running!"
    echo "Please start services first:"
    echo "  docker compose up -d"
    exit 1
fi

# Load environment variables safely (avoid executing backticks)
if [ -f ".env" ]; then
    while IFS='=' read -r key value; do
        # Skip comments and empty lines
        [[ $key =~ ^#.*$ ]] && continue
        [[ -z $key ]] && continue
        # Remove leading/trailing whitespace
        key=$(echo "$key" | xargs)
        value=$(echo "$value" | xargs)
        # Export the variable
        export "$key=$value"
    done < <(grep -v '^[[:space:]]*$' .env)
fi

# Get site name
echo "📝 Enter site details:"
echo ""
read -p "Site name (e.g., erp.example.com or site1.localhost): " SITE_NAME

if [ -z "$SITE_NAME" ]; then
    echo "❌ Site name cannot be empty"
    exit 1
fi

# Get admin password
read -sp "Administrator password: " ADMIN_PASSWORD
echo ""

if [ -z "$ADMIN_PASSWORD" ]; then
    echo "❌ Admin password cannot be empty"
    exit 1
fi

# Get MariaDB root password from .env
DB_PASS="${DB_PASSWORD}"

if [ -z "$DB_PASS" ]; then
    read -sp "Database root password: " DB_PASS
    echo ""
fi

# Get list of available apps
echo ""
echo "🔍 Detecting available apps in the Docker image..."
AVAILABLE_APPS=$(docker compose exec -T backend bash -c "ls -1 apps 2>/dev/null | grep -v apps.txt | grep -v frappe" || echo "")

if [ -z "$AVAILABLE_APPS" ]; then
    echo "⚠️  Could not detect apps. Using defaults."
    AVAILABLE_APPS="erpnext
hrms
payments"
fi

echo ""
echo "📦 Available apps:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Create arrays for apps
APP_ARRAY=()
i=1
while IFS= read -r app; do
    [ -z "$app" ] && continue
    echo "  $i) $app"
    APP_ARRAY+=("$app")
    ((i++))
done <<< "$AVAILABLE_APPS"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Note: 'frappe' is installed by default"
echo ""
echo "Select apps to install:"
echo "  • Enter numbers separated by space (e.g., 1 2 3)"
echo "  • Enter 'all' to install all apps"
echo "  • Press Enter to skip (frappe only)"
echo ""
read -p "Your choice: " APP_SELECTION

INSTALL_APPS=""

if [ "$APP_SELECTION" = "all" ]; then
    echo ""
    echo "✅ Installing all available apps"
    for app in "${APP_ARRAY[@]}"; do
        INSTALL_APPS="$INSTALL_APPS --install-app $app"
    done
elif [ -n "$APP_SELECTION" ]; then
    echo ""
    echo "✅ Selected apps:"
    for num in $APP_SELECTION; do
        # Validate number
        if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le "${#APP_ARRAY[@]}" ]; then
            idx=$((num-1))
            app="${APP_ARRAY[$idx]}"
            echo "  • $app"
            INSTALL_APPS="$INSTALL_APPS --install-app $app"
        else
            echo "  ⚠️  Invalid selection: $num (skipped)"
        fi
    done
else
    echo ""
    echo "ℹ️  Installing frappe only (no apps selected)"
fi

echo ""
echo "🚀 Creating site: $SITE_NAME"
echo "   Apps to install: ${INSTALL_APPS:-frappe only}"
echo ""

# Create the site
docker compose exec backend \
    bench new-site "$SITE_NAME" \
    --mariadb-root-password "$DB_PASS" \
    --admin-password "$ADMIN_PASSWORD" \
    $INSTALL_APPS \
    --force

echo ""
echo "=========================================="
echo "✅ Site created successfully!"
echo "=========================================="
echo ""
echo "Site: $SITE_NAME"
echo "Username: Administrator"
echo "Password: [your password]"
echo ""

# Set the site for bench commands
echo "🔧 Setting as current site..."
docker compose exec backend bench use "$SITE_NAME"

# Configure HTTPS for production sites
echo "🔒 Configuring HTTPS..."
docker compose exec -T backend bench --site "$SITE_NAME" set-config host_name "https://$SITE_NAME"

echo ""
echo "🌐 Access your site:"
if [ -n "$SITES" ]; then
    echo "  https://$SITE_NAME"
else
    echo "  http://localhost:${HTTP_PUBLISH_PORT:-8080}"
fi
echo ""
echo "📝 Common operations:"
echo "  - Backup site: ./scripts/backup.sh"
echo "  - Access shell: docker compose exec backend bash"
echo "  - View logs: docker compose logs -f backend"
echo ""
