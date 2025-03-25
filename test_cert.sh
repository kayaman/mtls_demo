# Port forward the API service to access it locally
kubectl port-forward svc/api-service 3443:3000

# In another terminal, try to access it without a certificate
curl https://localhost:3443/api/health -k