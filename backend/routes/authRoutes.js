const express = require('express');
const router = express.Router();
const User = require('../models/User');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const axios = require('axios');
const authMiddleware = require('../middleware/authMiddleware');
require('dotenv').config();

// ✅ REGISTER route - The JWT payload is now fixed
router.post('/register', async (req, res) => {
  const { email, password } = req.body;
  try {
    let user = await User.findOne({ email });
    if (user) {
      return res.status(400).json({ message: 'User already exists' });
    }
    user = new User({ email, password });
    await user.save();

    // Spoonacular connect logic... (remains the same)
    try {
      const spoonacularRes = await axios.post(
        `https://api.spoonacular.com/users/connect`,
        { username: email },
        { params: { apiKey: process.env.SPOONACULAR_API_KEY } }
      );
      user.spoonacular = {
        username: spoonacularRes.data.username,
        hash: spoonacularRes.data.hash
      };
      await user.save();
    } catch (spoonErr) {
      console.error("Spoonacular connect failed:", spoonErr.response?.data || spoonErr.message);
      return res.status(500).json({ message: "User created but Spoonacular connect failed" });
    }

    // ✅ CORRECTED JWT PAYLOAD STRUCTURE
    const payload = {
      user: {
        id: user.id, // This matches the login and middleware
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
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

// ✅ LOGIN route - This was already correct, but shown for consistency
router.post('/login', async (req, res) => {
  const { email, password } = req.body;
  try {
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(400).json({ message: 'Invalid credentials' });
    }
    const isMatch = await bcrypt.compare(password, user.password);
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
          user: user._id,
          email: user.email,
        });
      }
    );
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server error');
  }
});

// ✅ DELETE route - This is correct and will now work
router.delete('/delete', authMiddleware, async (req, res) => {
  try {
    const userId = req.user.id; // This will now correctly find req.user.id
    const user = await User.findByIdAndDelete(userId);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    res.status(200).json({ message: 'Account deleted successfully' });
  } catch (err) {
    console.error('Error deleting account:', err.message);
    res.status(500).send('Server error');
  }
});

module.exports = router;