#!/bin/bash

# ==============================================================================
# Frappe Docker - Reset Admin Password
# ==============================================================================
# This script resets the Administrator password for a site
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "Frappe Docker - Reset Admin Password"
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

# Get new password
read -sp "Enter new Administrator password: " NEW_PASSWORD
echo ""

if [ -z "$NEW_PASSWORD" ]; then
    echo "❌ Password cannot be empty"
    exit 1
fi

# Confirm password
read -sp "Confirm new password: " CONFIRM_PASSWORD
echo ""

if [ "$NEW_PASSWORD" != "$CONFIRM_PASSWORD" ]; then
    echo "❌ Passwords do not match"
    exit 1
fi

echo ""
echo "🔄 Resetting Administrator password for: $SITE_NAME"
echo ""

# Reset password
docker compose exec -T backend bench --site "$SITE_NAME" set-admin-password "$NEW_PASSWORD"

if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "✅ Password Reset Successfully!"
    echo "=========================================="
    echo ""
    echo "Site: $SITE_NAME"
    echo "Username: Administrator"
    echo "Password: ********** (your new password)"
    echo ""
    echo "You can now login at:"
    echo "  https://$SITE_NAME"
    echo ""
else
    echo ""
    echo "❌ Failed to reset password!"
    echo "Check logs: docker compose logs backend"
    exit 1
fi
