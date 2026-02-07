#!/bin/bash

# Helper untuk melihat OTP code dari Laravel log
# Usage: bash view_otp_from_log.sh

echo "📧 Mencari OTP Code di Laravel Log..."
echo "======================================"
echo ""

LOG_FILE="/home/naufal/project/nebeng-fullstack/backend/storage/logs/laravel.log"

if [ ! -f "$LOG_FILE" ]; then
    echo "❌ Log file tidak ditemukan: $LOG_FILE"
    exit 1
fi

# Cari OTP code (6 digit di dalam email)
echo "🔍 OTP Codes yang ditemukan (dari yang terbaru):"
echo ""

# Extract OTP codes with context
grep -B 5 -A 10 "Kode Verifikasi Anda" "$LOG_FILE" | tail -30 | grep -E "[0-9]{6}" | tail -5

echo ""
echo "💡 Tips:"
echo "   - Kode OTP adalah 6 digit angka"
echo "   - Untuk melihat full log: tail -f storage/logs/laravel.log"
echo "   - Untuk clear log: echo '' > storage/logs/laravel.log"
