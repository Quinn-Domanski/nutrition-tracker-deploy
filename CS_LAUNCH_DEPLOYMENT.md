# NutritionTrax - CS Launch Deployment Guide

This guide walks through deploying the NutritionTrax application to Virginia Tech's CS Launch (Kubernetes) platform.

## Prerequisites

- Access to CS Launch at https://launch.cs.vt.edu
- Docker Hub account (or other container registry)
- `kubectl` command-line tool installed locally
- Docker installed locally

## Step 1: Push Docker Images to Registry

### 1.1 Log in to Docker Hub
```bash
docker login
```

### 1.2 Build and Push Backend Image
```bash
cd backend
docker build -t YOUR_DOCKERHUB_USERNAME/nutritiontrax-backend:latest .
docker push YOUR_DOCKERHUB_USERNAME/nutritiontrax-backend:latest
```

### 1.3 Build and Push Frontend Image
```bash
cd frontend
docker build -t YOUR_DOCKERHUB_USERNAME/nutritiontrax-frontend:latest .
docker push YOUR_DOCKERHUB_USERNAME/nutritiontrax-frontend:latest
```

**Note:** Replace `YOUR_DOCKERHUB_USERNAME` with your actual Docker Hub username in both the build commands and the Kubernetes manifests (`05-backend.yaml` and `06-frontend.yaml`).

## Step 2: Set Up Project on CS Launch

1. Go to https://launch.cs.vt.edu
2. Log in with your CS credentials
3. Click on **Discovery** cluster
4. Click **Projects/Namespaces** → **Create Project**
5. Name it: `nutritiontrax`
6. Click **Create**

## Step 3: Create Namespace

1. Click **Projects/Namespaces**
2. Click **Create Namespace** for the nutritiontrax project
3. Name it: `nutritiontrax`
4. Click **Create**

## Step 4: Update Kubernetes Manifests

Before deploying, update the image references in the YAML files:

**In `k8s/05-backend.yaml` (line ~31):**
```yaml
image: YOUR_DOCKERHUB_USERNAME/nutritiontrax-backend:latest
```

**In `k8s/06-frontend.yaml` (line ~26):**
```yaml
image: YOUR_DOCKERHUB_USERNAME/nutritiontrax-frontend:latest
```

## Step 5: Deploy via CS Launch Web Interface

### 5.1 Create Secrets

From your **Cluster Dashboard**:

1. Click **Storage** → **Secrets** → **Create**
2. Select **Opaque** type
3. Upload the secrets from `k8s/01-secrets.yaml`
   - Create `postgres-secret` with keys: POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_DB
   - Create `backend-secret` with keys: SECRET_KEY, JWT_SECRET, USDA_KEY

**⚠️ IMPORTANT:** Change all placeholder passwords and secrets to secure values before deploying!

### 5.2 Create ConfigMaps

1. Click **Storage** → **ConfigMaps** → **Create**
2. Create `backend-config` with the values from `k8s/02-configmap.yaml`
3. Create `init-db` with the database schema SQL from `schema_fixed.sql`

### 5.3 Deploy PostgreSQL

1. Click **Apps** → **Charts**
2. Select **postgres** chart (or use manual deployment)
3. Configure with the secret values
4. Deploy to `nutritiontrax` namespace

**Alternative:** Use the Workloads interface to create a StatefulSet using the manifests provided.

### 5.4 Deploy Backend

1. Click **Workloads** → **Create** → **Deployment**
2. Name: `backend`
3. Container Image: `YOUR_DOCKERHUB_USERNAME/nutritiontrax-backend:latest`
4. Add Port: 5000 (TCP)
5. Add environment variables from `k8s/05-backend.yaml`
6. Click **Create**

### 5.5 Deploy Frontend

1. Click **Workloads** → **Create** → **Deployment**
2. Name: `frontend`
3. Container Image: `YOUR_DOCKERHUB_USERNAME/nutritiontrax-frontend:latest`
4. Add Port: 80 (TCP)
5. Click **Create**

## Step 6: Create Ingress

1. Click **Service Discovery** → **Ingresses** → **Create**
2. Name: `nutritiontrax-ingress`
3. Request Host: `nutritiontrax.discovery.cs.vt.edu`
4. Path: `/`
5. Target Service: `frontend` (port 80)
6. Click **Create**

**For API routing:**
1. Create another ingress
2. Name: `nutritiontrax-api-ingress`
3. Request Host: `nutritiontrax.discovery.cs.vt.edu`
4. Path: `/api`
5. Target Service: `backend` (port 5000)
6. Click **Create**

## Step 7: Using kubectl (Alternative Method)

If you have `kubectl` configured with CS Launch access:

```bash
# Update image references in YAML files
sed -i 's/YOUR_DOCKERHUB_USERNAME/your-username/g' k8s/*.yaml

# Create namespace and deploy
kubectl create namespace nutritiontrax
kubectl apply -f k8s/01-secrets.yaml
kubectl apply -f k8s/02-configmap.yaml
kubectl apply -f k8s/04-init-db-configmap.yaml
kubectl apply -f k8s/03-postgres.yaml
kubectl apply -f k8s/05-backend.yaml
kubectl apply -f k8s/06-frontend.yaml
kubectl apply -f k8s/07-ingress.yaml

# Verify deployments
kubectl get deployments -n nutritiontrax
kubectl get pods -n nutritiontrax
```

## Step 8: Access Your Application

Once everything is deployed and running:

- **Frontend:** https://nutritiontrax.discovery.cs.vt.edu
- **API:** https://nutritiontrax.discovery.cs.vt.edu/api

## Troubleshooting

### Check Pod Status
```bash
kubectl get pods -n nutritiontrax
kubectl describe pod <pod-name> -n nutritiontrax
kubectl logs <pod-name> -n nutritiontrax
```

### Database Connection Issues
```bash
kubectl exec -it postgres-0 -n nutritiontrax -- psql -U nutrition_user -d nutrition_prod
```

### Backend Not Starting
- Check image is pushed to registry
- Verify environment variables are set
- Check logs: `kubectl logs <backend-pod> -n nutritiontrax`

### Frontend Issues
- Clear browser cache
- Check nginx logs in frontend pod
- Verify API endpoint is correct in frontend code

## Security Notes

1. **Change all default secrets** in `k8s/01-secrets.yaml` before deployment
2. Use environment variables from CS Launch Secrets, not hardcoded values
3. Enable HTTPS (automatically done via ingress with cert-manager)
4. Set `SECURE_COOKIES: True` in production (already configured)
5. Review CORS settings in `backend/config.py` for production URL

## Production Checklist

- [ ] Docker images pushed to registry
- [ ] All passwords and secrets changed in `k8s/01-secrets.yaml`
- [ ] Image references updated in `k8s/05-backend.yaml` and `k8s/06-frontend.yaml`
- [ ] Namespace created on CS Launch
- [ ] All secrets created on CS Launch
- [ ] ConfigMaps created with correct values
- [ ] PostgreSQL database deployed
- [ ] Backend deployment running and healthy
- [ ] Frontend deployment running and healthy
- [ ] Ingress configured and accessible
- [ ] Application tested at https://nutritiontrax.discovery.cs.vt.edu
- [ ] Database tables initialized (verify via Adminer if deployed)

## Support

For issues with CS Launch, see: https://wiki.cs.vt.edu/HowTo:CS_Launch
