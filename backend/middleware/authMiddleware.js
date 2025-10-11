const jwt = require('jsonwebtoken');
require('dotenv').config();

module.exports = function(req, res, next) {
    console.log('--- Auth Middleware triggered ---');
    console.log('Headers:', JSON.stringify(req.headers, null, 2));

    let token;
    
    // ✅ CHANGED: Logic to check for both 'Authorization' and 'x-auth-token' headers.
    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
        // This is the standard way.
        token = req.headers.authorization.split(' ')[1];
        console.log('✅ Token found in "Authorization" header.');
    } else if (req.headers['x-auth-token']) {
        // This is the fallback for your current Flutter setup.
        token = req.headers['x-auth-token'];
        console.log('✅ Token found in "x-auth-token" header.');
    }

    if (!token) {
        console.error('❌ FAILURE: Token missing from headers. Sending 401.');
        return res.status(401).json({ success: false, message: 'Not authorized, token missing' });
    }

    try {
        console.log('⚙️ Verifying token...');
        if (!process.env.JWT_SECRET) {
            throw new Error('JWT_SECRET is not defined in .env file.');
        }
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        console.log('✅ SUCCESS: Token verified. Decoded Payload:', JSON.stringify(decoded, null, 2));
        
        req.user = decoded.user;
        
        console.log('🚀 Proceeding to controller...');
        next();

    } catch (err) {
        console.error('❌ FAILURE: JWT Verification Error in authMiddleware:', err.message);
        res.status(401).json({ success: false, message: 'Not authorized, token failed' });
    }
};