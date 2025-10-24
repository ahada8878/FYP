// controllers/mealPlanController.js
const MealPlan = require("../models/MealPlan.js");

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
// ✅ Log a specific meal within a user's meal plan
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

    let mealFound = false;

    // ✅ Iterate through Map safely using .entries()
    for (const [dayKey, day] of mealPlan.meals.entries()) {
      if (!day || !day.meals) continue;

      for (const meal of day.meals) {
        // ✅ Compare numerically to avoid string/number mismatch
        if (Number(meal.id) === Number(mealId)) {
          meal.loggedAt = new Date(); // log meal
          mealFound = true;
          console.log(`✅ Meal logged for ${dayKey} at ${meal.loggedAt}`);
          break;
        }
      }

      if (mealFound) break;
    }

    if (!mealFound) {
      return res
        .status(404)
        .json({ message: "Meal not found in any day" });
    }

    // ✅ Important: tell Mongoose nested path changed
    mealPlan.markModified("meals");
    await mealPlan.save();

    res.status(200).json({
      message: "Meal logged successfully",
      mealPlan,
    });
  } catch (error) {
    console.error("❌ Detailed error logging meal:", error);
    res.status(500).json({ message: "Server error logging meal" });
  }
};


module.exports = {
  getMealPlanByUserId,
  logMeal,
};

