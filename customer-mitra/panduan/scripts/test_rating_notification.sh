#!/bin/bash

# Script untuk test rating dan notifikasi
# Usage: ./test_rating_notification.sh

echo "=== Testing Rating & Notification System ==="
echo ""

# Konfigurasi
BASE_URL="http://localhost:8000"
API_BASE="${BASE_URL}/api/v1"

# Warna untuk output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Note: Pastikan Anda sudah memiliki:${NC}"
echo "1. Token API customer yang valid"
echo "2. Booking ID yang sudah completed"
echo "3. Driver ID dari booking tersebut"
echo ""

# Input dari user
read -p "Enter Customer API Token: " CUSTOMER_TOKEN
read -p "Enter Booking ID: " BOOKING_ID
read -p "Enter Driver ID: " DRIVER_ID
read -p "Enter Rating (1-5): " RATING_VALUE
read -p "Enter Review (optional): " REVIEW

echo ""
echo -e "${YELLOW}Submitting rating...${NC}"

# Submit rating
RATING_RESPONSE=$(curl -s -X POST "${API_BASE}/ratings" \
  -H "Authorization: Bearer ${CUSTOMER_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{
    \"booking_id\": ${BOOKING_ID},
    \"booking_type\": \"motor\",
    \"driver_id\": ${DRIVER_ID},
    \"rating\": ${RATING_VALUE},
    \"review\": \"${REVIEW}\"
  }")

echo "$RATING_RESPONSE" | jq '.'

# Check if success
if echo "$RATING_RESPONSE" | jq -e '.success == true' > /dev/null; then
  echo -e "${GREEN}✓ Rating submitted successfully!${NC}"
  RATING_ID=$(echo "$RATING_RESPONSE" | jq -r '.data.id')
  echo "Rating ID: $RATING_ID"
else
  echo -e "${RED}✗ Failed to submit rating${NC}"
  exit 1
fi

echo ""
echo -e "${YELLOW}Now checking driver notifications...${NC}"
read -p "Enter Driver API Token: " DRIVER_TOKEN

# Get driver notifications
sleep 2  # Wait for notification to be processed

NOTIF_RESPONSE=$(curl -s -X GET "${API_BASE}/notifications" \
  -H "Authorization: Bearer ${DRIVER_TOKEN}")

echo "$NOTIF_RESPONSE" | jq '.'

# Check for rating notification
RATING_NOTIF=$(echo "$NOTIF_RESPONSE" | jq '.data.data[] | select(.type == "rating_received") | select(.data.rating_id == "'$RATING_ID'")')

if [ -n "$RATING_NOTIF" ]; then
  echo ""
  echo -e "${GREEN}✓ Rating notification found in driver's notifications!${NC}"
  echo "$RATING_NOTIF" | jq '.'
else
  echo ""
  echo -e "${RED}✗ Rating notification not found${NC}"
  echo "Showing recent notifications:"
  echo "$NOTIF_RESPONSE" | jq '.data.data[0:3]'
fi

echo ""
echo -e "${YELLOW}Checking Laravel logs for notification...${NC}"
echo "Last 20 lines containing 'notification':"
tail -n 50 ../storage/logs/laravel.log | grep -i "notification" | tail -n 20

echo ""
echo "=== Test Complete ==="
