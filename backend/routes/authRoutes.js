const express = require('express');
const router = express.Router();
const User = require('../models/User');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs'); // Import bcryptjs for password comparison
const axios = require('axios');
require('dotenv').config();

// ✅ REGISTER route (Unchanged)
router.post('/register', async (req, res) => {
  const { email, password } = req.body;

  try {
    let user = await User.findOne({ email });
    if (user) {
      return res.status(400).json({ message: 'User already exists.....' });
    }

    user = new User({ email, password });
    await user.save(); // Password will be hashed by the pre-save hook in your User model

    // Connect to Spoonacular
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
      console.error("❌ Spoonacular connect failed:", spoonErr.response?.data || spoonErr.message);
      return res.status(500).json({ message: "User created but Spoonacular connect failed" });
    }

    const token = jwt.sign({ userId: user._id }, process.env.JWT_SECRET, {
      expiresIn: '1h'
    });

    res.json({
      message: "User registered & connected to Spoonacular",
      token,
      email: user.email,
      userId: user._id.toString()
    });

  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

// ✅ LOGIN route (This was missing)
router.post('/login', async (req, res) => {
  const { email, password } = req.body;

  try {
    // Check if user exists
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(400).json({ message: 'Invalid credentials' });
    }

    // Compare provided password with the stored hashed password
    // Assumes your User model has a method for this or you're using a pre-save hook for hashing.
    // If not, you might need user.comparePassword(password) like in your userRoutes.js
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(400).json({ message: 'Invalid credentials' });
    }

    // If credentials are correct, create and return JWT token
    const payload = {
      user: {
        id: user.id
      }
    };

    jwt.sign(
      payload,
      process.env.JWT_SECRET,
      { expiresIn: '5h' },
      (err, token) => {
        if (err) throw err;
        // This is the JSON response your Flutter app expects
        res.status(200).json({
          token,
          user: user._id,
          email: user.email
        });
      }
    );
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server error');
  }
});


module.exports = router;