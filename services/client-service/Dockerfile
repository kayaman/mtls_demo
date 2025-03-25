FROM node:18-alpine

WORKDIR /app

# Copy package files and install dependencies
COPY package*.json ./
RUN npm install

# Copy source code
COPY tsconfig.json ./
COPY src ./src

# Build TypeScript
RUN npm run build

# Create directory for certificates
RUN mkdir -p /certs

# Set environment variables
ENV NODE_ENV=production
ENV PORT=4000
ENV CERT_PATH=/certs
ENV API_SERVICE_URL=https://api-service:3000

# Expose client service port
EXPOSE 4000

CMD ["node", "dist/index.js"]