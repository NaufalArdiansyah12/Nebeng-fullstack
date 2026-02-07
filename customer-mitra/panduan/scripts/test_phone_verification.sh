#!/bin/bash

# Script untuk test Phone Verification OTP
# Jalankan: bash test_phone_verification.sh

echo "🧪 Testing Phone Verification OTP Implementation"
echo "================================================"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Base URL
BASE_URL="http://localhost:8000"

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}⚠️  jq is not installed. Install it for better JSON formatting: sudo apt install jq${NC}"
    echo ""
fi

echo "📋 Pre-requisites:"
echo "1. Laravel server harus running (php artisan serve)"
echo "2. User harus sudah login dan punya auth token"
echo "3. Database migration sudah dijalankan"
echo ""

# Get auth token from user
read -p "Enter your auth token (Bearer token): " AUTH_TOKEN

if [ -z "$AUTH_TOKEN" ]; then
    echo -e "${RED}❌ Auth token tidak boleh kosong!${NC}"
    exit 1
fi

echo ""
echo "🔍 Step 1: Checking phone verification status"
echo "=============================================="
STATUS_RESPONSE=$(curl -s -X GET "${BASE_URL}/api/v1/phone-verification/status" \
  -H "Authorization: Bearer ${AUTH_TOKEN}" \
  -H "Accept: application/json")

echo "Response:"
if command -v jq &> /dev/null; then
    echo "$STATUS_RESPONSE" | jq '.'
else
    echo "$STATUS_RESPONSE"
fi
echo ""

# Get phone number from user
read -p "Enter phone number to verify (e.g., 081234567890): " PHONE_NUMBER

if [ -z "$PHONE_NUMBER" ]; then
    echo -e "${RED}❌ Phone number tidak boleh kosong!${NC}"
    exit 1
fi

echo ""
echo "📧 Step 2: Sending OTP to email"
echo "================================"
SEND_RESPONSE=$(curl -s -X POST "${BASE_URL}/api/v1/phone-verification/send-otp" \
  -H "Authorization: Bearer ${AUTH_TOKEN}" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d "{\"phone\": \"${PHONE_NUMBER}\"}")

echo "Response:"
if command -v jq &> /dev/null; then
    echo "$SEND_RESPONSE" | jq '.'
else
    echo "$SEND_RESPONSE"
fi
echo ""

# Check if successful
SUCCESS=$(echo "$SEND_RESPONSE" | grep -o '"success":true' || echo "")
if [ -n "$SUCCESS" ]; then
    echo -e "${GREEN}✅ OTP berhasil dikirim!${NC}"
    echo ""
    echo "📬 Cek email atau log file untuk kode OTP:"
    echo "   tail -f storage/logs/laravel.log"
    echo ""
    
    # Get OTP from user
    read -p "Enter OTP code (6 digits): " OTP_CODE
    
    if [ -z "$OTP_CODE" ]; then
        echo -e "${RED}❌ OTP code tidak boleh kosong!${NC}"
        exit 1
    fi
    
    echo ""
    echo "✅ Step 3: Verifying OTP"
    echo "======================="
    VERIFY_RESPONSE=$(curl -s -X POST "${BASE_URL}/api/v1/phone-verification/verify-otp" \
      -H "Authorization: Bearer ${AUTH_TOKEN}" \
      -H "Content-Type: application/json" \
      -H "Accept: application/json" \
      -d "{\"phone\": \"${PHONE_NUMBER}\", \"otp_code\": \"${OTP_CODE}\"}")
    
    echo "Response:"
    if command -v jq &> /dev/null; then
        echo "$VERIFY_RESPONSE" | jq '.'
    else
        echo "$VERIFY_RESPONSE"
    fi
    echo ""
    
    # Check if verification successful
    VERIFY_SUCCESS=$(echo "$VERIFY_RESPONSE" | grep -o '"success":true' || echo "")
    if [ -n "$VERIFY_SUCCESS" ]; then
        echo -e "${GREEN}🎉 Verifikasi berhasil! Nomor HP telah terverifikasi!${NC}"
    else
        echo -e "${RED}❌ Verifikasi gagal. Cek response di atas untuk detail.${NC}"
    fi
else
    echo -e "${RED}❌ Gagal mengirim OTP. Cek response di atas untuk detail.${NC}"
fi

echo ""
echo "🔍 Step 4: Checking final status"
echo "================================="
FINAL_STATUS=$(curl -s -X GET "${BASE_URL}/api/v1/phone-verification/status" \
  -H "Authorization: Bearer ${AUTH_TOKEN}" \
  -H "Accept: application/json")

echo "Response:"
if command -v jq &> /dev/null; then
    echo "$FINAL_STATUS" | jq '.'
else
    echo "$FINAL_STATUS"
fi
echo ""

echo "✨ Test selesai!"
echo ""
echo "💡 Tips:"
echo "   - Untuk test resend OTP, tunggu 60 detik dan gunakan endpoint: /resend-otp"
echo "   - Untuk test dengan wrong OTP, masukkan kode yang salah (max 3x attempts)"
echo "   - Cek database table 'phone_otps' untuk melihat record OTP"
