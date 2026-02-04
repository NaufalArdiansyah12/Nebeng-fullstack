#!/bin/bash

# Test upload foto verifikasi wajah
# Ganti YOUR_API_TOKEN dengan token yang valid

API_TOKEN="YOUR_API_TOKEN"
API_URL="http://localhost:8000/api"

# Create a test image (1x1 pixel PNG)
echo "Creating test image..."
base64 -d > /tmp/test-photo.png << EOF
iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==
EOF

echo "Uploading test photo..."
curl -X POST "$API_URL/verifikasi/upload-wajah" \
  -H "Authorization: Bearer $API_TOKEN" \
  -F "photo=@/tmp/test-photo.png" \
  -v

echo -e "\n\nChecking storage folder..."
ls -la /home/naufal/project/nebeng-fullstack/backend/storage/app/public/verifikasi/wajah/
