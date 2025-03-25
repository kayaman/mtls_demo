import express from 'express'
import https from 'https'
import fs from 'fs'
import path from 'path'
import axios from 'axios'

// Create Express app
const app = express()
const PORT = process.env.PORT || 4000
const API_SERVICE_URL = process.env.API_SERVICE_URL || 'https://api-service:3000'

// Configure axios for mTLS
const axiosInstance = axios.create({
  httpsAgent: new https.Agent({
    cert: fs.readFileSync(path.join(process.env.CERT_PATH || '/certs', 'client-service.crt')),
    key: fs.readFileSync(path.join(process.env.CERT_PATH || '/certs', 'client-service.key')),
    ca: fs.readFileSync(path.join(process.env.CERT_PATH || '/certs', 'ca.crt')),
    rejectUnauthorized: true, // Verify server certificate
  }),
})

// Basic web server
app.get('/', (req, res) => {
  res.send(`
    <html>
      <head>
        <title>mTLS Demo Client</title>
        <style>
          body { font-family: Arial, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; }
          pre { background-color: #f5f5f5; padding: 10px; border-radius: 5px; }
          button { padding: 10px; margin: 10px 0; background-color: #4CAF50; color: white; border: none; cursor: pointer; }
        </style>
      </head>
      <body>
        <h1>mTLS Demo Client</h1>
        <p>This client connects to the API service using mutual TLS.</p>
        <button id="fetchBtn">Fetch Secure Data</button>
        <h2>Response:</h2>
        <pre id="response">Click the button to fetch data...</pre>
        
        <script>
          document.getElementById('fetchBtn').addEventListener('click', async () => {
            try {
              const response = await fetch('/proxy/data');
              const data = await response.json();
              document.getElementById('response').textContent = JSON.stringify(data, null, 2);
            } catch (error) {
              document.getElementById('response').textContent = 'Error: ' + error.message;
            }
          });
        </script>
      </body>
    </html>
  `)
})

// Proxy requests to API service with mTLS
app.get('/proxy/data', async (req, res) => {
  try {
    console.log(`Making mTLS request to: ${API_SERVICE_URL}/api/data`)
    const response = await axiosInstance.get(`${API_SERVICE_URL}/api/data`)
    res.json({
      apiResponse: response.data,
      clientInfo: {
        service: 'client-service',
        timestamp: new Date().toISOString(),
      },
    })
  } catch (error: any) {
    console.error('API request failed:', error.message)
    res.status(500).json({
      error: 'Failed to fetch data from API service',
      details: error.message,
    })
  }
})

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'healthy' })
})

// Start HTTP server (client service doesn't need its own HTTPS since it's internal)
app.listen(PORT, () => {
  console.log(`Client Service running on port ${PORT}`)
  console.log(`Configured to connect to API at: ${API_SERVICE_URL}`)
  console.log(
    `Using client certificate: ${path.join(
      process.env.CERT_PATH || '/certs',
      'client-service.crt',
    )}`,
  )
})
