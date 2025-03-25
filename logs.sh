#!/bin/bash


# Get the API service pod name
API_POD=$(kubectl get pods -l app=api-service -o jsonpath='{.items[0].metadata.name}')

# Get the client service pod name
CLIENT_POD=$(kubectl get pods -l app=client-service -o jsonpath='{.items[0].metadata.name}')

# View API service logs
kubectl logs $API_POD

# View client service logs
kubectl logs $CLIENT_POD