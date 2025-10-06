const jwt = require('jsonwebtoken');
require('dotenv').config();

// This function acts as a gatekeeper for protected routes
module.exports = function(req, res, next) {
    // Get token from the 'x-auth-token' header sent by Flutter
    const token = req.header('x-auth-token');

    // If no token is provided, deny access
    if (!token) {
        return res.status(401).json({ message: 'No token, authorization denied' });
    }

    // If a token exists, verify it
    try {
        // Decode the token using your JWT_SECRET
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        // Attach the user's ID from the token to the request object
        req.user = decoded.user;
        // Proceed to the next step (the actual delete logic)
        next();
    } catch (err) {
        // If the token is invalid, deny access
        res.status(401).json({ message: 'Token is not valid' });
    }
};