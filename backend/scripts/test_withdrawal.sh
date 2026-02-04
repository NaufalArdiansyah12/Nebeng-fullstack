#!/bin/bash

# Script untuk testing Tarik Saldo API
# Usage: ./test_withdrawal.sh

echo "🧪 Testing Withdrawal API..."
echo "================================"

# Base URL
BASE_URL="http://localhost:8000/api/v1"

# Login untuk mendapatkan token
echo ""
echo "1. Login sebagai Mitra..."
LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "mitra@example.com",
    "password": "password"
  }')

TOKEN=$(echo $LOGIN_RESPONSE | grep -o '"token":"[^"]*' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
  echo "❌ Login failed!"
  echo "$LOGIN_RESPONSE"
  exit 1
fi

echo "✅ Login successful!"
echo "Token: ${TOKEN:0:20}..."

# Test Get Balance Info
echo ""
echo "2. Testing Get Balance Info..."
BALANCE_RESPONSE=$(curl -s -X GET "$BASE_URL/mitra/withdrawal/balance" \
  -H "Authorization: Bearer $TOKEN")

echo "$BALANCE_RESPONSE" | jq '.'

# Test Submit Withdrawal (akan gagal jika PIN salah)
echo ""
echo "3. Testing Submit Withdrawal (dengan PIN: 123456)..."
SUBMIT_RESPONSE=$(curl -s -X POST "$BASE_URL/mitra/withdrawal/submit" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 50000,
    "pin": "123456"
  }')

echo "$SUBMIT_RESPONSE" | jq '.'

# Extract withdrawal_id
WITHDRAWAL_ID=$(echo $SUBMIT_RESPONSE | grep -o '"withdrawal_id":[0-9]*' | cut -d':' -f2)

if [ ! -z "$WITHDRAWAL_ID" ]; then
  echo ""
  echo "4. Testing Get Withdrawal Detail (ID: $WITHDRAWAL_ID)..."
  sleep 2
  DETAIL_RESPONSE=$(curl -s -X GET "$BASE_URL/mitra/withdrawal/$WITHDRAWAL_ID" \
    -H "Authorization: Bearer $TOKEN")
  
  echo "$DETAIL_RESPONSE" | jq '.'
  
  echo ""
  echo "5. Testing Check Status..."
  sleep 3
  STATUS_RESPONSE=$(curl -s -X GET "$BASE_URL/mitra/withdrawal/$WITHDRAWAL_ID/status" \
    -H "Authorization: Bearer $TOKEN")
  
  echo "$STATUS_RESPONSE" | jq '.'
fi

# Test Get History
echo ""
echo "6. Testing Get Withdrawal History..."
HISTORY_RESPONSE=$(curl -s -X GET "$BASE_URL/mitra/withdrawal/history/list" \
  -H "Authorization: Bearer $TOKEN")

echo "$HISTORY_RESPONSE" | jq '.'

echo ""
echo "================================"
echo "✅ Testing completed!"
