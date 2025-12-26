#!/bin/bash

# ==============================================================================
# Frappe Docker - Logs Script
# ==============================================================================
# This script displays container logs
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "Frappe Docker - View Logs"
echo "=========================================="
echo ""

cd "$PROJECT_DIR"

# Check if docker-compose.yml exists
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ docker-compose.yml not found!"
    exit 1
fi

# Check if a specific service was requested
if [ -n "$1" ]; then
    echo "📝 Showing logs for: $1"
    echo "   Press Ctrl+C to exit"
    echo ""
    docker compose logs -f "$1"
else
    echo "📝 Showing logs for all services"
    echo "   Press Ctrl+C to exit"
    echo ""
    echo "💡 Tip: To view logs for specific service:"
    echo "   ./scripts/logs.sh backend"
    echo "   ./scripts/logs.sh frontend"
    echo "   ./scripts/logs.sh db"
    echo ""
    docker compose logs -f
fi
