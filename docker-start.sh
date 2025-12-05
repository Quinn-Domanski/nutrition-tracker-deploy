#!/bin/bash

set -e

echo "=========================================="
echo "Nutrition Tracker Docker Startup"
echo "=========================================="

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "❌ Error: .env file not found!"
    echo "Please create .env file with the following variables:"
    echo "  DB_USER=nutrition_user"
    echo "  DB_PASSWORD=your_password"
    echo "  DB_NAME=nutrition_dev"
    exit 1
fi

echo "✓ .env file found"

# Check if docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Error: Docker is not running!"
    exit 1
fi

echo "✓ Docker is running"

# Build and start containers
echo ""
echo "Building and starting containers..."
docker-compose up -d --build

echo ""
echo "Waiting for services to be ready..."
sleep 5

# Check service health
echo ""
echo "Checking service health..."

# Check PostgreSQL
if docker-compose exec -T postgres pg_isready -U $(grep DB_USER .env | cut -d= -f2) > /dev/null 2>&1; then
    echo "✓ PostgreSQL is running"
else
    echo "⚠ PostgreSQL health check pending..."
fi

# Check Backend
if docker-compose exec -T backend curl -f http://localhost:5000/health > /dev/null 2>&1; then
    echo "✓ Backend (Gunicorn) is running"
else
    echo "⚠ Backend health check pending..."
fi

# Check Frontend
if curl -f http://localhost/health > /dev/null 2>&1; then
    echo "✓ Frontend (Nginx) is running"
else
    echo "⚠ Frontend is starting..."
fi

echo ""
echo "=========================================="
echo "✓ Services started successfully!"
echo "=========================================="
echo ""
echo "URLs:"
echo "  Frontend: http://localhost"
echo "  API:      http://localhost/api"
echo ""
echo "Commands:"
echo "  View logs:  docker-compose logs -f"
echo "  Stop:       docker-compose down"
echo "  Clean:      docker-compose down -v"
echo ""
