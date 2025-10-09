// routes/mealPlanRoutes.js
const express = require("express");
const router = express.Router();
const {
  getMealPlanByUserId,
  logMeal, // Import the new controller function
} = require("../controllers/mealPlanController.js");

// GET: Fetch meal plan by userId
router.get("/:userId", getMealPlanByUserId);

// --- ✅ NEW ROUTE ---
// PATCH: Log a meal for a user
router.patch("/log-meal", logMeal);

module.exports = router;
