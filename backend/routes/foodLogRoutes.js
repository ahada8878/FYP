// backend/routes/foodLogRoutes.js

const express = require('express');
const router = express.Router();
// 1. Import the new controller function
const { logFoodItem, getFoodLogForDate, generateWeeklyReport } = require('../controllers/foodLogController');
const { protect } = require('../middleware/authMiddleware'); 

// --- Food Log Routes ---

// @route   POST /api/foodlog
// @desc    Log a new food item
router.route('/')
    .post(protect, logFoodItem);

// @route   POST /api/foodlog/generate-report
// @desc    Generate AI Weekly Report
// Placed BEFORE /:date to prevent conflict with the parameter route
router.route('/generate-report')
    .post(protect, generateWeeklyReport);

// @route   GET /api/foodlog/2025-11-10
// @desc    Get all food items for a specific date
router.route('/:date')
    .get(protect, getFoodLogForDate);
 
module.exports = router;