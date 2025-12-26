#!/bin/bash

# ==============================================================================
# Frappe Docker - Start Script
# ==============================================================================
# This script starts all Docker containers
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "Frappe Docker - Start Services"
echo "=========================================="
echo ""

cd "$PROJECT_DIR"

# Check if docker-compose.yml exists
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ docker-compose.yml not found!"
    echo "Please deploy first using ./scripts/deploy-production.sh"
    exit 1
fi

echo "🚀 Starting all containers..."
docker compose up -d

echo ""
echo "⏳ Waiting for services to be ready..."
sleep 5

echo ""
echo "📊 Container status:"
docker compose ps

echo ""
echo "=========================================="
echo "✅ Services started!"
echo "=========================================="
echo ""
echo "📝 View logs: ./scripts/logs.sh"
echo "📊 Check status: docker compose ps"
echo ""
