#!/bin/bash

echo "🧪 Docker Deployment Test Suite"
echo "================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to check test result
check_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ PASS${NC}: $2"
    else
        echo -e "${RED}❌ FAIL${NC}: $2"
        echo "Error details: $3"
    fi
}

echo "Waiting for services to be ready..."
sleep 15

echo ""
echo "1️⃣ Testing container status..."
CONTAINERS=$(docker-compose ps --format json 2>/dev/null)
WEB_STATUS=$(docker-compose ps web --format "{{.Status}}" 2>/dev/null | grep -c "Up")
DB_STATUS=$(docker-compose ps db --format "{{.Status}}" 2>/dev/null | grep -c "healthy")

check_result $WEB_STATUS "Web container is running"
check_result $DB_STATUS "Database container is healthy"

echo ""
echo "2️⃣ Testing health endpoint..."
HEALTH_CHECK=$(curl -s -w "\n%{http_code}" http://localhost:3000/up 2>/dev/null | tail -1)
if [ "$HEALTH_CHECK" == "200" ]; then
    check_result 0 "Health endpoint responding"
else
    check_result 1 "Health endpoint responding" "HTTP Status: $HEALTH_CHECK"
fi

echo ""
echo "3️⃣ Testing user authentication API..."
echo "   Creating test login..."
LOGIN_RESPONSE=$(curl -s -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@cranston.edu","password":"password123"}' 2>/dev/null)

if echo "$LOGIN_RESPONSE" | grep -q "token"; then
    check_result 0 "User authentication working"
    TOKEN=$(echo "$LOGIN_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['token'])" 2>/dev/null)
    
    echo ""
    echo "4️⃣ Testing authenticated user endpoint..."
    USER_RESPONSE=$(curl -s -w "\n%{http_code}" \
      -H "Authorization: Bearer $TOKEN" \
      http://localhost:3000/api/v1/users 2>/dev/null | tail -1)
    
    if [ "$USER_RESPONSE" == "200" ]; then
        check_result 0 "Authenticated API requests working"
    else
        check_result 1 "Authenticated API requests working" "HTTP Status: $USER_RESPONSE"
    fi
else
    check_result 1 "User authentication working" "Response: $LOGIN_RESPONSE"
fi

echo ""
echo "5️⃣ Testing service-to-service API..."
# First get an admin user's external_id
ADMIN_USER=$(docker-compose exec -T web /rails/bin/rails runner "puts User.find_by(email: 'admin@cranston.edu')&.external_id" 2>/dev/null | tr -d '\r\n')

if [ ! -z "$ADMIN_USER" ]; then
    SERVICE_RESPONSE=$(curl -s -w "\n%{http_code}" \
      -H "X-Service-Api-Key: classroom_test_key_789" \
      "http://localhost:3000/api/v1/services/users/$ADMIN_USER" 2>/dev/null | tail -1)
    
    if [ "$SERVICE_RESPONSE" == "200" ]; then
        check_result 0 "Service API authentication working"
    else
        check_result 1 "Service API authentication working" "HTTP Status: $SERVICE_RESPONSE"
    fi
else
    check_result 1 "Service API authentication working" "Could not get user external_id"
fi

echo ""
echo "6️⃣ Testing admin web interface..."
ADMIN_LOGIN=$(curl -s -w "\n%{http_code}" http://localhost:3000/admin/login 2>/dev/null | tail -1)
if [ "$ADMIN_LOGIN" == "200" ]; then
    check_result 0 "Admin interface accessible"
else
    check_result 1 "Admin interface accessible" "HTTP Status: $ADMIN_LOGIN"
fi

echo ""
echo "================================"
echo "📋 Test Summary:"
echo ""
echo "Key endpoints:"
echo "  • Health Check: http://localhost:3000/up"
echo "  • User Auth API: http://localhost:3000/api/v1/auth/login"
echo "  • Admin Interface: http://localhost:3000/admin/login"
echo ""
echo "Test credentials:"
echo "  • admin@cranston.edu / password123"
echo "  • teacher1@cranston.edu / password123"
echo "  • student1@cranston.edu / password123"
echo ""
echo "Service API Keys (in .env):"
echo "  • CLASSROOM_SERVICE_API_KEY=classroom_test_key_789"
echo "  • GAME_SERVICE_API_KEY=game_test_key_101"
echo "  • STORE_SERVICE_API_KEY=store_test_key_112"
echo ""
echo "================================"