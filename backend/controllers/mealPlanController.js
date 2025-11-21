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




const getMealPlanByUserIdToday = async (req, res) => {
  try {
    // 1. Get userId from request parameters
    const { userId } = req.params;

    if (!userId) {
      return res.status(400).json({ message: "User ID is required" });
    }

    // 2. Find the latest meal plan
    // CRITICAL FIX: We must select 'detailedRecipes' to get the ingredients/nutrition
    const mealPlan = await MealPlan.findOne({ userId })
      .select('meals detailedRecipes') 
      .sort({ weekStart: -1 })
      .lean(); 

    if (!mealPlan || !mealPlan.meals) { 
      return res
        .status(404)
        .json({ message: "No complete meal plan found for this user" });
    }

    // 3. Prepare today's normalized date for comparison
    const today = new Date();
    const todayNormalizedString = today.toISOString().substring(0, 10); 

    let todayMealsEntry = null;

    // 4. Iterate through day1 to day7 to find a date match
    for (let i = 1; i <= 7; i++) {
      const dayKey = `day${i}`; 
      const dayEntry = mealPlan.meals[dayKey]; 
      
      if (dayEntry && dayEntry.date) {
        const planDate = new Date(dayEntry.date);
        const planDateNormalizedString = planDate.toISOString().substring(0, 10);
        
        if (planDateNormalizedString === todayNormalizedString) {
          todayMealsEntry = dayEntry;
          break;
        }
      }
    }
    
    // 5. Check if meals were found
    if (!todayMealsEntry) {
      return res.status(404).json({ 
        message: "Meal plan found, but no entry matched today's date." 
      });
    }

    // 6. ✅ ENRICHMENT STEP: Merge schedule info with detailed recipe info
    // Create a lookup map for O(1) access
    const detailsMap = {};
    if (mealPlan.detailedRecipes && Array.isArray(mealPlan.detailedRecipes)) {
      mealPlan.detailedRecipes.forEach(recipe => {
        if (recipe && recipe.id) {
          detailsMap[recipe.id] = recipe;
        }
      });
    }

    // Merge the details into the meal objects
    if (todayMealsEntry.meals && Array.isArray(todayMealsEntry.meals)) {
      todayMealsEntry.meals = todayMealsEntry.meals.map(simpleMeal => {
        const detailedInfo = detailsMap[simpleMeal.id];
        if (detailedInfo) {
          // Return a new object merging both (details take precedence for overlapping keys)
          return { ...simpleMeal, ...detailedInfo };
        }
        return simpleMeal;
      });
    }

    // 7. Return the enriched day entry
    res.status(200).json(todayMealsEntry);

  } catch (error) {
    console.error("❌ Error fetching today's meals:", error);
    res.status(500).json({ message: "Server error fetching today's meals" });
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
  getMealPlanByUserIdToday,
  logMeal,
};

