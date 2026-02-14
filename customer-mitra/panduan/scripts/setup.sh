#!/bin/bash

# Nebeng Admin - Quick Setup Script
# This script automates the setup process

echo "🚀 Nebeng Admin Backend Setup"
echo "=============================="

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js 18+ first."
    exit 1
fi

echo "✅ Node.js found: $(node --version)"

# Check if MySQL is installed
if ! command -v mysql &> /dev/null; then
    echo "⚠️  MySQL command not found. Make sure MySQL is installed and added to PATH."
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo ""
echo "Step 1: Setup Backend Dependencies"
echo "-----------------------------------"
cd backend
npm install
echo "✅ Dependencies installed"

echo ""
echo "Step 2: Create .env file"
echo "------------------------"
if [ ! -f .env ]; then
    cp .env.example .env
    echo "✅ .env file created from template"
    echo "⚠️  Please edit backend/.env with your MySQL credentials"
else
    echo "ℹ️  .env already exists, skipping..."
fi

echo ""
echo "Step 3: Setup MySQL Database"
echo "-----------------------------"
echo "Would you like to setup the MySQL database now?"
read -p "Setup database? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    read -p "Enter MySQL user (default: root): " -e db_user
    db_user=${db_user:-root}
    
    mysql -u "$db_user" -p < database/schema.sql
    if [ $? -eq 0 ]; then
        echo "✅ Database setup completed"
    else
        echo "❌ Database setup failed"
    fi
else
    echo "ℹ️  Skipping database setup"
    echo "To setup later, run:"
    echo "  mysql -u root -p < backend/database/schema.sql"
fi

echo ""
echo "✅ Setup Complete!"
echo "=================="
echo ""
echo "Next steps:"
echo "1. Edit backend/.env with your database credentials"
echo "2. Run: cd backend && npm run dev"
echo "3. Backend will start at http://localhost:3001"
echo ""
echo "For frontend:"
echo "1. Make sure .env has VITE_API_URL=http://localhost:3001/api"
echo "2. Run: npm run dev (in root directory)"
echo ""
echo "📖 See README_BACKEND.md for more information"
