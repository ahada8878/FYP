const jwt = require('jsonwebtoken');
require('dotenv').config();

// This function acts as a gatekeeper for protected routes
module.exports = function(req, res, next) {
    let token;
    
    // CRITICAL FIX: Get token from the standard 'Authorization: Bearer <token>' header
    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
        token = req.headers.authorization.split(' ')[1];
    }

    // If no token is provided, deny access
    if (!token) {
        return res.status(401).json({ success: false, message: 'Not authorized, token missing' });
    }

    // If a token exists, verify it
    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        
        // Attach the user's ID to req.user (assuming payload is { user: { id: '...' } })
        req.user = decoded.user;
        
        // Proceed to the next step
        next();
    } catch (err) {
        // If the token is invalid, deny access
        console.error("JWT Verification Error in authMiddleware:", err.message);
        res.status(401).json({ success: false, message: 'Not authorized, token failed' });
    }
};