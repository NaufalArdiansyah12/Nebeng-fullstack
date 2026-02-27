#!/bin/bash
# Verification script untuk memastikan setup benar

echo "🔍 Nebeng Admin - Backend Verification"
echo "======================================"
echo ""

# Check Node.js
echo "✓ Checking Node.js..."
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    echo "  ✅ Node.js $NODE_VERSION found"
else
    echo "  ❌ Node.js not found"
fi

# Check npm
echo "✓ Checking npm..."
if command -v npm &> /dev/null; then
    NPM_VERSION=$(npm --version)
    echo "  ✅ npm $NPM_VERSION found"
else
    echo "  ❌ npm not found"
fi

# Check MySQL
echo "✓ Checking MySQL..."
if command -v mysql &> /dev/null; then
    echo "  ✅ MySQL found"
else
    echo "  ⚠️  MySQL command not found (might still be installed)"
fi

# Check backend files
echo "✓ Checking backend files..."
BACKEND_FILES=(
    "backend/server.ts"
    "backend/package.json"
    "backend/tsconfig.json"
    "backend/.env.example"
    "backend/database/schema.sql"
    "backend/src/routes/admin.routes.ts"
    "backend/src/routes/customer.routes.ts"
    "backend/src/routes/mitra.routes.ts"
    "backend/src/routes/pesanan.routes.ts"
    "backend/src/routes/laporan.routes.ts"
    "backend/src/routes/refund.routes.ts"
)

for file in "${BACKEND_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✅ $file"
    else
        echo "  ❌ $file - MISSING!"
    fi
done

# Check API service
echo "✓ Checking API service..."
if [ -f "src/services/api.ts" ]; then
    echo "  ✅ src/services/api.ts"
else
    echo "  ❌ src/services/api.ts - MISSING!"
fi

# Check documentation
echo "✓ Checking documentation..."
DOCS=(
    "SETUP_GUIDE.md"
    "INTEGRATION_GUIDE.md"
    "DATABASE_SCHEMA.md"
    "README_BACKEND.md"
    "COMPLETION_CHECKLIST.md"
    "START_HERE.md"
    "TROUBLESHOOTING.md"
)

for doc in "${DOCS[@]}"; do
    if [ -f "$doc" ]; then
        echo "  ✅ $doc"
    else
        echo "  ❌ $doc - MISSING!"
    fi
done

echo ""
echo "✅ Verification Complete!"
echo ""
echo "Next steps:"
echo "1. cd backend && npm install"
echo "2. cp .env.example .env"
echo "3. mysql -u root -p < database/schema.sql"
echo "4. npm run dev"
