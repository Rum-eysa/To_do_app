const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');

dotenv.config();

// Database connection
const { connectDB } = require('./config/database');
connectDB();

// Import models for associations
require('./models');

// Routes
const authRoutes = require('./routes/authRoutes');
const todoRoutes = require('./routes/todoRoutes');

const app = express();

// CORS ayarlarını en geniş haliyle bıraktık ki telefonun rahat bağlansın
app.use(cors());
app.use(express.json());

app.use('/api/auth', authRoutes);
app.use('/api/todos', todoRoutes);

app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    message: 'Server is running',
    database: 'SQLite',
    storage: process.env.DB_STORAGE 
  });
});

const PORT = process.env.PORT || 5000;

// KRİTİK DEĞİŞİKLİK: '0.0.0.0' ekleyerek telefonunun bağlanmasını sağladık
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`📡 Network URL: http://192.168.10.192:${PORT}`);
  console.log('💾 Database: SQLite (database.sqlite)');
  console.log('📝 Veriler kalıcı olarak kaydedilecek!');
});