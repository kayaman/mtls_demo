FROM node:18-alpine

WORKDIR /app

# Copy package files and install dependencies
COPY package*.json ./
RUN npm install

# Copy source code
COPY tsconfig.json ./
COPY src ./src
COPY certs ./certs

# Build TypeScript
RUN npm run build

# Create directory for certificates
# RUN mkdir -p /app/certs

# Set environment variables
ENV NODE_ENV=production
ENV PORT=3000
ENV CERT_PATH=/certs

# Expose API port
EXPOSE 3000

CMD ["node", "dist/index.js"]