#!/bin/bash

# Script untuk monitoring location tracking di database
# Usage: ./check-location.sh [booking_id]

BOOKING_ID=${1:-2}

echo "🔍 Monitoring Location Tracking for Booking ID: $BOOKING_ID"
echo "=================================================="
echo ""

cd "$(dirname "$0")/backend"

# Cek apakah menggunakan SQLite atau PostgreSQL
DB_CONNECTION=$(grep "DB_CONNECTION=" .env | cut -d '=' -f2)

if [ "$DB_CONNECTION" = "sqlite" ]; then
    echo "📊 Database: SQLite"
    echo ""
    
    # Query SQLite
    sqlite3 database/database.sqlite <<EOF
.mode column
.headers on
.width 5 15 15 25 15
SELECT 
    id,
    ROUND(last_lat, 7) as last_lat,
    ROUND(last_lng, 7) as last_lng,
    last_location_at,
    status
FROM booking_motor
WHERE id = $BOOKING_ID;
EOF

    echo ""
    echo "📈 Last 5 location updates:"
    sqlite3 database/database.sqlite <<EOF
.mode column
.headers on
SELECT 
    ROUND(last_lat, 7) as lat,
    ROUND(last_lng, 7) as lng,
    last_location_at as timestamp
FROM booking_motor
WHERE id = $BOOKING_ID
ORDER BY last_location_at DESC
LIMIT 5;
EOF

else
    echo "📊 Database: PostgreSQL"
    echo ""
    
    # Get PostgreSQL credentials from .env
    DB_HOST=$(grep "DB_HOST=" .env | cut -d '=' -f2)
    DB_PORT=$(grep "DB_PORT=" .env | cut -d '=' -f2)
    DB_DATABASE=$(grep "DB_DATABASE=" .env | cut -d '=' -f2)
    DB_USERNAME=$(grep "DB_USERNAME=" .env | cut -d '=' -f2)
    DB_PASSWORD=$(grep "DB_PASSWORD=" .env | cut -d '=' -f2)
    
    # Query PostgreSQL
    PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USERNAME -d $DB_DATABASE -c "
    SELECT 
        id,
        ROUND(last_lat::numeric, 7) as last_lat,
        ROUND(last_lng::numeric, 7) as last_lng,
        last_location_at,
        status
    FROM booking_motor
    WHERE id = $BOOKING_ID;
    "
fi

echo ""
echo "✅ Done! Press Ctrl+C to stop monitoring or run again to refresh."
