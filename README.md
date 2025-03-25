# Mutual TLS (mTLS) Microservices Demo

This project demonstrates how to implement mutual TLS (mTLS) between microservices running on Kubernetes.

## Project Overview

The project consists of two TypeScript microservices:

- **API Service**: A secure backend that requires client certificates
- **Client Service**: A frontend that connects to the API service using mTLS

## Prerequisites

- Docker
- Kubernetes cluster (local like Minikube/Kind or remote)
- kubectl configured for your cluster
- Node.js and npm (for local development)
- OpenSSL (for certificate generation)

## Project Structure

```
mtls-demo/
├── certs/                  # Certificate generation scripts
│   ├── ca/                 # CA certificates
│   ├── api-service/        # API service certificates
│   ├── client-service/     # Client service certificates
│   └── generate-certs.sh   # Certificate generation script
├── k8s/                    # Kubernetes manifests
│   ├── api-deployment.yaml
│   ├── client-deployment.yaml
│   └── secrets.yaml
├── services/
│   ├── api-service/        # Backend API service
│   │   ├── src/
│   │   ├── Dockerfile
│   │   └── package.json
│   └── client-service/     # Frontend client service
│       ├── src/
│       ├── Dockerfile
│       └── package.json
└── README.md
```

## Getting Started

### Setup

1. Clone this repository:

   ```bash
   git clone https://github.com/yourusername/mtls-demo.git
   cd mtls-demo
   ```

2. Run the setup script:

   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```

   This script will:

   - Generate certificates for the CA, API service, and Client service
   - Build Docker images for the services
   - Create Kubernetes secrets containing the certificates
   - Deploy the services to your Kubernetes cluster

### Manual Setup

If you prefer to set up manually:

1. Generate certificates:

   ```bash
   chmod +x certs/generate-certs.sh
   ./certs/generate-certs.sh
   ```

2. Build Docker images:

   ```bash
   # API Service
   cd services/api-service
   docker build -t mtls-demo/api-service:latest .
   cd ../..

   # Client Service
   cd services/client-service
   docker build -t mtls-demo/client-service:latest .
   cd ../..
   ```

3. Create Kubernetes secrets and deploy services:
   ```bash
   # Follow instructions in k8s/secrets.yaml to replace placeholder values
   kubectl apply -f k8s/secrets.yaml
   kubectl apply -f k8s/api-deployment.yaml
   kubectl apply -f k8s/client-deployment.yaml
   ```

## Testing the mTLS Connection

Once deployed, you can access the client service through your browser:

1. If using Minikube, run:

   ```bash
   minikube service client-service
   ```

2. If using another Kubernetes setup, find the service IP:

   ```bash
   kubectl get service client-service
   ```

3. Navigate to the service URL in your browser and click "Fetch Secure Data" to see mTLS in action.

## Understanding the mTLS Implementation

### Certificate Authority (CA)

We create a self-signed CA certificate that acts as our root of trust. Both services trust certificates signed by this CA.

### Server Authentication (API Service)

The API Service presents its certificate to clients, allowing them to verify they're talking to the legitimate API.

### Client Authentication (Client Service)

The Client Service presents its certificate to the API Service, allowing the API to verify that only authorized clients can connect.

### Certificate Verification

- The API service verifies the client certificate in the `verifyCertificate` middleware
- The client service configures its HTTPS agent with the client certificate and CA certificate

## Troubleshooting

### Certificate Issues

If you encounter certificate issues, check:

- Certificate paths are correct in the container
- Certificates are properly mounted as Kubernetes secrets
- Certificates haven't expired

### Connection Issues

If services can't connect:

- Ensure the API service is reachable within the cluster at `api-service:3000`
- Check the API service logs for certificate validation errors
- Verify that the client is correctly presenting its certificate

## Testing the mTLS Demo Project

Let's go through the steps to test our mTLS project and see it in action. I'll provide a comprehensive guide to observe the mutual TLS authentication working between our services.

### 1. Verify the Deployments

First, check that both services are running properly:

```bash
# Check if pods are running
kubectl get pods

# Check services
kubectl get services

# Check deployments
kubectl get deployments
```

### 2. Access the Client Service

The client service has been configured as a LoadBalancer, so you can access it through its external IP:

```bash
# Get the external IP and port
kubectl get service client-service
```

Depending on your Kubernetes setup:

- **Minikube**: Run `minikube service client-service --url` to get the URL
- **Kind**: Use port-forwarding with `kubectl port-forward svc/client-service 8080:80`
- **Cloud provider**: Use the external IP directly

### 3. Interact with the Web Interface

Once you have the URL:

1. Open it in your browser
2. You should see the "mTLS Demo Client" page
3. Click the "Fetch Secure Data" button
4. The page should display the secure data fetched from the API service
5. The response will include details about the client certificate used for authentication

### 4. Observe the Logs

To see mTLS in action, check the logs from both services:

```bash
# Get the API service pod name
API_POD=$(kubectl get pods -l app=api-service -o jsonpath='{.items[0].metadata.name}')

# Get the client service pod name
CLIENT_POD=$(kubectl get pods -l app=client-service -o jsonpath='{.items[0].metadata.name}')

# View API service logs
kubectl logs $API_POD

# View client service logs
kubectl logs $CLIENT_POD
```

In the API service logs, you should see:

- Messages about client certificate authentication
- Information about which client connected (the CN of the certificate)

In the client service logs, you should see:

- Messages about making mTLS requests to the API
- Details about the TLS handshake

### 5. Test Certificate Validation

To verify that mTLS is working properly, you can try accessing the API service directly without a valid client certificate:

```bash
# Port forward the API service to access it locally
kubectl port-forward svc/api-service 3443:3000

# In another terminal, try to access it without a certificate
curl https://localhost:3443/api/health -k
```

This should fail with a certificate error, confirming that the API service requires client certificates.

### 6. Advanced Testing

To further test mTLS functionality, you can:

#### Create an unauthorized client

1. Generate a new certificate not signed by our CA
2. Try to use it to connect to the API service
3. Verify it's rejected

```bash
# Generate an unauthorized certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout unauthorized.key -out unauthorized.crt \
  -subj "/CN=unauthorized-client"

# Try to use it to connect
curl --cert unauthorized.crt --key unauthorized.key \
  https://localhost:3443/api/health -k
```

#### Inspect the TLS handshake

Use a tool like Wireshark or tcpdump to capture and analyze the TLS handshake between services:

```bash
# If tcpdump is available in your environment:
kubectl exec $API_POD -- tcpdump -i any -w /tmp/capture.pcap port 3000
kubectl cp $API_POD:/tmp/capture.pcap ./capture.pcap

# Then analyze with Wireshark
```

### 7. Visualize the mTLS Connection

To understand what's happening, remember the flow:

1. The browser connects to the client service (normal HTTPS)
2. When you click "Fetch Secure Data":
   - The client service makes an mTLS connection to the API service
   - It presents its client certificate
   - The API service verifies the client certificate
   - The API service returns data only after authentication
3. The client service returns this data to your browser

This demonstrates the end-to-end mTLS security where both parties authenticate each other before exchanging data.

By following these steps, you'll be able to see mutual TLS in action, protecting the communication between your microservices in Kubernetes.

## Next Steps

To extend this project:

1. Implement certificate rotation
2. Add a proper certificate management solution like cert-manager
3. Implement authorization based on certificate attributes
4. Add more microservices with their own certificates

## License

MIT
