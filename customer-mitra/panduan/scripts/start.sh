#!/bin/bash

# 🚀 Quick Start Script untuk Admin Panel dengan Laravel Backend
# Script ini akan membantu setup dan menjalankan admin panel

set -e  # Exit on error

echo "🎯 NEBENG ADMIN PANEL - QUICK START"
echo "===================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    echo -e "${RED}❌ Error: package.json not found!${NC}"
    echo "Please run this script from the admin directory"
    exit 1
fi

echo -e "${GREEN}✓${NC} Running from admin directory"
echo ""

# Step 1: Check Node.js
echo "📦 Step 1: Checking Node.js..."
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js not found! Please install Node.js first${NC}"
    exit 1
fi
echo -e "${GREEN}✓${NC} Node.js version: $(node -v)"
echo ""

# Step 2: Check .env file
echo "🔧 Step 2: Checking .env file..."
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}⚠ .env file not found. Creating from .env.example...${NC}"
    if [ -f ".env.example" ]; then
        cp .env.example .env
        echo -e "${GREEN}✓${NC} .env file created"
    else
        echo -e "${RED}❌ .env.example not found!${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✓${NC} .env file exists"
fi

# Verify API URL in .env
API_URL=$(grep VITE_API_URL .env | cut -d '=' -f2)
echo "   API URL: $API_URL"
if [ "$API_URL" != "http://localhost:8000/api/admin" ]; then
    echo -e "${YELLOW}⚠ Warning: API URL is not pointing to Laravel backend${NC}"
    echo "   Expected: http://localhost:8000/api/admin"
    echo "   Current: $API_URL"
fi
echo ""

# Step 3: Install dependencies
echo "📥 Step 3: Installing dependencies..."
if command -v bun &> /dev/null; then
    echo "   Using bun..."
    bun install
elif command -v npm &> /dev/null; then
    echo "   Using npm..."
    npm install
else
    echo -e "${RED}❌ Neither npm nor bun found!${NC}"
    exit 1
fi
echo -e "${GREEN}✓${NC} Dependencies installed"
echo ""

# Step 4: Check Laravel backend
echo "🔍 Step 4: Checking Laravel backend..."
echo "   Checking if Laravel backend is running at http://localhost:8000..."

if curl -s http://localhost:8000/api/v1/health > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Laravel backend is running!"
else
    echo -e "${YELLOW}⚠ Laravel backend is not running${NC}"
    echo ""
    echo "To start Laravel backend:"
    echo "  cd ../backend"
    echo "  php artisan serve"
    echo ""
    echo -e "${YELLOW}Press Enter when Laravel backend is ready, or Ctrl+C to exit${NC}"
    read -r
fi
echo ""

# Step 5: Show instructions
echo "✅ Setup Complete!"
echo ""
echo "📝 Next Steps:"
echo ""
echo "1. Make sure Laravel backend is running:"
echo "   cd ../backend"
echo "   php artisan serve"
echo ""
echo "2. Start admin frontend:"
echo "   npm run dev    (or bun run dev)"
echo ""
echo "3. Open browser:"
echo "   http://localhost:5173"
echo ""
echo "4. Login dengan default admin account:"
echo "   Email: admin@nebeng.com"
echo "   Password: password123"
echo ""
echo "📚 Documentation:"
echo "   - Backend Migration Guide: ./BACKEND_MIGRATION.md"
echo "   - API Documentation: ../backend/routes/api.php"
echo ""
echo -e "${GREEN}🚀 Ready to go!${NC}"
echo ""

# Ask if user wants to start dev server
echo -e "${YELLOW}Do you want to start the dev server now? (y/n)${NC}"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo ""
    echo "🚀 Starting dev server..."
    if command -v bun &> /dev/null; then
        bun run dev
    else
        npm run dev
    fi
fi
