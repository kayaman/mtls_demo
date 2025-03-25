# Generate certificates
./certs/generate-certs.sh

# Copy certificates to the expected locations
mkdir -p services/api-service/certs
mkdir -p services/client-service/certs
cp certs/ca/ca.crt services/api-service/certs/
cp certs/ca/ca.crt services/client-service/certs/
cp certs/api-service/* services/api-service/certs/
cp certs/client-service/* services/client-service/certs/

# Install dependencies
cd services/api-service
npm install
cd ../client-service
npm install

