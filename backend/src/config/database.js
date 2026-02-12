const { Sequelize } = require('sequelize');

const sequelize = new Sequelize({
  dialect: 'sqlite',
  storage: process.env.DB_STORAGE || './database.sqlite',
  logging: false
});

const connectDB = async () => {
  try {
    await sequelize.authenticate();
    console.log('✅ SQLite connected successfully');
    console.log('📁 Database file:', process.env.DB_STORAGE || './database.sqlite');
    
    await sequelize.sync({ alter: true });
    console.log('✅ Database synchronized');
  } catch (error) {
    console.error('❌ SQLite connection error:', error);
    process.exit(1);
  }
};

module.exports = { sequelize, connectDB };
