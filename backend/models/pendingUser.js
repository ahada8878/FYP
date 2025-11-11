const mongoose = require('mongoose');

const PendingUserSchema = new mongoose.Schema({
    email: { type: String, required: true, unique: true },
    password: { type: String, required: true }, // HASHED password
    otp: { type: String, required: true },
    otpExpires: { type: Date, required: true },
    // Auto-delete document after 5 minutes
    createdAt: { type: Date, default: Date.now, expires: '5m' } 
});

module.exports = mongoose.model('PendingUser', PendingUserSchema);