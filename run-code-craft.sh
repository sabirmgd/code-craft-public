#!/bin/bash

echo "Logging in to Docker Hub..."
docker login -u sabirmgd -p "$1" || exit 1

# Run Postgres
docker run -d \
  --name docsgen_postgres \
  -e POSTGRES_USER=myuser \
  -e POSTGRES_PASSWORD=mypass \
  -e POSTGRES_DB=mydb \
  -p 5433:5432 \
  -v docsgen_db_data:/var/lib/postgresql/data \
  postgres:15

# Run Redis
docker run -d \
  --name docsgen_redis \
  -p 6380:6379 \
  redis:7-alpine

# Run Backend
docker run -d \
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
docker run -d \
  --name docsgen_frontend \
  --link docsgen_backend:backend \
  -e NEXT_PUBLIC_API_URL=http://localhost:3001 \
  -p 3000:3000 \
  sabirmgd/code-craft-frontend:latest
