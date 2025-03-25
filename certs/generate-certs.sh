#!/bin/bash
set -e

# Create directories for certificates
mkdir -p certs/{ca,api-service,client-service}

# Generate CA key and certificate
echo "Generating CA certificates..."
openssl genrsa -out certs/ca/ca.key 4096
openssl req -new -x509 -key certs/ca/ca.key -sha256 -subj "/CN=mtls-demo-ca" \
  -out certs/ca/ca.crt -days 365

# Function to generate service certificates
generate_service_cert() {
  SERVICE_NAME=$1
  SERVICE_DNS=$2
  
  echo "Generating certificates for $SERVICE_NAME..."
  
  # Generate service key
  openssl genrsa -out certs/$SERVICE_NAME/$SERVICE_NAME.key 2048
  
  # Generate service CSR (Certificate Signing Request)
  openssl req -new -key certs/$SERVICE_NAME/$SERVICE_NAME.key \
    -out certs/$SERVICE_NAME/$SERVICE_NAME.csr \
    -subj "/CN=$SERVICE_DNS"
  
  # Create config for SAN (Subject Alternative Name)
  cat > certs/$SERVICE_NAME/openssl.cnf <<EOF
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name

[req_distinguished_name]

[v3_req]
subjectAltName = @alt_names

[alt_names]
DNS.1 = $SERVICE_DNS
DNS.2 = $SERVICE_NAME
DNS.3 = $SERVICE_NAME.default
DNS.4 = $SERVICE_NAME.default.svc.cluster.local
EOF
  
  # Sign the CSR with our CA
  openssl x509 -req -in certs/$SERVICE_NAME/$SERVICE_NAME.csr \
    -CA certs/ca/ca.crt \
    -CAkey certs/ca/ca.key \
    -CAcreateserial \
    -out certs/$SERVICE_NAME/$SERVICE_NAME.crt \
    -days 365 \
    -sha256 \
    -extfile certs/$SERVICE_NAME/openssl.cnf \
    -extensions v3_req
  
  # Verify the certificate
  openssl verify -CAfile certs/ca/ca.crt certs/$SERVICE_NAME/$SERVICE_NAME.crt
  
  # Create PEM files (combined cert and key) for services that need it
  cat certs/$SERVICE_NAME/$SERVICE_NAME.crt certs/$SERVICE_NAME/$SERVICE_NAME.key > certs/$SERVICE_NAME/$SERVICE_NAME.pem
  
  echo "Certificates for $SERVICE_NAME generated successfully"
}

# Generate certificates for services
generate_service_cert "api-service" "api-service.default.svc.cluster.local"
generate_service_cert "client-service" "client-service.default.svc.cluster.local"

echo "All certificates generated successfully"