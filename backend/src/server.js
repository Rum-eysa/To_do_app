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

app.listen(PORT, () => {
  console.log('🚀 Server running on port' );
  console.log('💾 Database: SQLite ()');
  console.log('📝 Veriler kalıcı olarak kaydedilecek!^');
});
