#!/bin/bash

# API Testing Script
# Tests the basic functionality of the Smart Waste Management API

BASE_URL="http://localhost:8000"
TOKEN=""

echo "========================================"
echo "Smart Waste Management - API Test"
echo "========================================"
echo ""

# Test 1: Login
echo "Test 1: User Login"
echo "-------------------"
LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/api/auth/login/" \
  -H "Content-Type: application/json" \
  -d '{"username":"citizen1","password":"citizen123"}')

TOKEN=$(echo $LOGIN_RESPONSE | grep -o '"access":"[^"]*' | cut -d'"' -f4)

if [ -n "$TOKEN" ]; then
    echo "✓ Login successful"
    echo "Token: ${TOKEN:0:20}..."
else
    echo "✗ Login failed"
    echo "Response: $LOGIN_RESPONSE"
    exit 1
fi

echo ""

# Test 2: Get Profile
echo "Test 2: Get User Profile"
echo "------------------------"
PROFILE_RESPONSE=$(curl -s -X GET "$BASE_URL/api/auth/profile/" \
  -H "Authorization: Bearer $TOKEN")

if echo "$PROFILE_RESPONSE" | grep -q "username"; then
    echo "✓ Profile retrieved successfully"
    echo "$PROFILE_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$PROFILE_RESPONSE"
else
    echo "✗ Profile retrieval failed"
    echo "Response: $PROFILE_RESPONSE"
fi

echo ""

# Test 3: Create Report
echo "Test 3: Create Garbage Report"
echo "------------------------------"
REPORT_RESPONSE=$(curl -s -X POST "$BASE_URL/api/reports/" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test Garbage Report",
    "description": "This is a test report created by API test script",
    "garbage_type": "household",
    "latitude": 40.7128,
    "longitude": -74.0060,
    "address": "123 Test St, New York, NY"
  }')

if echo "$REPORT_RESPONSE" | grep -q '"id"'; then
    echo "✓ Report created successfully"
    REPORT_ID=$(echo $REPORT_RESPONSE | grep -o '"id":[0-9]*' | cut -d':' -f2)
    echo "Report ID: $REPORT_ID"
else
    echo "✗ Report creation failed"
    echo "Response: $REPORT_RESPONSE"
fi

echo ""

# Test 4: List Reports
echo "Test 4: List Reports"
echo "--------------------"
REPORTS_LIST=$(curl -s -X GET "$BASE_URL/api/reports/" \
  -H "Authorization: Bearer $TOKEN")

if echo "$REPORTS_LIST" | grep -q "results"; then
    echo "✓ Reports list retrieved"
    COUNT=$(echo "$REPORTS_LIST" | grep -o '"count":[0-9]*' | cut -d':' -f2)
    echo "Total reports: $COUNT"
else
    echo "✗ Reports list retrieval failed"
fi

echo ""

# Test 5: API Documentation
echo "Test 5: Check API Documentation"
echo "--------------------------------"
SWAGGER_CHECK=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/swagger/")

if [ "$SWAGGER_CHECK" = "200" ]; then
    echo "✓ API documentation accessible"
    echo "URL: $BASE_URL/swagger/"
else
    echo "✗ API documentation not accessible"
fi

echo ""
echo "========================================"
echo "API Testing Complete!"
echo "========================================"
echo ""
echo "Note: Make sure the Django server is running:"
echo "  cd backend"
echo "  source venv/bin/activate"
echo "  python manage.py runserver"
