// routes/mealPlanRoutes.js
const express = require("express");
const router = express.Router();
const {
  getMealPlanByUserId,
  getMealPlanByUserIdToday,
  logMeal, // Import the new controller function
} = require("../controllers/mealPlanController.js");

// GET: Fetch meal plan by userId
router.get("/:userId", getMealPlanByUserId);


router.get("/:userId/today", getMealPlanByUserIdToday);


// --- ✅ NEW ROUTE ---
// PATCH: Log a meal for a user
router.patch("/log-meal", logMeal);

module.exports = router;
