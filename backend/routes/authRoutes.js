const express = require('express');
const router = express.Router();
const User = require('../models/User'); // Your User model
// ... (other imports)
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const axios = require('axios');
const authMiddleware = require('../middleware/authMiddleware');
require('dotenv').config();

// ✅ REGISTER route - FINAL FIX
router.post('/register', async (req, res) => {
  const { email, password } = req.body;
  
  // 1. Validate email input
  if (!email || !password) {
      return res.status(400).json({ message: 'Email and password are required.' });
  }

  try {
    // 2. Check if user already exists (using .lean() for efficiency)
    let user = await User.findOne({ email }).select('email').lean();
    
    if (user) {
      console.log(`❌ Registration attempt for existing email: ${email}`);
      return res.status(400).json({ message: 'User already exists' }); // Returns error if user is found
    }

    // 3. Create new user
    user = new User({ email, password });
    await user.save();

    // 4. Spoonacular connect logic... 
    try {
      const spoonacularRes = await axios.post(
        `https://api.spoonacular.com/users/connect`,
        { username: user.id }, // Use user ID or email for spoonacular username
        { params: { apiKey: process.env.SPOONACULAR_API_KEY } }
      );
      user.spoonacular = {
        username: spoonacularRes.data.username,
        hash: spoonacularRes.data.hash
      };
      await user.save();
    } catch (spoonErr) {
      // Allow user creation even if external service fails
      console.error("Spoonacular connect failed:", spoonErr.response?.data || spoonErr.message);
    }

    // 5. Generate and return JWT
    const payload = {
      user: {
        id: user.id, 
      },
    };

    jwt.sign(
      payload,
      process.env.JWT_SECRET,
      { expiresIn: '5h' },
      (err, token) => {
        if (err) throw err;
        res.status(201).json({
          message: "User registered & connected to Spoonacular",
          token,
          email: user.email,
          userId: user.id, 
        });
      }
    );
  } catch (err) {
    console.error('Registration server error:', err.message);
    // 6. Handle MongoDB duplicate key error (in case unique: true is used)
    if (err.code && err.code === 11000) {
       return res.status(400).json({ message: 'User already exists (Duplicate key error)' });
    }
    res.status(500).json({ message: 'Server error during registration' });
  }
});


// --- LOGIN route ---
router.post('/login', async (req, res) => {
  const { email, password } = req.body;
  try {
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(400).json({ message: 'Invalid credentials' });
    }
    const isMatch = await bcrypt.compare(password, user.password); // Ensure bcrypt is used correctly
    if (!isMatch) {
      return res.status(400).json({ message: 'Invalid credentials' });
    }
    
    const payload = {
      user: {
        id: user.id,
      },
    };
    jwt.sign(
      payload,
      process.env.JWT_SECRET,
      { expiresIn: '5h' },
      (err, token) => {
        if (err) throw err;
        res.status(200).json({
          token,
          // CRITICAL: Matches client's login saving key
          user: user.id,
          email: user.email,
        });
      }
    );
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server error');
  }
});

// --- DELETE route ---
router.delete('/delete', authMiddleware.protect, async (req, res) => {
    try {
        // authMiddleware provides the correct, valid user ID
        const userId = req.user.id; 
        
        const user = await User.findById(userId);

        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }
        
        // Optional: Add logic here to delete the user from Spoonacular
        
        await user.deleteOne();
        res.status(200).json({ message: 'Account deleted successfully' });

    } catch (err) {
        console.error(`Error deleting account for user ${req.user?.id}: ${err.message}`);
        res.status(500).send('Server error during account deletion.');
    }
});

module.exports = router;