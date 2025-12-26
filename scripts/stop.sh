#!/bin/bash

# ==============================================================================
# Frappe Docker - Stop Script
# ==============================================================================
# This script stops all Docker containers
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "Frappe Docker - Stop Services"
echo "=========================================="
echo ""

cd "$PROJECT_DIR"

# Check if docker-compose.yml exists
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ docker-compose.yml not found!"
    echo "No services to stop."
    exit 1
fi

echo "🛑 Stopping all containers..."
docker compose down

echo ""
echo "=========================================="
echo "✅ All services stopped!"
echo "=========================================="
echo ""
echo "💡 To start again: ./scripts/start.sh"
echo "🗑️  To remove all data: docker compose down -v"
echo ""
