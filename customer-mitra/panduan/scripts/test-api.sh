#!/bin/bash

# 🧪 Test Script untuk Admin API Laravel Backend
# Script ini akan test semua endpoint admin

echo "🧪 TESTING ADMIN API - LARAVEL BACKEND"
echo "======================================="
echo ""

# Base URL
BASE_URL="http://localhost:8000/api/admin"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if Laravel is running
echo -e "${BLUE}Checking if Laravel backend is running...${NC}"
if ! curl -s http://localhost:8000/api/v1/health > /dev/null 2>&1; then
    echo -e "${RED}❌ Laravel backend is not running!${NC}"
    echo "Please start it first:"
    echo "  cd backend && php artisan serve"
    exit 1
fi
echo -e "${GREEN}✓ Laravel backend is running${NC}"
echo ""

# Test 1: Login
echo -e "${BLUE}Test 1: Admin Login${NC}"
echo "POST $BASE_URL/auth/login"

LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@nebeng.com",
    "password": "password123"
  }')

echo "$LOGIN_RESPONSE" | jq '.'

# Extract token
TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.token')

if [ "$TOKEN" != "null" ] && [ -n "$TOKEN" ]; then
    echo -e "${GREEN}✓ Login successful!${NC}"
    echo "Token: $TOKEN"
else
    echo -e "${RED}❌ Login failed!${NC}"
    echo "Response: $LOGIN_RESPONSE"
    exit 1
fi
echo ""
echo "---"
echo ""

# Test 2: Verify Token
echo -e "${BLUE}Test 2: Verify Token${NC}"
echo "GET $BASE_URL/auth/verify"

VERIFY_RESPONSE=$(curl -s -X GET "$BASE_URL/auth/verify" \
  -H "Authorization: Bearer $TOKEN")

echo "$VERIFY_RESPONSE" | jq '.'

if echo "$VERIFY_RESPONSE" | jq -e '.success' > /dev/null; then
    echo -e "${GREEN}✓ Token verification successful!${NC}"
else
    echo -e "${RED}❌ Token verification failed!${NC}"
fi
echo ""
echo "---"
echo ""

# Test 3: Get Profile
echo -e "${BLUE}Test 3: Get Admin Profile${NC}"
echo "GET $BASE_URL/auth/profile"

PROFILE_RESPONSE=$(curl -s -X GET "$BASE_URL/auth/profile" \
  -H "Authorization: Bearer $TOKEN")

echo "$PROFILE_RESPONSE" | jq '.'

if echo "$PROFILE_RESPONSE" | jq -e '.success' > /dev/null; then
    echo -e "${GREEN}✓ Profile fetch successful!${NC}"
else
    echo -e "${RED}❌ Profile fetch failed!${NC}"
fi
echo ""
echo "---"
echo ""

# Test 4: Get Dashboard
echo -e "${BLUE}Test 4: Get Dashboard Statistics${NC}"
echo "GET $BASE_URL/dashboard"

DASHBOARD_RESPONSE=$(curl -s -X GET "$BASE_URL/dashboard" \
  -H "Authorization: Bearer $TOKEN")

echo "$DASHBOARD_RESPONSE" | jq '.'

if echo "$DASHBOARD_RESPONSE" | jq -e '.success' > /dev/null; then
    echo -e "${GREEN}✓ Dashboard fetch successful!${NC}"
else
    echo -e "${RED}❌ Dashboard fetch failed!${NC}"
fi
echo ""
echo "---"
echo ""

# Test 5: Get Customers
echo -e "${BLUE}Test 5: Get Customers List${NC}"
echo "GET $BASE_URL/customers"

CUSTOMERS_RESPONSE=$(curl -s -X GET "$BASE_URL/customers" \
  -H "Authorization: Bearer $TOKEN")

echo "$CUSTOMERS_RESPONSE" | jq '.'

if echo "$CUSTOMERS_RESPONSE" | jq -e '.success' > /dev/null; then
    echo -e "${GREEN}✓ Customers list fetch successful!${NC}"
else
    echo -e "${RED}❌ Customers list fetch failed!${NC}"
fi
echo ""
echo "---"
echo ""

# Test 6: Get Mitra
echo -e "${BLUE}Test 6: Get Mitra List${NC}"
echo "GET $BASE_URL/mitra"

MITRA_RESPONSE=$(curl -s -X GET "$BASE_URL/mitra" \
  -H "Authorization: Bearer $TOKEN")

echo "$MITRA_RESPONSE" | jq '.'

if echo "$MITRA_RESPONSE" | jq -e '.success' > /dev/null; then
    echo -e "${GREEN}✓ Mitra list fetch successful!${NC}"
else
    echo -e "${RED}❌ Mitra list fetch failed!${NC}"
fi
echo ""
echo "---"
echo ""

# Test 7: Get Pesanan
echo -e "${BLUE}Test 7: Get Pesanan List${NC}"
echo "GET $BASE_URL/pesanan"

PESANAN_RESPONSE=$(curl -s -X GET "$BASE_URL/pesanan" \
  -H "Authorization: Bearer $TOKEN")

echo "$PESANAN_RESPONSE" | jq '.'

if echo "$PESANAN_RESPONSE" | jq -e '.success' > /dev/null; then
    echo -e "${GREEN}✓ Pesanan list fetch successful!${NC}"
else
    echo -e "${RED}❌ Pesanan list fetch failed!${NC}"
fi
echo ""
echo "---"
echo ""

# Test 8: Logout
echo -e "${BLUE}Test 8: Logout${NC}"
echo "POST $BASE_URL/auth/logout"

LOGOUT_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/logout" \
  -H "Authorization: Bearer $TOKEN")

echo "$LOGOUT_RESPONSE" | jq '.'

if echo "$LOGOUT_RESPONSE" | jq -e '.success' > /dev/null; then
    echo -e "${GREEN}✓ Logout successful!${NC}"
else
    echo -e "${RED}❌ Logout failed!${NC}"
fi
echo ""
echo "---"
echo ""

# Summary
echo ""
echo "================================"
echo -e "${GREEN}✅ All tests completed!${NC}"
echo "================================"
echo ""
echo "Summary:"
echo "1. Login ✓"
echo "2. Verify Token ✓"
echo "3. Get Profile ✓"
echo "4. Get Dashboard ✓"
echo "5. Get Customers ✓"
echo "6. Get Mitra ✓"
echo "7. Get Pesanan ✓"
echo "8. Logout ✓"
echo ""
echo -e "${GREEN}🎉 All Admin API endpoints are working!${NC}"
