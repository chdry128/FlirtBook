const express = require('express');
const cors = require('cors');
const fetch = require('node-fetch');
const bodyParser = require('body-parser');

const app = express();
const port = process.env.PORT || 3000;

// Enable CORS for all routes
app.use(cors());
app.use(bodyParser.json({ limit: '50mb' }));
app.use(bodyParser.urlencoded({ extended: true, limit: '50mb' }));

// Serve static files from the web directory
app.use(express.static('web'));

// Proxy endpoint for NVIDIA API
app.post('/api/nvidia', async (req, res) => {
  console.log(`Incoming request: ${req.method} ${req.url}`);

  const nvidiaApiKey = process.env.NVIDIA_API_KEY;

  if (!nvidiaApiKey) {
    console.error('NVIDIA API key not configured on server.');
    return res.status(500).json({ error: 'API configuration error on server.' });
  }

  try {
    // The client will no longer send the API key.
    // The body from the client is expected to be the payload for the NVIDIA API.
    const clientRequestBody = req.body; 

    if (!clientRequestBody) {
      console.log('Request body is missing.');
      return res.status(400).json({ error: 'Request body is missing.' });
    }
    
    console.log('Proxying request to NVIDIA API with body:', JSON.stringify(clientRequestBody).substring(0, 100) + '...'); // Log a snippet

    const response = await fetch('https://integrate.api.nvidia.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${nvidiaApiKey}`,
        'Accept': 'application/json',
      },
      body: JSON.stringify(clientRequestBody), // Forward the client's request body
    });

    const responseBody = await response.text(); // Read as text first to handle non-JSON errors
    
    if (!response.ok) {
      console.error(`NVIDIA API error: ${response.status} ${response.statusText}`, responseBody);
      // Try to parse as JSON if possible, otherwise send text
      let errorJson;
      try {
        errorJson = JSON.parse(responseBody);
      } catch (e) {
        errorJson = { error: responseBody || 'Error from NVIDIA API' };
      }
      return res.status(response.status).json(errorJson);
    }
    
    // If response is ok, assume it's JSON and send it back
    res.json(JSON.parse(responseBody));

  } catch (error) {
    console.error('Error proxying request to NVIDIA API:', error.message, error.stack);
    // Differentiate between network/fetch errors and other issues
    if (error.name === 'FetchError' || (error.cause && error.cause.code === 'ENOTFOUND')) { // node-fetch specific
        return res.status(502).json({ error: 'Bad Gateway: Error connecting to NVIDIA API.' });
    }
    res.status(500).json({ error: 'Internal server error while proxying request.' });
  }
});

app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});