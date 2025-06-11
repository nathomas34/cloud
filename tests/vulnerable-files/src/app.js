const express = require('express');
const app = express();

// Vulnérabilité: Secrets codés en dur
const API_KEY = 'sk-1234567890abcdef';
const DB_PASSWORD = 'admin123';
const JWT_SECRET = 'super-secret-key';

// Vulnérabilité: Pas de validation d'entrée
app.get('/user/:id', (req, res) => {
  const userId = req.params.id;
  // Vulnérabilité SQL Injection potentielle
  const query = `SELECT * FROM users WHERE id = ${userId}`;
  console.log('Executing query:', query);
  res.json({ message: 'User data', query });
});

// Vulnérabilité: XSS
app.get('/search', (req, res) => {
  const searchTerm = req.query.q;
  // Pas d'échappement HTML
  res.send(`<h1>Résultats pour: ${searchTerm}</h1>`);
});

// Vulnérabilité: Exposition d'informations sensibles
app.get('/debug', (req, res) => {
  res.json({
    environment: process.env,
    secrets: {
      apiKey: API_KEY,
      dbPassword: DB_PASSWORD,
      jwtSecret: JWT_SECRET
    }
  });
});

// Vulnérabilité: Pas de limitation de taux
app.post('/login', (req, res) => {
  // Pas de protection contre les attaques par force brute
  const { username, password } = req.body;
  if (password === 'admin') {
    res.json({ token: 'fake-jwt-token' });
  } else {
    res.status(401).json({ error: 'Invalid credentials' });
  }
});

// Vulnérabilité: Désérialisation non sécurisée
app.post('/data', express.json(), (req, res) => {
  try {
    // Vulnérabilité: eval() avec données utilisateur
    const result = eval(req.body.expression);
    res.json({ result });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`API Key: ${API_KEY}`); // Vulnérabilité: Log de secrets
});

module.exports = app;