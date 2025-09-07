#!/bin/bash

echo "🚀 Cranston Auth Docker Test Deployment"
echo "========================================"
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed!"
    echo ""
    echo "Please install Docker Desktop for Mac first:"
    echo "https://www.docker.com/products/docker-desktop/"
    echo ""
    exit 1
fi

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo "❌ Docker is not running!"
    echo "Please start Docker Desktop and try again."
    exit 1
fi

echo "✅ Docker is installed and running"
echo ""

# Check if .env file exists
if [ ! -f .env ]; then
    echo "❌ .env file not found!"
    echo "Please create .env file from .env.example"
    exit 1
fi

echo "✅ .env file found"
echo ""

echo "📦 Building and starting containers..."
echo "This may take 5-10 minutes on first run..."
echo ""

# Build and start containers
docker-compose up -d --build

# Wait for containers to be ready
echo ""
echo "⏳ Waiting for services to be ready..."
sleep 10

# Check container status
echo ""
echo "📊 Container Status:"
docker-compose ps

# Test the application
echo ""
echo "🧪 Testing application health..."
if curl -s http://localhost:3000/up | grep -q "200"; then
    echo "✅ Application is running!"
    echo ""
    echo "🎉 Success! Your Docker deployment is working."
    echo ""
    echo "📝 Next steps:"
    echo "1. Create an admin user:"
    echo "   docker-compose exec web rails console"
    echo "   Then run: User.create!(email: 'admin@test.edu', password: 'password123', role: 'admin', first_name: 'Test', last_name: 'Admin')"
    echo ""
    echo "2. Access admin interface:"
    echo "   http://localhost:3000/admin/login"
    echo ""
    echo "3. View logs:"
    echo "   docker-compose logs -f"
    echo ""
    echo "4. Stop containers:"
    echo "   docker-compose down"
    echo ""
    echo "5. Remove everything (including data):"
    echo "   docker-compose down -v"
else
    echo "⚠️  Application may still be starting up..."
    echo "Check logs with: docker-compose logs web"
fi