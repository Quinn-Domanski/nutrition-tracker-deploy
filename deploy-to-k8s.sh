#!/bin/bash
set -e

# NutritionTrax - Kubernetes Deployment Script
# This script helps deploy to CS Launch

DOCKER_USERNAME="${1:-}"
NAMESPACE="nutritiontrax"
PROJECT_NAME="nutritiontrax"

if [ -z "$DOCKER_USERNAME" ]; then
    echo "Usage: ./deploy-to-k8s.sh <docker-hub-username>"
    echo ""
    echo "Example: ./deploy-to-k8s.sh quinn"
    exit 1
fi

echo "=========================================="
echo "NutritionTrax Kubernetes Deployment"
echo "=========================================="
echo ""
echo "Docker Hub Username: $DOCKER_USERNAME"
echo "Namespace: $NAMESPACE"
echo ""

# Step 1: Build and push images
echo "Step 1: Building and pushing Docker images..."
echo ""

echo "Building backend image..."
cd backend
docker build -t ${DOCKER_USERNAME}/nutritiontrax-backend:latest .
docker push ${DOCKER_USERNAME}/nutritiontrax-backend:latest
cd ..

echo "Building frontend image..."
cd frontend
docker build -t ${DOCKER_USERNAME}/nutritiontrax-frontend:latest .
docker push ${DOCKER_USERNAME}/nutritiontrax-frontend:latest
cd ..

echo "✓ Images built and pushed successfully"
echo ""

# Step 2: Update manifests
echo "Step 2: Updating Kubernetes manifests..."
sed -i "s|YOUR_DOCKERHUB_USERNAME|${DOCKER_USERNAME}|g" k8s/05-backend.yaml
sed -i "s|YOUR_DOCKERHUB_USERNAME|${DOCKER_USERNAME}|g" k8s/06-frontend.yaml
echo "✓ Manifests updated"
echo ""

# Step 3: Apply manifests (if kubectl is available)
if command -v kubectl &> /dev/null; then
    echo "Step 3: Applying Kubernetes manifests..."
    echo ""
    
    read -p "Have you created the namespace '${NAMESPACE}' on CS Launch? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
        kubectl apply -f k8s/01-secrets.yaml
        kubectl apply -f k8s/02-configmap.yaml
        kubectl apply -f k8s/04-init-db-configmap.yaml
        kubectl apply -f k8s/03-postgres.yaml
        kubectl apply -f k8s/05-backend.yaml
        kubectl apply -f k8s/06-frontend.yaml
        kubectl apply -f k8s/07-ingress.yaml
        
        echo "✓ Manifests applied successfully"
        echo ""
        echo "Checking deployment status..."
        kubectl get deployments -n ${NAMESPACE}
        kubectl get pods -n ${NAMESPACE}
    else
        echo ""
        echo "Please create the namespace on CS Launch first, then run kubectl apply commands:"
        echo "  kubectl apply -f k8s/01-secrets.yaml"
        echo "  kubectl apply -f k8s/02-configmap.yaml"
        echo "  kubectl apply -f k8s/04-init-db-configmap.yaml"
        echo "  kubectl apply -f k8s/03-postgres.yaml"
        echo "  kubectl apply -f k8s/05-backend.yaml"
        echo "  kubectl apply -f k8s/06-frontend.yaml"
        echo "  kubectl apply -f k8s/07-ingress.yaml"
    fi
else
    echo "Step 3: kubectl not found - using CS Launch web interface"
    echo ""
    echo "Manual deployment steps:"
    echo "1. Go to https://launch.cs.vt.edu"
    echo "2. Select Discovery cluster"
    echo "3. Create project: ${PROJECT_NAME}"
    echo "4. Create namespace: ${NAMESPACE}"
    echo "5. Follow the web interface to deploy manifests from k8s/ directory"
fi

echo ""
echo "=========================================="
echo "Deployment script complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. ⚠️  CHANGE ALL SECRETS in k8s/01-secrets.yaml"
echo "2. Create the secrets on CS Launch"
echo "3. Create ConfigMaps"
echo "4. Deploy PostgreSQL"
echo "5. Deploy backend and frontend"
echo "6. Create ingress"
echo ""
echo "Access your app at: https://nutritiontrax.discovery.cs.vt.edu"
