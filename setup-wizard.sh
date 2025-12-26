#!/bin/bash

# ==============================================================================
# Frappe Docker - Initial Setup Wizard
# ==============================================================================
# This interactive script guides you through the initial setup
# ==============================================================================

set -e

echo "=========================================="
echo "Frappe/ERPNext Production Setup Wizard"
echo "=========================================="
echo ""
echo "This wizard will help you set up Frappe/ERPNext on your server."
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    echo "⚠️  Warning: Running as root"
    echo "It's recommended to use a non-root user with sudo access."
    echo ""
fi

# Step 1: Check prerequisites
echo "📋 Step 1: Checking prerequisites..."
echo ""

MISSING_DEPS=0

if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed"
    MISSING_DEPS=1
else
    echo "✅ Docker is installed ($(docker --version))"
fi

if ! docker compose version &> /dev/null 2>&1; then
    echo "❌ Docker Compose is not installed"
    MISSING_DEPS=1
else
    echo "✅ Docker Compose is installed ($(docker compose version))"
fi

if ! command -v git &> /dev/null; then
    echo "❌ Git is not installed"
    MISSING_DEPS=1
else
    echo "✅ Git is installed ($(git --version))"
fi

echo ""

if [ $MISSING_DEPS -eq 1 ]; then
    echo "🔧 Missing prerequisites detected."
    read -p "Would you like to install them now? (y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo ./scripts/install-prerequisites.sh
    else
        echo "Please install missing prerequisites manually and run this script again."
        exit 1
    fi
fi

# Step 2: Deployment type
echo "=========================================="
echo "📋 Step 2: Choose deployment type"
echo "=========================================="
echo ""
echo "1) Production (with SSL/HTTPS) - Recommended for live sites"
echo "2) Development (no SSL) - For local testing"
echo ""
read -p "Select deployment type (1 or 2): " DEPLOY_TYPE

if [ "$DEPLOY_TYPE" = "1" ]; then
    PRODUCTION=true
    echo "✅ Production deployment selected"
else
    PRODUCTION=false
    echo "✅ Development deployment selected"
fi

# Step 3: Configuration
echo ""
echo "=========================================="
echo "📋 Step 3: Configuration"
echo "=========================================="
echo ""

if [ ! -f ".env" ]; then
    cp .env.example .env
    echo "✅ Created .env file from template"
else
    echo "⚠️  .env file already exists"
    read -p "Overwrite with template? (y/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cp .env.example .env
        echo "✅ Overwrote .env file"
    fi
fi

# Database password
echo ""
echo "🔐 Database Configuration"
read -sp "Enter database password (will be saved to .env): " DB_PASS
echo ""

# Update .env with database password
sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=$DB_PASS/" .env

if [ "$PRODUCTION" = true ]; then
    # Production configuration
    echo ""
    echo "🌐 SSL Configuration"
    read -p "Enter your email for Let's Encrypt: " LE_EMAIL
    read -p "Enter your domain name (e.g., erp.example.com): " DOMAIN
    
    # Update .env
    sed -i "s/LETSENCRYPT_EMAIL=.*/LETSENCRYPT_EMAIL=$LE_EMAIL/" .env
    sed -i "s/SITES=.*/SITES=\`$DOMAIN\`/" .env
    
    echo ""
    echo "⚠️  Important: Make sure your domain DNS points to this server!"
    echo "   Domain: $DOMAIN"
    echo "   Should point to: $(curl -s ifconfig.me)"
    echo ""
fi

# Step 4: Custom apps
echo ""
echo "=========================================="
echo "📋 Step 4: Custom Apps"
echo "=========================================="
echo ""
echo "Do you want to customize the apps to install?"
echo "Default apps: ERPNext, HRMS"
echo ""
read -p "Customize apps? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Opening apps.json for editing..."
    echo "Press Enter when done editing..."
    ${EDITOR:-nano} apps.json
    
    BUILD_IMAGE=true
else
    BUILD_IMAGE=false
fi

# Step 5: Build or deploy
echo ""
echo "=========================================="
echo "📋 Step 5: Build & Deploy"
echo "=========================================="
echo ""

if [ "$BUILD_IMAGE" = true ]; then
    echo "🏗️  Building custom image with your apps..."
    ./scripts/build-image.sh
    
    # Update .env to use custom image
    sed -i "s/CUSTOM_IMAGE=.*/CUSTOM_IMAGE=custom-frappe/" .env
    sed -i "s/CUSTOM_TAG=.*/CUSTOM_TAG=latest/" .env
fi

echo ""
echo "🚀 Ready to deploy!"
echo ""
echo "Configuration summary:"
echo "  Deployment: $([ "$PRODUCTION" = true ] && echo "Production (SSL)" || echo "Development")"
echo "  Database: Configured"
if [ "$PRODUCTION" = true ]; then
    echo "  Domain: $DOMAIN"
    echo "  SSL Email: $LE_EMAIL"
fi
if [ "$BUILD_IMAGE" = true ]; then
    echo "  Custom apps: Yes"
fi
echo ""

read -p "Deploy now? (Y/n): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    if [ "$PRODUCTION" = true ]; then
        ./scripts/deploy-production.sh
    else
        ./scripts/deploy-development.sh
    fi
    
    echo ""
    echo "=========================================="
    echo "✅ Setup Complete!"
    echo "=========================================="
    echo ""
    echo "Next steps:"
    echo ""
    echo "1. Wait for all services to start (2-5 minutes)"
    echo "   Check with: docker compose ps"
    echo ""
    echo "2. Create your first site:"
    echo "   ./scripts/create-site.sh"
    echo ""
    if [ "$PRODUCTION" = true ]; then
        echo "3. Access your site: https://$DOMAIN"
    else
        echo "3. Access your site: http://localhost:8080"
    fi
    echo ""
else
    echo "Deployment skipped. You can deploy later with:"
    if [ "$PRODUCTION" = true ]; then
        echo "  ./scripts/deploy-production.sh"
    else
        echo "  ./scripts/deploy-development.sh"
    fi
fi

echo ""
echo "📚 Documentation:"
echo "  README.md - Complete documentation"
echo "  QUICKSTART.md - Quick reference guide"
echo "  MIGRATION.md - Migration from existing setup"
echo ""
echo "🎉 Happy using Frappe/ERPNext!"
echo ""
