// controllers/mealPlanController.js
const MealPlan = require("../models/mealPlan.js");

// ✅ Fetch meal plan for a specific user
const getMealPlanByUserId = async (req, res) => {
  try {
    const { userId } = req.params;

    if (!userId) {
      return res.status(400).json({ message: "User ID is required" });
    }

    // Find the latest meal plan for this user
    const mealPlan = await MealPlan.findOne({ userId }).sort({ weekStart: -1 });

    if (!mealPlan) {
      return res
        .status(404)
        .json({ message: "No meal plan found for this user" });
    }

    res.status(200).json(mealPlan);
  } catch (error) {
    console.error("❌ Error fetching meal plan:", error);
    res.status(500).json({ message: "Server error fetching meal plan" });
  }
};

// Log a specific meal within a user's meal plan
const logMeal = async (req, res) => {
  try {
    const { userId, mealId } = req.body;

    if (!userId || !mealId) {
      return res
        .status(400)
        .json({ message: "User ID and Meal ID are required" });
    }

    // Find the latest meal plan for the user
    const mealPlan = await MealPlan.findOne({ userId }).sort({ weekStart: -1 });

    if (!mealPlan) {
      return res
        .status(404)
        .json({ message: "Meal plan not found for this user" });
    }

    // Find the specific recipe in the detailedRecipes array
    const recipeToLog = mealPlan.detailedRecipes.find(
      (recipe) => recipe.id === mealId
    );

    if (!recipeToLog) {
      return res.status(404).json({ message: "Meal not found in this plan" });
    }

    // Update the loggedAt timestamp to the current time
    recipeToLog.loggedAt = new Date();

    // Explicitly tell Mongoose that the nested 'detailedRecipes' array has changed.
    mealPlan.markModified("detailedRecipes");

    // Save the entire meal plan document with the updated recipe
    await mealPlan.save();

    // Return the updated meal plan
    res.status(200).json({
      message: "Meal logged successfully",
      mealPlan,
    });
  } catch (error) {
    // It's helpful to log the actual error for better debugging
    console.error("❌ Detailed error logging meal:", error);
    res.status(500).json({ message: "Server error logging meal" });
  }
};

module.exports = {
  getMealPlanByUserId,
  logMeal,
};

