#!/bin/bash

# Script untuk simulasi pembayaran
# Usage: ./simulate_payment.sh [payment_id]

BASE_URL="http://127.0.0.1:8000"

echo "🔍 Fetching pending payments..."
echo ""

# Get pending payments
RESPONSE=$(curl -s "${BASE_URL}/api/v1/payments/test/pending")

# Check if successful
if echo "$RESPONSE" | grep -q '"success":true'; then
    echo "📋 Pending Payments:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Parse and display payments
    echo "$RESPONSE" | python3 -c "
import sys, json
data = json.load(sys.stdin)
if data.get('data'):
    for p in data['data']:
        print(f\"ID: {p['id']}\")
        print(f\"Booking: {p['booking_number']}\")
        print(f\"Amount: Rp {p['total_amount']}\")
        print(f\"Method: {p['payment_method']}\")
        if p.get('virtual_account_number'):
            print(f\"VA Number: {p['virtual_account_number']}\")
        print(f\"Status: {p['status']}\")
        print(f\"Created: {p['created_at']}\")
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
else:
    print('No pending payments found.')
" 2>/dev/null || echo "$RESPONSE"
    
    echo ""
    
    # If payment ID provided as argument
    if [ -n "$1" ]; then
        PAYMENT_ID=$1
    else
        # Ask for payment ID
        read -p "Enter Payment ID to simulate: " PAYMENT_ID
    fi
    
    if [ -n "$PAYMENT_ID" ]; then
        echo ""
        echo "💰 Simulating payment for ID: $PAYMENT_ID..."
        
        SIMULATE_RESPONSE=$(curl -s -X POST "${BASE_URL}/api/v1/payments/test/${PAYMENT_ID}/simulate")
        
        if echo "$SIMULATE_RESPONSE" | grep -q '"success":true'; then
            echo "✅ Payment simulated successfully!"
            echo ""
            echo "$SIMULATE_RESPONSE" | python3 -c "
import sys, json
data = json.load(sys.stdin)
if data.get('data'):
    p = data['data']
    print(f\"Payment ID: {p['id']}\")
    print(f\"Booking: {p['booking_number']}\")
    print(f\"Status: {p['status']}\")
    print(f\"Paid At: {p.get('paid_at', 'N/A')}\")
" 2>/dev/null || echo "$SIMULATE_RESPONSE"
        else
            echo "❌ Failed to simulate payment"
            echo "$SIMULATE_RESPONSE"
        fi
    fi
else
    echo "❌ Failed to fetch pending payments"
    echo "$RESPONSE"
fi

echo ""
