#! /bin/bash

# Generate an unauthorized certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout unauthorized.key -out unauthorized.crt \
  -subj "/CN=unauthorized-client"

# Try to use it to connect
curl --cert unauthorized.crt --key unauthorized.key \
  https://localhost:3443/api/health -k