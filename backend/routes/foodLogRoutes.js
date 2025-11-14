const express = require('express');
const router = express.Router();
const { logFoodItem, getFoodLogForDate } = require('../controllers/foodLogController');
const { protect } = require('../middleware/authMiddleware'); // Import your auth middleware

// --- Food Log Routes ---

// @route   POST /api/foodlog
// @desc    Log a new food item
router.route('/')
    .post(protect, logFoodItem);

// @route   GET /api/foodlog/2025-11-10
// @desc    Get all food items for a specific date
router.route('/:date')
    .get(protect, getFoodLogForDate);
 
module.exports = router;