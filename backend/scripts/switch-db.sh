#!/bin/bash

# Script untuk switch antara database local dan online
# Usage: ./switch-db.sh {local|testing|production}

cd "$(dirname "$0")"

case "$1" in
  local)
    if [ ! -f .env.local ]; then
      echo "❌ File .env.local tidak ditemukan!"
      exit 1
    fi
    cp .env.local .env
    echo "✅ Switched to LOCAL database"
    echo "   Database: MySQL Local (127.0.0.1:3306)"
    ;;
    
  testing)
    if [ ! -f .env.testing ]; then
      echo "❌ File .env.testing tidak ditemukan!"
      exit 1
    fi
    cp .env.testing .env
    echo "✅ Switched to TESTING database (ONLINE)"
    echo "   Database: Supabase PostgreSQL"
    ;;
    
  production)
    echo "⚠️  Production mode belum dikonfigurasi"
    echo "   Buat file .env.production terlebih dahulu"
    exit 1
    ;;
    
  *)
    echo "Usage: ./switch-db.sh {local|testing|production}"
    echo ""
    echo "Commands:"
    echo "  local      - Gunakan database PostgreSQL lokal (development)"
    echo "  testing    - Gunakan database Supabase online (testing)"
    echo "  production - Gunakan database production (belum dikonfigurasi)"
    exit 1
    ;;
esac

# Clear dan rebuild cache Laravel
echo ""
echo "🔄 Clearing Laravel cache..."
php artisan config:clear
php artisan cache:clear
php artisan config:cache

echo ""
echo "✅ Database switched successfully!"
echo "   Current environment: $(grep APP_ENV .env | cut -d '=' -f2)"
echo "   Database connection: $(grep DB_CONNECTION .env | grep -v '#' | cut -d '=' -f2)"
echo "   Database host: $(grep DB_HOST .env | grep -v '#' | cut -d '=' -f2)"
