// routes/authRoutes.js
const express = require('express');
const router = express.Router();
const User = require('../models/User');
const jwt = require('jsonwebtoken');
const axios = require('axios');
require('dotenv').config();

// ✅ REGISTER route
router.post('/register', async (req, res) => {
  const { email, password } = req.body;

  try {
    // Check if user already exists
    let user = await User.findOne({ email });
    if (user) {
      return res.status(400).json({ message: 'User already exists.....' });
    }

    // Create new user
    user = new User({ email, password });
    await user.save();

    // 🔗 Connect this user to Spoonacular
    try {
      const spoonacularRes = await axios.post(
        `https://api.spoonacular.com/users/connect`,
        { username: email }, // You can also pass { email, firstName, lastName }
        { params: { apiKey: process.env.SPOONACULAR_API_KEY } }
      );

      // Save spoonacular credentials
      user.spoonacular = {
        username: spoonacularRes.data.username,
        hash: spoonacularRes.data.hash
      };
      await user.save();
    } catch (spoonErr) {
      console.error("❌ Spoonacular connect failed:", spoonErr.response?.data || spoonErr.message);
      // You can decide: either fail registration or just warn
      return res.status(500).json({ message: "User created but Spoonacular connect failed" });
    }

    // ✅ Create JWT token
    const token = jwt.sign({ userId: user._id }, process.env.JWT_SECRET, {
      expiresIn: '1h'
    });

    res.json({
  message: "User registered & connected to Spoonacular",
  token,
  email: user.email,         // added
  userId: user._id.toString() // added
});

  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
