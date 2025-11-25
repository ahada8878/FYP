// controllers/mealPlanController.js
const MealPlan = require("../models/MealPlan.js");

// Fetch meal plan for a specific user
const getMealPlanByUserId = async (req, res) => {
  try {
    const { userId } = req.params;
    if (!userId) return res.status(400).json({ message: "User ID is required" });

    const mealPlan = await MealPlan.findOne({ userId }).sort({ weekStart: -1 });
    if (!mealPlan) return res.status(404).json({ message: "No meal plan found" });

    res.status(200).json(mealPlan);
  } catch (error) {
    console.error("❌ Error fetching meal plan:", error);
    res.status(500).json({ message: "Server error fetching meal plan" });
  }
};

const getMealPlanByUserIdToday = async (req, res) => {
  try {
    const { userId } = req.params;
    if (!userId) return res.status(400).json({ message: "User ID is required" });

    const mealPlan = await MealPlan.findOne({ userId })
      .select('meals detailedRecipes')
      .sort({ weekStart: -1 })
      .lean();

    if (!mealPlan || !mealPlan.meals) {
      return res.status(404).json({ message: "No complete meal plan found" });
    }

    const today = new Date();
    const todayNormalizedString = today.toISOString().substring(0, 10);
    let todayMealsEntry = null;

    for (let i = 1; i <= 7; i++) {
      const dayKey = `day${i}`;
      const dayEntry = mealPlan.meals[dayKey];
      if (dayEntry && dayEntry.date) {
        const planDate = new Date(dayEntry.date);
        if (planDate.toISOString().substring(0, 10) === todayNormalizedString) {
          todayMealsEntry = dayEntry;
          break;
        }
      }
    }

    if (!todayMealsEntry) {
      return res.status(404).json({ message: "No entry matched today's date." });
    }

    const detailsMap = {};
    if (mealPlan.detailedRecipes) {
      mealPlan.detailedRecipes.forEach(recipe => {
        if (recipe && recipe.id) detailsMap[recipe.id] = recipe;
      });
    }

    if (todayMealsEntry.meals) {
      todayMealsEntry.meals = todayMealsEntry.meals.map(simpleMeal => {
        const detailedInfo = detailsMap[simpleMeal.id];
        return detailedInfo ? { ...simpleMeal, ...detailedInfo } : simpleMeal;
      });
    }

    res.status(200).json(todayMealsEntry);
  } catch (error) {
    console.error("❌ Error fetching today's meals:", error);
    res.status(500).json({ message: "Server error fetching today's meals" });
  }
};

const logMeal = async (req, res) => {
  try {
    const { userId, mealId } = req.body;
    if (!userId || !mealId) return res.status(400).json({ message: "User ID and Meal ID are required" });

    const mealPlan = await MealPlan.findOne({ userId }).sort({ weekStart: -1 });
    if (!mealPlan) return res.status(404).json({ message: "Meal plan not found" });

    let mealFound = false;
    for (const [dayKey, day] of mealPlan.meals.entries()) {
      if (!day || !day.meals) continue;
      for (const meal of day.meals) {
        if (Number(meal.id) === Number(mealId)) {
          meal.loggedAt = new Date();
          mealFound = true;
          break;
        }
      }
      if (mealFound) break;
    }

    if (!mealFound) return res.status(404).json({ message: "Meal not found in any day" });

    mealPlan.markModified("meals");
    await mealPlan.save();

    res.status(200).json({ message: "Meal logged successfully", mealPlan });
  } catch (error) {
    console.error("❌ Error logging meal:", error);
    res.status(500).json({ message: "Server error logging meal" });
  }
};

// ✅ NEW: Local Shopping List Generation (No AI)
const generateShoppingList = async (req, res) => {
  try {
    const { userId } = req.body;
    if (!userId) return res.status(400).json({ message: "User ID is required" });

    const mealPlan = await MealPlan.findOne({ userId }).sort({ weekStart: -1 });
    if (!mealPlan) return res.status(404).json({ message: "Meal plan not found" });

    // 1. Aggregate Ingredients
    // Map key: "name_unit" to handle distinct units separately (e.g., 'flour_cup' vs 'flour_grams')
    const aggregatedIngredients = {};

    if (mealPlan.detailedRecipes && mealPlan.detailedRecipes.length > 0) {
      mealPlan.detailedRecipes.forEach((recipe) => {
        if (recipe.ingredients) {
          recipe.ingredients.forEach((ing) => {
            const name = ing.name.toLowerCase().trim();
            const unit = (ing.unit || "").toLowerCase().trim();
            const key = `${name}_${unit}`;

            if (aggregatedIngredients[key]) {
              aggregatedIngredients[key].amount += ing.amount;
            } else {
              aggregatedIngredients[key] = {
                name: ing.name, // Keep original display name
                amount: ing.amount,
                unit: ing.unit,
                cleanName: name
              };
            }
          });
        }
      });
    }

    // 2. Categorize Ingredients using keywords
    const categorizedList = {
      "Produce": [],
      "Meat & Seafood": [],
      "Dairy & Eggs": [],
      "Pantry & Spices": [],
      "Grains & Bread": [],
      "Other": []
    };

    const getCategory = (name) => {
      if (/chicken|beef|pork|steak|fish|salmon|shrimp|tuna|meat|bacon|sausage|ham/i.test(name)) return "Meat & Seafood";
      if (/milk|cheese|yogurt|cream|butter|egg|cheddar|mozzarella/i.test(name)) return "Dairy & Eggs";
      if (/apple|banana|orange|berry|spinach|lettuce|carrot|onion|garlic|pepper|tomato|potato|vegetable|fruit|avocado|lemon|lime|herb|cilantro|parsley/i.test(name)) return "Produce";
      if (/rice|pasta|bread|flour|oat|quinoa|noodle|tortilla|bun|bagel/i.test(name)) return "Grains & Bread";
      if (/oil|salt|pepper|sugar|spice|sauce|vinegar|honey|syrup|stock|broth|can|jar|nut|seed/i.test(name)) return "Pantry & Spices";
      return "Other";
    };

    Object.values(aggregatedIngredients).forEach(item => {
      const category = getCategory(item.cleanName);
      
      // Format nicely: "200 g Chicken Breast"
      // Use Math.round or toFixed to avoid long decimals like 199.99999
      const formattedAmount = Number.isInteger(item.amount) 
        ? item.amount 
        : parseFloat(item.amount.toFixed(2)); 
      
      const displayString = `${formattedAmount} ${item.unit} ${item.name}`;
      categorizedList[category].push(displayString);
    });

    // 3. Remove empty categories
    Object.keys(categorizedList).forEach(key => {
      if (categorizedList[key].length === 0) {
        delete categorizedList[key];
      } else {
        categorizedList[key].sort(); // Sort alphabetically within category
      }
    });

    res.status(200).json(categorizedList);

  } catch (error) {
    console.error("❌ Error generating shopping list:", error);
    res.status(500).json({ message: "Server error generating list" });
  }
};

module.exports = {
  getMealPlanByUserId,
  getMealPlanByUserIdToday,
  logMeal,
  generateShoppingList, // Export the new function
};