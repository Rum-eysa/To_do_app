const { User } = require('../models');
const admin = require('firebase-admin');
const path = require('path');

// Firebase Admin SDK'yı başlat (sadece bir kez)
if (!admin.apps.length) {
  const serviceAccount = require(
    path.join(__dirname, '../config/todoapp-e58a5-firebase-adminsdk-fbsvc-354f83bd94.json')
  );
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

const protect = async (req, res, next) => {
  const token = req.headers.authorization?.split('Bearer ')[1];

  if (!token) {
    return res.status(401).json({ message: 'No token provided' });
  }

  try {
    const decodedToken = await admin.auth().verifyIdToken(token);
    req.user = { uid: decodedToken.uid, email: decodedToken.email };
    next();
  } catch (error) {
    console.error('Firebase token doğrulama hatası:', error);
    return res.status(401).json({ message: 'Unauthorized' });
  }
};

module.exports = { protect };