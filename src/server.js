const express = require('express');
const path = require('path');
const fs = require('fs');
const { v4: uuidv4 } = require('uuid');

const app = express();
const PORT = process.env.PORT || 3000;
const DOMAIN = process.env.DOMAIN || 'deliverabilityanalyzer.xyz';
const DATA_DIR = process.env.DATA_DIR || '/var/lib/mail-tester/emails';

// Ensure data directory exists
if (!fs.existsSync(DATA_DIR)) {
  fs.mkdirSync(DATA_DIR, { recursive: true });
}

app.use(express.json());
app.use(express.static(path.join(__dirname, '../public')));

// Generate a new test email address
app.get('/api/generate', (req, res) => {
  const id = uuidv4().replace(/-/g, '').substring(0, 12);
  const email = `test-${id}@${DOMAIN}`;
  const data = {
    id,
    email,
    status: 'waiting',
    createdAt: new Date().toISOString(),
    received: false
  };
  fs.writeFileSync(path.join(DATA_DIR, `${id}.json`), JSON.stringify(data, null, 2));
  res.json({ email, id });
});

// Check results for a test ID
app.get('/api/check/:id', (req, res) => {
  const id = req.params.id;
  if (!/^[a-f0-9]{12}$/i.test(id)) {
    return res.status(400).json({ error: 'Invalid test ID' });
  }
  const filePath = path.join(DATA_DIR, `${id}.json`);
  if (!fs.existsSync(filePath)) {
    return res.status(404).json({ error: 'Test not found' });
  }
  const data = JSON.parse(fs.readFileSync(filePath, 'utf8'));
  res.json(data);
});

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Serve frontend for all other routes
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, '../public/index.html'));
});

app.listen(PORT, () => {
  console.log(`Mail Tester running on port ${PORT}`);
});
