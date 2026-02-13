const { Sequelize } = require('sequelize');

const sequelize = new Sequelize({
  dialect: 'sqlite',
  storage: process.env.DB_STORAGE || './database.sqlite',
  logging: false,
  define: {
    // İsimlendirme hatalarını önlemek için:
    underscored: false, 
    timestamps: true
  }
});

const connectDB = async () => {
  try {
    await sequelize.authenticate();
    console.log('✅ SQLite connected successfully');
    
    // sync içindeki '+' silindi, yerine 'alter' geldi.
    await sequelize.sync();
    console.log('✅ Database synchronized');
  } catch (error) {
    console.error('❌ SQLite connection error:', error);
    process.exit(1);
  }
};

module.exports = { sequelize, connectDB };