#!/bin/bash
set -e

# Make script executable with: chmod +x setup.sh

echo "=== mTLS Demo Project Setup ==="

# Step 1: Generate certificates
echo "Generating certificates..."
./certs/generate-certs.sh

# Step 2: Build Docker images
echo "Building Docker images..."

# Build API service
echo "Building API service..."
cd services/api-service
docker build -t mtls-demo/api-service:latest .
cd ../..

# Build Client service
echo "Building Client service..."
cd services/client-service
docker build -t mtls-demo/client-service:latest .
cd ../..

# Step 3: Create Kubernetes secrets with certificates
echo "Creating Kubernetes secrets..."

# Base64 encode certificates for Kubernetes secrets
CA_CERT=$(cat certs/ca/ca.crt | base64 | tr -d '\n')
API_SERVICE_CERT=$(cat certs/api-service/api-service.crt | base64 | tr -d '\n')
API_SERVICE_KEY=$(cat certs/api-service/api-service.key | base64 | tr -d '\n')
CLIENT_SERVICE_CERT=$(cat certs/client-service/client-service.crt | base64 | tr -d '\n')
CLIENT_SERVICE_KEY=$(cat certs/client-service/client-service.key | base64 | tr -d '\n')

# Create temp file with actual secrets
cat k8s/secrets.yaml | \
  sed "s/\${CA_CERT}/$CA_CERT/g" | \
  sed "s/\${API_SERVICE_CERT}/$API_SERVICE_CERT/g" | \
  sed "s/\${API_SERVICE_KEY}/$API_SERVICE_KEY/g" | \
  sed "s/\${CLIENT_SERVICE_CERT}/$CLIENT_SERVICE_CERT/g" | \
  sed "s/\${CLIENT_SERVICE_KEY}/$CLIENT_SERVICE_KEY/g" \
  > k8s/secrets_filled.yaml

# Apply secrets to Kubernetes
kubectl apply -f k8s/secrets_filled.yaml
rm k8s/secrets_filled.yaml  # Remove file with sensitive data

# Step 4: Deploy services to Kubernetes
echo "Deploying services to Kubernetes..."
kubectl apply -f k8s/api-deployment.yaml || echo "Error deploying API service"

echo "Deploying client service..."
if [ -f k8s/client-deployment.yaml ]; then
  kubectl apply -f k8s/client-deployment.yaml || echo "Error deploying client service"
else
  echo "Error: k8s/client-deployment.yaml not found"
fi

echo "Waiting for services to be ready..."
kubectl wait --for=condition=ready pod -l app=api-service --timeout=300s
kubectl wait --for=condition=ready pod -l app=client-service --timeout=300s

# Step 5: Get access URL
echo "Getting service URL..."
if [ "$(uname)" == "Darwin" ]; then
  # MacOS
  open http://localhost:80
else
  # Linux
  echo "Access the client service at http://localhost:80"
fi

echo "=== Setup complete! ==="
echo "You can now access the client service in your browser."