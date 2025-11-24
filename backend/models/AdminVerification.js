const mongoose = require('mongoose');

const verificationSchema = new mongoose.Schema({
  email: { type: String, required: true },
  otp: { type: String, required: true },
  tempUserData: { type: Object, required: true }, // Store user data here until verified
  createdAt: { type: Date, default: Date.now, expires: 600 } // Expires in 10 mins
});

module.exports = mongoose.model('AdminVerification', verificationSchema);