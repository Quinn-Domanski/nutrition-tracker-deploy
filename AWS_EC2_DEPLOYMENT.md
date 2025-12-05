# AWS EC2 Deployment Guide

## Step 1: Launch EC2 Instance

1. Go to **AWS Console** → **EC2** → **Instances** → **Launch Instances**
2. Select **Ubuntu Server 22.04 LTS** (free tier eligible)
3. Instance Type: **t2.micro** or **t3.micro** (free tier)
4. Storage: **20GB** (free tier)
5. Security Group: Allow:
   - Port 22 (SSH)
   - Port 80 (HTTP)
   - Port 443 (HTTPS)
6. Create/select key pair and download `.pem` file
7. Launch instance

## Step 2: Connect to EC2

```bash
# Make key readable
chmod 600 my-key.pem

# SSH into instance
ssh -i my-key.pem ubuntu@<EC2_PUBLIC_IP>
```

## Step 3: Install Docker

```bash
sudo apt-get update
sudo apt-get install -y docker.io docker-compose

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Start Docker
sudo systemctl start docker
sudo systemctl enable docker
```

## Step 4: Login to Docker Hub

```bash
docker login
# Enter your Docker Hub credentials
```

## Step 5: Clone/Upload Project

```bash
# Option A: Clone from Git
git clone https://github.com/your-repo/dbmsnutritiontracker-deploy.git
cd dbmsnutritiontracker-deploy

# Option B: Or copy files via SCP from local machine
scp -i my-key.pem -r . ubuntu@<EC2_IP>:~/nutrition-tracker
ssh -i my-key.pem ubuntu@<EC2_IP>
cd ~/nutrition-tracker
```

## Step 6: Configure Environment

```bash
# Create .env file
cat > .env << EOF
DB_USER=nutrition_user
DB_PASSWORD=YourSecurePassword123!
DB_NAME=nutrition_dev
EOF

# Update backend/.env.deploy
# Change FRONTEND_URL to your domain or EC2 public IP
nano backend/.env.deploy
```

Example for **frontend/.env.deploy**:
```
VITE_API_URL=https://your-domain.com/api
```

## Step 7: Start Services

```bash
# Pull latest images from Docker Hub
docker-compose -f docker-compose.deploy.yml pull

# Start containers
docker-compose -f docker-compose.deploy.yml up -d

# Check status
docker-compose -f docker-compose.deploy.yml ps

# View logs
docker-compose -f docker-compose.deploy.yml logs -f
```

## Step 8: Initialize Database

```bash
# Load schema into PostgreSQL
docker-compose -f docker-compose.deploy.yml exec postgres psql -U nutrition_user -d nutrition_dev < nutrition_schema.sql

# Verify
docker-compose -f docker-compose.deploy.yml exec postgres psql -U nutrition_user -d nutrition_dev -c "\dt"
```

## Step 9: Setup HTTPS (Let's Encrypt)

### Option A: Using Nginx with Let's Encrypt

```bash
# Install certbot
sudo apt-get install -y certbot python3-certbot-nginx

# Get certificate (replace with your domain)
sudo certbot certonly --standalone -d nutrition-tracker.example.com

# Certificates stored in: /etc/letsencrypt/live/nutrition-tracker.example.com/
```

### Option B: Use AWS Certificate Manager (Recommended)

1. Go to AWS Console → Certificate Manager
2. Request a certificate for your domain
3. Validate domain ownership
4. Use certificate with AWS Load Balancer (optional)

## Step 10: Configure Nginx for HTTPS

Update `frontend/nginx.conf`:

```nginx
server {
    listen 443 ssl http2;
    server_name nutrition-tracker.example.com;

    ssl_certificate /etc/letsencrypt/live/nutrition-tracker.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/nutrition-tracker.example.com/privkey.pem;

    root /usr/share/nginx/html;
    index index.html;

    client_max_body_size 20M;

    location / {
        try_files $uri /index.html;
        expires 1h;
        add_header Cache-Control "public, immutable";
    }

    location /api/ {
        proxy_pass http://nutrition-backend:5000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Connection "";
        
        proxy_connect_timeout 60s;
        proxy_send_timeout 120s;
        proxy_read_timeout 120s;
    }
}

# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name nutrition-tracker.example.com;
    return 301 https://$server_name$request_uri;
}
```

Then restart:
```bash
docker-compose -f docker-compose.deploy.yml restart frontend
```

## Step 11: Setup Domain

1. Get a domain from Route53, GoDaddy, Namecheap, etc.
2. Create DNS records pointing to EC2 public IP:
   ```
   A record: nutrition-tracker.example.com → <EC2_PUBLIC_IP>
   ```

## Access Application

```
https://nutrition-tracker.example.com
```

## Monitoring

```bash
# Check container status
docker-compose -f docker-compose.deploy.yml ps

# View logs
docker-compose -f docker-compose.deploy.yml logs -f backend
docker-compose -f docker-compose.deploy.yml logs -f frontend
docker-compose -f docker-compose.deploy.yml logs -f postgres

# Check disk space
df -h

# Check memory usage
free -h
```

## Database Backup

```bash
# Backup
docker-compose -f docker-compose.deploy.yml exec -T postgres pg_dump -U nutrition_user nutrition_dev > backup-$(date +%Y%m%d-%H%M%S).sql

# Restore
docker-compose -f docker-compose.deploy.yml exec -T postgres psql -U nutrition_user nutrition_dev < backup-20231215-120000.sql
```

## Troubleshooting

### Port 80/443 already in use
```bash
sudo lsof -i :80
sudo lsof -i :443
sudo kill -9 <PID>
```

### Container keeps restarting
```bash
docker-compose -f docker-compose.deploy.yml logs postgres
docker-compose -f docker-compose.deploy.yml logs backend
```

### Out of disk space
```bash
docker system prune -a
docker volume prune
```

### Database connection errors
```bash
docker-compose -f docker-compose.deploy.yml exec postgres psql -U nutrition_user -d nutrition_dev -c "SELECT version();"
```

## Security Tips

1. **Change default passwords** in `.env` and `backend/.env.deploy`
2. **Use strong secrets** for `SECRET_KEY` and `JWT_SECRET`
3. **Enable firewall** on EC2
4. **Use VPC** instead of public subnet
5. **Set up CloudWatch** for monitoring
6. **Enable EC2 detailed monitoring**
7. **Rotate secrets regularly**

## Cost Optimization

- **Free tier**: t2.micro/t3.micro with 1GB RAM, 8GB EBS
- **Storage**: 20GB free EBS
- **Data transfer**: 100GB free outbound per month
- **Stop instance** when not in use to save costs
- **Use spot instances** for non-production

## Auto-restart on Reboot

```bash
# Make docker-compose start on system reboot
sudo systemctl restart docker
docker-compose -f docker-compose.deploy.yml up -d

# Verify
sudo systemctl status docker
```

## Next Steps

1. Setup monitoring (CloudWatch, Datadog, etc.)
2. Setup automated backups
3. Setup CI/CD pipeline (GitHub Actions, GitLab CI)
4. Configure auto-scaling (Load Balancer + ASG)
5. Setup RDS for managed PostgreSQL (optional)
