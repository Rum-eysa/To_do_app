const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const swaggerUi = require('swagger-ui-express'); // Swagger UI paketi
const swaggerJsdoc = require('swagger-jsdoc'); // Swagger JSDoc paketi

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

// --- SWAGGER YAPILANDIRMASI BAŞLANGICI ---
const swaggerOptions = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'Todo App API',
      version: '1.0.0',
      description: 'JWT Authentication ve Hatırlatıcı Destekli Todo API Dökümantasyonu',
      contact: {
        name: 'Geliştirici Destek'
      },
    },
    servers: [
      {
        url: `http://localhost:${process.env.PORT || 5000}`,
        description: 'Yerel Sunucu',
      },
      {
        url: 'http://192.168.10.145:5000', // Senin ağ IP adresin
        description: 'Ağ Sunucusu (Telefon Erişimi)',
      },
    ],
    components: {
      securitySchemes: {
        bearerAuth: { // JWT için Authorize butonu ekler
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT',
        },
      },
    },
  },
  // ÖNEMLİ: Rotalarının olduğu klasör yolunu buraya yazıyoruz
  apis: ['./src/routes/*.js'], 
};

const swaggerSpec = swaggerJsdoc(swaggerOptions);
// Swagger arayüzü için endpoint
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));
// --- SWAGGER YAPILANDIRMASI BİTİŞİ ---

// Middleware
app.use(cors());
app.use(express.json());

// Routes
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

app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`📖 Swagger UI: http://localhost:${PORT}/api-docs`);
  console.log(`📡 Network URL: http://192.168.10.192:${PORT}`);
  console.log('💾 Database: SQLite (database.sqlite)');
  console.log('📝 Veriler kalıcı olarak kaydedilecek!');
});