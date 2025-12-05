#!/bin/bash

set -e

REMOTE_HOST="${1:-launch.cs.vt.edu}"
REMOTE_USER="${2:-user}"
REMOTE_PATH="${3:-/home/apps/nutrition-tracker}"

echo "=========================================="
echo "Deploying to launch.cs.vt.edu"
echo "=========================================="
echo "Host: $REMOTE_HOST"
echo "User: $REMOTE_USER"
echo "Path: $REMOTE_PATH"
echo ""

# Check SSH connectivity
echo "Checking SSH connectivity..."
if ! ssh -o ConnectTimeout=5 "$REMOTE_USER@$REMOTE_HOST" "echo 'SSH OK'" > /dev/null 2>&1; then
    echo "❌ Cannot connect to $REMOTE_USER@$REMOTE_HOST"
    echo "Usage: ./deploy-to-launch.sh [host] [user] [path]"
    exit 1
fi

echo "✓ SSH connection successful"
echo ""

# Step 1: Push images to Docker Hub
echo "=========================================="
echo "Step 1: Pushing images to Docker Hub"
echo "=========================================="
./docker-push.sh

echo ""
echo "=========================================="
echo "Step 2: Deploying to remote server"
echo "=========================================="

# Deploy script
DEPLOY_SCRIPT=$(cat <<'DEPLOY_EOF'
#!/bin/bash
set -e

REMOTE_PATH="$1"

echo "Pulling latest code..."
cd "$REMOTE_PATH"
git pull origin main

echo "Pulling latest Docker images..."
docker-compose -f docker-compose.deploy.yml pull

echo "Stopping old containers..."
docker-compose -f docker-compose.deploy.yml down || true

echo "Starting new containers..."
docker-compose -f docker-compose.deploy.yml up -d

echo "Waiting for services to be ready..."
sleep 5

echo ""
echo "Checking service health..."
docker-compose -f docker-compose.deploy.yml ps

echo ""
echo "Recent logs:"
docker-compose -f docker-compose.deploy.yml logs --tail=10

DEPLOY_EOF
)

# Execute remote deployment
ssh "$REMOTE_USER@$REMOTE_HOST" bash << EOF
$DEPLOY_SCRIPT
$REMOTE_PATH
EOF

echo ""
echo "=========================================="
echo "✓ Deployment complete!"
echo "=========================================="
echo ""
echo "Services should now be running at:"
echo "  https://nutrition-tracker.discovery.cs.vt.edu"
echo ""
echo "Monitor logs with:"
echo "  ssh $REMOTE_USER@$REMOTE_HOST"
echo "  cd $REMOTE_PATH"
echo "  docker-compose -f docker-compose.deploy.yml logs -f"
echo ""
