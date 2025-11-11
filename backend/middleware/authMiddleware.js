const jwt = require('jsonwebtoken');
const fs = require('fs'); // ✅ 1. ADDED fs for file cleanup
require('dotenv').config();

// ✅ 2. CHANGED 'module.exports = function...' to 'const protect = function...'
const protect = function(req, res, next) {
    console.log('--- Auth Middleware triggered ---');
    console.log('Headers:', JSON.stringify(req.headers, null, 2));

    let token;
    
    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
        token = req.headers.authorization.split(' ')[1];
        console.log('✅ Token found in "Authorization" header.');
        console.log(token);
    } else if (req.headers['x-auth-token']) {
        token = req.headers['x-auth-token'];
        console.log('✅ Token found in "x-auth-token" header.');
    }

    if (!token) {
        console.error('❌ FAILURE: Token missing from headers. Sending 401.');
        
        // Add file cleanup logic (from your original server.js)
        if (req.file) {
            fs.unlink(req.file.path, (err) => {
                if (err) console.error('Error deleting file:', err);
            });
        }
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
        
        // ✅ 3. ADDED THIS LINE - This is critical for your other routes
        req.userId = decoded.user.id; 
        
        console.log('🚀 Proceeding to controller...');
        next();

    } catch (err) {
        console.error('❌ FAILURE: JWT Verification Error in authMiddleware:', err.message);
        
        // Add file cleanup logic (from your original server.js)
        if (req.file) {
            fs.unlink(req.file.path, (err) => {
                if (err) console.error('Error deleting file:', err);
            });
        }
        res.status(401).json({ success: false, message: 'Not authorized, token failed' });
    }
};

// ✅ 4. EXPORT 'protect' AS AN OBJECT - This fixes the TypeError
module.exports = { protect };