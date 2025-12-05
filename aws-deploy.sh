#!/bin/bash

set -e

echo "=========================================="
echo "AWS EC2 Deployment Script"
echo "=========================================="
echo ""
echo "Prerequisites:"
echo "  - AWS CLI installed and configured"
echo "  - EC2 instance running (Ubuntu 22.04 or similar)"
echo "  - Security group allowing ports 22, 80, 443"
echo ""

read -p "Enter EC2 instance IP or hostname: " EC2_HOST
read -p "Enter SSH key path (e.g., ~/.ssh/my-key.pem): " SSH_KEY
read -p "Enter SSH username (default: ubuntu): " SSH_USER
SSH_USER=${SSH_USER:-ubuntu}

echo ""
echo "Testing SSH connection..."
if ! ssh -i "$SSH_KEY" -o ConnectTimeout=5 "$SSH_USER@$EC2_HOST" "echo 'SSH OK'" > /dev/null 2>&1; then
    echo "❌ Cannot connect to $SSH_USER@$EC2_HOST"
    exit 1
fi

echo "✓ SSH connection successful"
echo ""

# Deploy script
DEPLOY_SCRIPT=$(cat <<'DEPLOY_EOF'
#!/bin/bash
set -e

echo "=========================================="
echo "Setting up EC2 instance..."
echo "=========================================="

# Update system
sudo apt-get update
sudo apt-get upgrade -y

# Install Docker
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    sudo apt-get install -y docker.io docker-compose
    sudo usermod -aG docker $USER
    sudo systemctl start docker
    sudo systemctl enable docker
else
    echo "✓ Docker already installed"
fi

# Install certbot for HTTPS
if ! command -v certbot &> /dev/null; then
    echo "Installing certbot..."
    sudo apt-get install -y certbot
else
    echo "✓ Certbot already installed"
fi

echo "✓ System setup complete"
DEPLOY_EOF
)

echo "Setting up EC2 instance..."
ssh -i "$SSH_KEY" "$SSH_USER@$EC2_HOST" bash << EOF
$DEPLOY_SCRIPT
EOF

echo ""
echo "Uploading project files..."
# Copy project to EC2
scp -i "$SSH_KEY" -r . "$SSH_USER@$EC2_HOST:~/nutrition-tracker"

echo ""
echo "=========================================="
echo "EC2 Deployment Complete!"
echo "=========================================="
echo ""
echo "Next steps on EC2:"
echo "  1. SSH into instance:"
echo "     ssh -i $SSH_KEY $SSH_USER@$EC2_HOST"
echo ""
echo "  2. Navigate to project:"
echo "     cd ~/nutrition-tracker"
echo ""
echo "  3. Create .env file:"
echo "     cat > .env << 'EOL'"
echo "     DB_USER=nutrition_user"
echo "     DB_PASSWORD=your_secure_password"
echo "     DB_NAME=nutrition_dev"
echo "     EOL"
echo ""
echo "  4. Update backend/.env.deploy with your domain"
echo ""
echo "  5. Start services:"
echo "     docker-compose -f docker-compose.deploy.yml pull"
echo "     docker-compose -f docker-compose.deploy.yml up -d"
echo ""
echo "  6. Setup HTTPS with Let's Encrypt:"
echo "     sudo certbot certonly --standalone -d your-domain.com"
echo ""
echo "  7. Update nginx.conf with SSL certificates (if needed)"
echo ""
