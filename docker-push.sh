#!/bin/bash

set -e

DOCKER_USER="quinn341"
DOCKER_REGISTRY="docker.io"
BACKEND_IMAGE="nutrition-backend"
FRONTEND_IMAGE="nutrition-frontend"
TAG="latest"

echo "=========================================="
echo "Docker Push to Docker Hub"
echo "=========================================="
echo "Registry: $DOCKER_REGISTRY"
echo "Username: $DOCKER_USER"
echo ""

# Proceed with build and push

# Build images
echo "Building images..."
docker-compose build --no-cache

echo ""
echo "=========================================="
echo "Tagging images..."
echo "=========================================="

# Tag backend (docker-compose uses directory prefix)
docker tag dbmsnutritiontracker-deploy-backend:latest $DOCKER_USER/$BACKEND_IMAGE:$TAG
docker tag dbmsnutritiontracker-deploy-backend:latest $DOCKER_USER/$BACKEND_IMAGE:$(date +%Y%m%d)
echo "✓ Tagged backend: $DOCKER_USER/$BACKEND_IMAGE:$TAG"

# Tag frontend (docker-compose uses directory prefix)
docker tag dbmsnutritiontracker-deploy-frontend:latest $DOCKER_USER/$FRONTEND_IMAGE:$TAG
docker tag dbmsnutritiontracker-deploy-frontend:latest $DOCKER_USER/$FRONTEND_IMAGE:$(date +%Y%m%d)
echo "✓ Tagged frontend: $DOCKER_USER/$FRONTEND_IMAGE:$TAG"

echo ""
echo "=========================================="
echo "Pushing images..."
echo "=========================================="

# Push backend
echo "Pushing backend..."
docker push $DOCKER_USER/$BACKEND_IMAGE:$TAG
docker push $DOCKER_USER/$BACKEND_IMAGE:$(date +%Y%m%d)
echo "✓ Pushed backend"

# Push frontend
echo "Pushing frontend..."
docker push $DOCKER_USER/$FRONTEND_IMAGE:$TAG
docker push $DOCKER_USER/$FRONTEND_IMAGE:$(date +%Y%m%d)
echo "✓ Pushed frontend"

echo ""
echo "=========================================="
echo "✓ Push complete!"
echo "=========================================="
echo ""
echo "Images available at:"
echo "  Backend:  docker.io/$DOCKER_USER/$BACKEND_IMAGE:$TAG"
echo "  Frontend: docker.io/$DOCKER_USER/$FRONTEND_IMAGE:$TAG"
echo ""
