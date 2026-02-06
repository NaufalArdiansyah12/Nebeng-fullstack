#!/bin/bash

# Test Register API Endpoint
# Usage: ./test_register.sh

API_URL="${API_URL:-http://localhost:8000}/api/v1/auth/register"

# Generate unique email for testing
TIMESTAMP=$(date +%s)
TEST_EMAIL="testuser${TIMESTAMP}@example.com"
TEST_NAME="Test User ${TIMESTAMP}"
TEST_PASSWORD="password123"

echo "================================"
echo "Testing Register API Endpoint"
echo "================================"
echo "API URL: $API_URL"
echo "Test Email: $TEST_EMAIL"
echo "Test Name: $TEST_NAME"
echo ""

# Test 1: Successful registration
echo "Test 1: Successful Registration"
echo "--------------------------------"
RESPONSE=$(curl -s -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d "{
    \"name\": \"$TEST_NAME\",
    \"email\": \"$TEST_EMAIL\",
    \"password\": \"$TEST_PASSWORD\",
    \"password_confirmation\": \"$TEST_PASSWORD\"
  }")

echo "Response:"
echo "$RESPONSE" | jq '.'
echo ""

# Extract success status
SUCCESS=$(echo "$RESPONSE" | jq -r '.success')
if [ "$SUCCESS" == "true" ]; then
    echo "✅ Registration successful!"
    USER_ID=$(echo "$RESPONSE" | jq -r '.data.user.id')
    echo "User ID: $USER_ID"
else
    echo "❌ Registration failed!"
fi
echo ""

# Test 2: Try to register with same email (should fail)
echo "Test 2: Duplicate Email Registration (Should Fail)"
echo "---------------------------------------------------"
RESPONSE2=$(curl -s -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d "{
    \"name\": \"$TEST_NAME\",
    \"email\": \"$TEST_EMAIL\",
    \"password\": \"$TEST_PASSWORD\",
    \"password_confirmation\": \"$TEST_PASSWORD\"
  }")

echo "Response:"
echo "$RESPONSE2" | jq '.'
echo ""

SUCCESS2=$(echo "$RESPONSE2" | jq -r '.success')
if [ "$SUCCESS2" == "false" ]; then
    echo "✅ Duplicate email correctly rejected!"
else
    echo "❌ Duplicate email was not rejected (ERROR)!"
fi
echo ""

# Test 3: Password mismatch
echo "Test 3: Password Mismatch (Should Fail)"
echo "----------------------------------------"
NEW_EMAIL="testuser2_${TIMESTAMP}@example.com"
RESPONSE3=$(curl -s -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d "{
    \"name\": \"Test User 2\",
    \"email\": \"$NEW_EMAIL\",
    \"password\": \"password123\",
    \"password_confirmation\": \"password456\"
  }")

echo "Response:"
echo "$RESPONSE3" | jq '.'
echo ""

SUCCESS3=$(echo "$RESPONSE3" | jq -r '.success')
if [ "$SUCCESS3" == "false" ]; then
    echo "✅ Password mismatch correctly rejected!"
else
    echo "❌ Password mismatch was not rejected (ERROR)!"
fi
echo ""

# Test 4: Invalid email format
echo "Test 4: Invalid Email Format (Should Fail)"
echo "------------------------------------------"
RESPONSE4=$(curl -s -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d "{
    \"name\": \"Test User 3\",
    \"email\": \"invalidemail\",
    \"password\": \"password123\",
    \"password_confirmation\": \"password123\"
  }")

echo "Response:"
echo "$RESPONSE4" | jq '.'
echo ""

SUCCESS4=$(echo "$RESPONSE4" | jq -r '.success')
if [ "$SUCCESS4" == "false" ]; then
    echo "✅ Invalid email format correctly rejected!"
else
    echo "❌ Invalid email format was not rejected (ERROR)!"
fi
echo ""

# Test 5: Short password
echo "Test 5: Short Password (Should Fail)"
echo "------------------------------------"
NEW_EMAIL2="testuser3_${TIMESTAMP}@example.com"
RESPONSE5=$(curl -s -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d "{
    \"name\": \"Test User 4\",
    \"email\": \"$NEW_EMAIL2\",
    \"password\": \"pass\",
    \"password_confirmation\": \"pass\"
  }")

echo "Response:"
echo "$RESPONSE5" | jq '.'
echo ""

SUCCESS5=$(echo "$RESPONSE5" | jq -r '.success')
if [ "$SUCCESS5" == "false" ]; then
    echo "✅ Short password correctly rejected!"
else
    echo "❌ Short password was not rejected (ERROR)!"
fi
echo ""

echo "================================"
echo "All tests completed!"
echo "================================"
