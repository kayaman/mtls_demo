import express from 'express'
import https from 'https'
import fs from 'fs'
import path from 'path'

// Create Express app
const app = express()
const PORT = process.env.PORT || 3000

// Middleware to verify client certificate is from our CA
const verifyCertificate = (
  req: express.Request,
  res: express.Response,
  next: express.NextFunction,
) => {
  const cert = (req.socket as import('tls').TLSSocket).getPeerCertificate()

  if (!cert || Object.keys(cert).length === 0) {
    console.error('No client certificate provided')
    return res.status(403).json({ error: 'Client certificate required' })
  }

  if (!(req.socket as import('tls').TLSSocket).authorized) {
    console.error('Client certificate not authorized')
    return res.status(403).json({ error: 'Invalid client certificate' })
  }

  console.log(`Client authenticated: ${cert.subject?.CN}`)
  next()
}

// Apply certificate verification middleware
app.use(verifyCertificate)

// JSON middleware
app.use(express.json())

// Basic API routes
app.get('/api/health', (req, res) => {
  res.json({ status: 'healthy' })
})

app.get('/api/data', (req, res) => {
  res.json({
    message: 'This data is secured with mTLS!',
    timestamp: new Date().toISOString(),
    clientCert: (req.socket as import('tls').TLSSocket).getPeerCertificate().subject,
  })
})

// HTTPS server options with mTLS configuration
const httpsOptions = {
  key: fs.readFileSync(path.join(process.env.CERT_PATH || '/certs', 'api-service.key')),
  cert: fs.readFileSync(path.join(process.env.CERT_PATH || '/certs', 'api-service.crt')),
  ca: fs.readFileSync(path.join(process.env.CERT_PATH || '/certs', 'ca.crt')),
  requestCert: true, // Request client certificate
  rejectUnauthorized: true, // Reject requests without valid client certificate
}

// Create HTTPS server
const server = https.createServer(httpsOptions, app)

// Start server
server.listen(PORT, () => {
  console.log(`API Service running securely on port ${PORT}`)
  console.log(`TLS certificate loaded for: ${httpsOptions.cert}`)
  console.log(`Using CA certificate: ${httpsOptions.ca}`)
})
