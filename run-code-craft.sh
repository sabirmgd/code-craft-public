#!/bin/bash

set -e  # Exit on error

echo "🔐 Logging in to Docker Hub..."
echo "$1" | docker login -u sabirmgd --password-stdin

echo "🧹 Stopping old containers if any..."
docker rm -f docsgen_postgres docsgen_redis docsgen_backend docsgen_frontend 2>/dev/null || true

echo "📦 Pulling latest images..."
docker pull sabirmgd/code-craft-backend:latest
docker pull sabirmgd/code-craft-frontend:latest

echo "🚀 Starting services..."

# Run Postgres
docker run -d --rm \
  --name docsgen_postgres \
  -e POSTGRES_USER=myuser \
  -e POSTGRES_PASSWORD=mypass \
  -e POSTGRES_DB=mydb \
  -p 5433:5432 \
  -v docsgen_db_data:/var/lib/postgresql/data \
  postgres:15

# Run Redis
docker run -d --rm \
  --name docsgen_redis \
  -p 6380:6379 \
  redis:7-alpine

# Run Backend
docker run -d --rm \
  --name docsgen_backend \
  --link docsgen_postgres:postgres \
  --link docsgen_redis:redis \
  -e DB_HOST=postgres \
  -e DB_PORT=5432 \
  -e DB_USERNAME=myuser \
  -e DB_PASSWORD=mypass \
  -e DB_DATABASE=mydb \
  -e REDIS_HOST=redis \
  -e REDIS_PORT=6379 \
  -e ENCRYPTION_SECRET=some-32-char-random-string \
  -e LICENSE_KEY=MY_SUPER_SECRET_LICENSE_KEY \
  -e NODE_ENV=production \
  -p 3001:3001 \
  sabirmgd/code-craft-backend:latest

# Run Frontend
docker run -d --rm \
  --name docsgen_frontend \
  --link docsgen_backend:backend \
  -e NEXT_PUBLIC_API_URL=http://localhost:3001 \
  -p 3000:3000 \
  sabirmgd/code-craft-frontend:latest

echo "📡 Tailing logs (Ctrl+C to stop)..."
docker logs -f docsgen_backend
