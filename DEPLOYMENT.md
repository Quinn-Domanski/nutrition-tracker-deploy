# Deployment Guide

## Prerequisites

Before deploying, ensure:
1. Docker images are pushed to Docker Hub
2. SSH access to launch.cs.vt.edu
3. Docker and Docker Compose installed on the server

---

## Step 1: Push Docker Images to Docker Hub

Run the push script locally:

```bash
./docker-push.sh
```

This will:
- Build backend and frontend images
- Tag them with `latest` and today's date
- Push them to `quinn341/nutrition-backend` and `quinn341/nutrition-frontend`

---

## Step 2: Deploy to launch.cs.vt.edu

### Option A: Manual Deployment via SSH

1. **SSH into the server:**
   ```bash
   ssh user@launch.cs.vt.edu
   ```

2. **Navigate to project directory:**
   ```bash
   cd /path/to/dbmsnutritiontracker-deploy
   ```

3. **Update files from repository:**
   ```bash
   git pull origin main
   ```

4. **Create .env file (if not present):**
   ```bash
   cat > .env << EOF
   DB_USER=nutrition_user
   DB_PASSWORD=your_secure_password
   DB_NAME=nutrition_dev
   EOF
   ```

5. **Update backend .env:**
   ```bash
   # Edit backend/.env.deploy with production values
   vim backend/.env.deploy
   ```
   
   Key variables to update:
   - `FRONTEND_URL`: Set to actual domain
   - `SECRET_KEY`: Generate a secure key
   - `JWT_SECRET`: Generate a secure key
   - `SECURE_COOKIES`: Set to `true` for HTTPS

6. **Pull and start services:**
   ```bash
   docker-compose -f docker-compose.deploy.yml pull
   docker-compose -f docker-compose.deploy.yml up -d
   ```

7. **Verify services are running:**
   ```bash
   docker-compose -f docker-compose.deploy.yml ps
   ```

8. **Check logs:**
   ```bash
   docker-compose -f docker-compose.deploy.yml logs -f
   ```

---

### Option B: Automated Deployment Script

Create a deployment script on the server or use SSH:

```bash
ssh user@launch.cs.vt.edu << 'EOF'
cd /path/to/dbmsnutritiontracker-deploy
git pull origin main
docker-compose -f docker-compose.deploy.yml pull
docker-compose -f docker-compose.deploy.yml down
docker-compose -f docker-compose.deploy.yml up -d
docker-compose -f docker-compose.deploy.yml logs --tail=20
EOF
```

---

## Step 3: Setup Reverse Proxy (Nginx)

If launch.cs.vt.edu uses nginx at the host level:

```nginx
server {
    listen 443 ssl http2;
    server_name nutrition-tracker.discovery.cs.vt.edu;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    location / {
        proxy_pass http://localhost;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

---

## Troubleshooting

### Check if containers are running:
```bash
docker ps
```

### View container logs:
```bash
docker-compose logs backend
docker-compose logs frontend
docker-compose logs postgres
```

### Restart services:
```bash
docker-compose restart
```

### Stop all services:
```bash
docker-compose down
```

### Rebuild without cache:
```bash
docker pull quinn341/nutrition-backend:latest
docker pull quinn341/nutrition-frontend:latest
docker-compose -f docker-compose.deploy.yml up -d
```

---

## Rollback to Previous Version

Push images with date tags, then:

```bash
docker pull quinn341/nutrition-backend:20231215
docker-compose down
# Update docker-compose.deploy.yml to use specific tag
docker-compose -f docker-compose.deploy.yml up -d
```

---

## Database Backups

To backup the PostgreSQL database:

```bash
docker-compose exec postgres pg_dump -U nutrition_user nutrition_dev > backup-$(date +%Y%m%d).sql
```

To restore:

```bash
docker-compose exec -T postgres psql -U nutrition_user nutrition_dev < backup-20231215.sql
```

---

## Health Checks

Verify services are responding:

```bash
# Backend health
curl http://localhost/api/health

# Frontend
curl http://localhost

# Database
docker-compose exec postgres pg_isready -U nutrition_user
```
