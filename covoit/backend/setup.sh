#!/bin/bash

# Covoit Backend Setup Script

set -e

echo "🚀 Covoit Microservices Backend Setup"
echo "======================================"

# Check Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker not found. Please install Docker first."
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose not found. Please install Docker Compose first."
    exit 1
fi

echo "✅ Docker & Docker Compose found"

# .env setup
if [ ! -f .env ]; then
    echo "📝 Creating .env from template..."
    cp .env.example .env
    echo "⚠️  Please review and update .env with your actual secrets"
fi

# Build images
echo "🔨 Building Docker images..."
docker-compose build

# Start services
echo "🐳 Starting services..."
docker-compose up -d

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."
sleep 10

# Create databases
echo "🗄️  Creating databases..."
docker-compose exec -T postgres-auth psql -U postgres -c "CREATE DATABASE IF NOT EXISTS auth_db;"
docker-compose exec -T postgres-user psql -U postgres -c "CREATE DATABASE IF NOT EXISTS user_db;"

# Health checks
echo "🏥 Running health checks..."
for i in {1..10}; do
    if curl -s http://localhost:8000/health > /dev/null; then
        echo "✅ API Gateway is healthy"
        break
    fi
    echo "⏳ Waiting for API Gateway... ($i/10)"
    sleep 2
done

for i in {1..10}; do
    if curl -s http://localhost:8001/health > /dev/null; then
        echo "✅ Auth Service is healthy"
        break
    fi
    echo "⏳ Waiting for Auth Service... ($i/10)"
    sleep 2
done

for i in {1..10}; do
    if curl -s http://localhost:8002/health > /dev/null; then
        echo "✅ User Service is healthy"
        break
    fi
    echo "⏳ Waiting for User Service... ($i/10)"
    sleep 2
done

echo ""
echo "✅ Setup completed successfully!"
echo ""
echo "📍 Services running on:"
echo "   - API Gateway:  http://localhost:8000"
echo "   - Auth Service: http://localhost:8001"
echo "   - User Service: http://localhost:8002"
echo "   - PostgreSQL (Auth): localhost:5432"
echo "   - PostgreSQL (User): localhost:5433"
echo "   - Redis: localhost:6379"
echo "   - RabbitMQ Management: http://localhost:15672 (guest/guest)"
echo ""
echo "🧪 Test login:"
echo "   curl -X POST http://localhost:8000/api/auth/register \\"
echo "   -H 'Content-Type: application/json' \\"
echo "   -d '{\"email\": \"test@example.com\", \"password\": \"test123\", \"phone\": \"+212612345678\", \"role\": \"passenger\"}'"
echo ""
echo "📖 More info: cat README.md"
