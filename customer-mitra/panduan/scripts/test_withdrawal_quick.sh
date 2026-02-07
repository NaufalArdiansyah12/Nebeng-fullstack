#!/bin/bash

# Quick Test Withdrawal Feature
echo "🧪 Testing Withdrawal Feature..."
echo ""

# 1. Login
echo "1️⃣ Login as mitra..."
LOGIN_RESPONSE=$(curl -s -X POST "http://localhost:8000/api/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email": "mitra@example.com", "password": "password"}')

TOKEN=$(echo $LOGIN_RESPONSE | jq -r '.data.token')

if [ "$TOKEN" = "null" ] || [ -z "$TOKEN" ]; then
  echo "❌ Login failed!"
  echo "$LOGIN_RESPONSE" | jq '.'
  exit 1
fi

echo "✅ Login successful!"
echo "Token: ${TOKEN:0:30}..."
echo ""

# 2. Get Balance Info
echo "2️⃣ Getting balance info..."
BALANCE_RESPONSE=$(curl -s -X GET "http://localhost:8000/api/v1/mitra/withdrawal/balance" \
  -H "Authorization: Bearer $TOKEN")

echo "$BALANCE_RESPONSE" | jq '.'
echo ""

# Check if success
SUCCESS=$(echo $BALANCE_RESPONSE | jq -r '.success')
if [ "$SUCCESS" = "true" ]; then
  BALANCE=$(echo $BALANCE_RESPONSE | jq -r '.data.balance')
  BANK_NAME=$(echo $BALANCE_RESPONSE | jq -r '.data.bank_name')
  echo "✅ Balance: Rp $BALANCE"
  echo "✅ Bank: $BANK_NAME"
else
  MESSAGE=$(echo $BALANCE_RESPONSE | jq -r '.message')
  echo "❌ Error: $MESSAGE"
fi

echo ""
echo "================================"
echo "✅ Backend test completed!"
echo ""
echo "📱 Now test on Flutter app:"
echo "   1. Login as: mitra@example.com / password"
echo "   2. Click 'Tarik Saldo' button"
echo "   3. Should see balance: Rp 200.000"
echo "   4. Bank: BRI - 129519285192518417"
