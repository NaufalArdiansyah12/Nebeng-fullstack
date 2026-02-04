#!/bin/bash

# Vehicle Approval Test Script
# Usage: ./test_vehicle_approval.sh

BASE_URL="http://localhost:8000/api/v1"

echo "=== Vehicle Approval Test Script ==="
echo ""

# Test 1: Get admin token (you need to update this with actual admin credentials)
echo "1. Login as Admin"
echo "POST $BASE_URL/auth/login"
ADMIN_TOKEN="your_admin_token_here"
echo "Admin Token: $ADMIN_TOKEN"
echo ""

# Test 2: Get all vehicles (as admin, we might want to see all vehicles)
echo "2. Get All Vehicles"
echo "GET $BASE_URL/vehicles"
curl -s -X GET "$BASE_URL/vehicles" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Accept: application/json" | jq .
echo ""

# Test 3: Approve vehicle
VEHICLE_ID=1
echo "3. Approve Vehicle #$VEHICLE_ID"
echo "POST $BASE_URL/vehicles/$VEHICLE_ID/approve"
curl -s -X POST "$BASE_URL/vehicles/$VEHICLE_ID/approve" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Accept: application/json" | jq .
echo ""

# Test 4: Reject vehicle with reason
VEHICLE_ID=2
echo "4. Reject Vehicle #$VEHICLE_ID"
echo "POST $BASE_URL/vehicles/$VEHICLE_ID/reject"
curl -s -X POST "$BASE_URL/vehicles/$VEHICLE_ID/reject" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "rejection_reason": "Foto plat nomor tidak jelas. Mohon upload ulang dengan foto yang lebih jelas."
  }' | jq .
echo ""

echo "=== Test Complete ==="
echo ""
echo "Notes:"
echo "- Update ADMIN_TOKEN variable with actual admin token"
echo "- Update VEHICLE_ID for testing specific vehicles"
echo "- Make sure jq is installed for JSON formatting (optional)"
