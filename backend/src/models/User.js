const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database'); // ← DÜZELTME BURADA

const User = sequelize.define('User', {
  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true,
  },
  uid: {
    type: DataTypes.STRING,
    allowNull: false,
    unique: true,
  },
  email: {
    type: DataTypes.STRING,
    allowNull: false,
    unique: true,
  },
  username: {
    type: DataTypes.STRING,
    allowNull: true,
  }
  // password kaldırıldı — artık Firebase Auth yönetiyor
});

module.exports = User;