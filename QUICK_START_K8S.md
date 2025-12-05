# NutritionTrax on CS Launch - Quick Start

## TL;DR - 5 Minute Setup

### 1. Push Images to Docker Hub
```bash
# Build and push backend
cd backend
docker build -t YOUR_USERNAME/nutritiontrax-backend:latest .
docker push YOUR_USERNAME/nutritiontrax-backend:latest
cd ..

# Build and push frontend  
cd frontend
docker build -t YOUR_USERNAME/nutritiontrax-frontend:latest .
docker push YOUR_USERNAME/nutritiontrax-frontend:latest
cd ..
```

### 2. Create Project on CS Launch
- Go to https://launch.cs.vt.edu
- Select **Discovery** cluster
- Click **Projects/Namespaces** → **Create Project** → Name: `nutritiontrax`
- Click **Create Namespace** → Name: `nutritiontrax`

### 3. Create Secrets on CS Launch
**Storage → Secrets → Create**

Create two secrets:
- **postgres-secret** (Opaque):
  - POSTGRES_USER: `nutrition_user`
  - POSTGRES_PASSWORD: `ChangeMe123!ChangeMe` ⚠️ **Change this!**
  - POSTGRES_DB: `nutrition_prod`

- **backend-secret** (Opaque):
  - SECRET_KEY: `GenerateNewSecureKey` ⚠️ **Change this!**
  - JWT_SECRET: `GenerateNewJWTSecret` ⚠️ **Change this!**
  - USDA_KEY: `91EtLz7zkCFgpJc7IC8s1gjfd4c8e8lbPXh60vqb`

### 4. Create ConfigMaps
**Storage → ConfigMaps → Create**

- **backend-config** (Key-Value):
  ```
  FLASK_ENV: production
  DB_HOST: postgres
  DB_PORT: 5432
  FRONTEND_URL: https://nutritiontrax.discovery.cs.vt.edu
  SECURE_COOKIES: True
  PYTHONUNBUFFERED: 1
  ```

- **init-db** (Binary Data):
  - Key: `01-schema.sql`
  - Value: Copy contents of `schema_fixed.sql`

### 5. Deploy Services

**Workloads → Create → Deployment**

**PostgreSQL:**
- Name: `postgres`
- Image: `postgres:15`
- Ports: 5000 → 5432
- Environment (from secrets):
  - POSTGRES_USER
  - POSTGRES_PASSWORD
  - POSTGRES_DB

**Backend:**
- Name: `backend`
- Image: `YOUR_USERNAME/nutritiontrax-backend:latest`
- Ports: 5000 → 5000
- Environment (from secrets and configmap)

**Frontend:**
- Name: `frontend`
- Image: `YOUR_USERNAME/nutritiontrax-frontend:latest`
- Ports: 80 → 80

### 6. Create Ingress
**Service Discovery → Ingresses → Create**

- Name: `nutritiontrax-ingress`
- Request Host: `nutritiontrax.discovery.cs.vt.edu`
- Path: `/`
- Target Service: `frontend` (port 80)

**Second Ingress for API:**
- Name: `nutritiontrax-api-ingress`
- Request Host: `nutritiontrax.discovery.cs.vt.edu`
- Path: `/api`
- Target Service: `backend` (port 5000)

### 7. Access Application
```
https://nutritiontrax.discovery.cs.vt.edu
```

## Important Notes

⚠️ **BEFORE DEPLOYING:**
1. Change all default passwords and secrets
2. Update Docker image references to use YOUR_USERNAME
3. Generate strong SECRET_KEY and JWT_SECRET values

## Troubleshooting

**Pods not starting?**
```bash
kubectl describe pod <pod-name> -n nutritiontrax
kubectl logs <pod-name> -n nutritiontrax
```

**Database connection error?**
- Verify postgres pod is running
- Check DB credentials match in secrets

**Frontend/Backend not communicating?**
- Check ingress is correctly configured
- Verify backend health: `GET /health`
- Check FRONTEND_URL in ConfigMap

**Still stuck?**
See full guide: `CS_LAUNCH_DEPLOYMENT.md`
