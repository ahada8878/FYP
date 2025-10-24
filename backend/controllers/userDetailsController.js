const UserDetails = require("../models/userDetails.js");
const User = require("../models/User.js");
const MealPlan = require("../models/MealPlan.js");
const axios = require("axios");

// Utility function imports
const { getExcludedIngredientsFromHealthConcerns } = require("../utils/diseaseMapping.js");
const { mapEatingStylesToDiet } = require("../utils/eatingStylesMapping.js");
// <-- REMOVED: calculateCalories is no longer needed in this file.
const { extractRecipeDetails } = require("../utils/extractRecipeDetails.js");

// ======================================================================
// 헬 Helper Function for Meal Plan Generation
// ======================================================================

const generateWeeklyMealPlan = async (userDetails, user) => {
    const linkedUser = await User.findById(user._id || user.id).lean();
    if (!linkedUser?.spoonacular) {
        throw new Error("User not connected to Spoonacular");
    }
    const { username, hash } = linkedUser.spoonacular;

    const targetCalories = userDetails.caloriesGoal;
    
    const ingredientExclusions = getExcludedIngredientsFromHealthConcerns(userDetails.healthConcerns);
    if (ingredientExclusions) console.log(`🚫 Excluding: ${ingredientExclusions}`);
    const diet = mapEatingStylesToDiet(userDetails.eatingStyles);
    if (diet) console.log(`🥗 Diet: ${diet}`);

    console.log(`📊 Generating meal plan for user ${user._id || user.id} with target calories: ${targetCalories}`);

    const weekPlan = {};
    const allRecipeIds = new Set();
    const API_KEY = process.env.SPOONACULAR_API_KEY;
    const minCalories = Math.max(1200, targetCalories - 300);
    const maxCalories = targetCalories + 100;
    console.log(`🔥 Generating meal plan (calories: ${minCalories}-${maxCalories})`);

for (let i = 0; i < 7; i++) {
  const dayName = `day${i + 1}`;
  const date = new Date();
  date.setDate(date.getDate() + i);

  const dailyMeals = [];
  let finalNutrients = {};
  let attempts = 0;
  const MAX_ATTEMPTS = 10;
  const MEALS_PER_DAY = 3;

  while (dailyMeals.length < MEALS_PER_DAY && attempts < MAX_ATTEMPTS) {
    attempts++;
    const randomCalories = Math.floor(Math.random() * (maxCalories - minCalories + 1)) + minCalories;

    try {
      const { data } = await axios.get(`https://api.spoonacular.com/mealplanner/generate`, {
        params: {
          apiKey: process.env.SPOONACULAR_API_KEY,
          timeFrame: "day",
          targetCalories: randomCalories,
          diet,
          exclude: ingredientExclusions,
          seed: Date.now() + i + attempts,
        },
      });

      const meals = data.meals || [];
      finalNutrients = data.nutrients;

      for (const meal of meals) {
        if (!allRecipeIds.has(meal.id)) {
          allRecipeIds.add(meal.id);

          // ✅ Add `loggedAt` to each individual meal object
          dailyMeals.push({
            ...meal,
            loggedAt: null,
          });

          if (dailyMeals.length >= MEALS_PER_DAY) break;
        }
      }
    } catch (err) {
      console.error(`❌ API error for ${dayName}:`, err.response?.data || err.message);
    }
  }

  if (dailyMeals.length < MEALS_PER_DAY) {
  console.warn(`⚠️ Could not generate ${MEALS_PER_DAY} unique meals for ${dayName} after ${MAX_ATTEMPTS} attempts.`);

  // ✅ Allow similar (non-unique) meals instead of throwing error
  try {
    const fallbackCalories = Math.floor((minCalories + maxCalories) / 2);
    const { data: fallbackData } = await axios.get(`https://api.spoonacular.com/mealplanner/generate`, {
      params: {
        apiKey: process.env.SPOONACULAR_API_KEY,
        timeFrame: "day",
        targetCalories: fallbackCalories,
        diet,
        exclude: ingredientExclusions,
      },
    });

    const fallbackMeals = fallbackData.meals || [];
    for (const meal of fallbackMeals) {
      if (dailyMeals.length >= MEALS_PER_DAY) break;

      // Push similar (possibly duplicate) meals to complete the day
      dailyMeals.push({
        ...meal,
        loggedAt: null,
      });
    }

    finalNutrients = fallbackData.nutrients || finalNutrients;
    console.log(`✅ Used similar meals to complete ${dayName}.`);
  } catch (fallbackErr) {
    console.error(`❌ Fallback failed for ${dayName}:`, fallbackErr.response?.data || fallbackErr.message);
  }
}


  // ✅ store per-day meals with their own loggedAt fields
  weekPlan[dayName] = { date, meals: dailyMeals, nutrients: finalNutrients };
}


    // ✅ Fetch full recipe info
    if (allRecipeIds.size === 0) {
      return res.status(200).json({
        message: "User details saved, but no recipes generated.",
        details: newUserDetails,
      });
    }
    
    const idsParam = Array.from(allRecipeIds).join(",");
    const { data: recipeDetails } = await axios.get(`https://api.spoonacular.com/recipes/informationBulk`, {
        params: { apiKey: API_KEY, ids: idsParam, includeNutrition: true },
    });

    const filteredRecipes = recipeDetails.map(extractRecipeDetails);
    const newMealPlan = new MealPlan({ userId: user._id || user.id, meals: weekPlan, detailedRecipes: filteredRecipes });
    const savedPlan = await newMealPlan.save();
    console.log(`✅ Meal plan ${savedPlan._id} saved successfully in MongoDB.`);

    // Add meals to Spoonacular user's meal planner
    const addMealPromises = recipeDetails.map(meal =>
        axios.post(`https://api.spoonacular.com/mealplanner/${username}/items`, {
            date: Math.floor(new Date().getTime() / 1000),
            slot: 1,
            position: 0,
            type: "RECIPE",
            value: { id: meal.id, servings: 1, title: meal.title, imageType: meal.imageType },
        }, { params: { hash, apiKey: API_KEY } })
    );

    try {
        await Promise.all(addMealPromises);
        console.log("✅ Meals added to Spoonacular user account.");
    } catch (spoonErr) {
        console.error("⚠️ Failed to save meal plan on Spoonacular:", spoonErr.response?.data || spoonErr.message);
    }
    return savedPlan;
};

// ======================================================================
// ✅ Primary Controller Functions
// ======================================================================

/**
 * @desc    Create or Update the profile for the logged-in user and generate a meal plan.
 * @route   POST /api/user-details/my-profile
 * @access  Private
 */
const saveMyProfile = async (req, res) => {
    console.log('--- Attempting to save user profile ---');
    console.log('🔑 Authenticated User ID:', req.user?.id);
    console.log('📦 Request Body Payload:', JSON.stringify(req.body, null, 2));

    try {
        const userId = req.user.id;
        if (!userId) {
            return res.status(401).json({ message: 'Authentication error: User ID not found.' });
        }
        
        // <-- ✅ CHANGED: Replaced 'findOneAndUpdate' with 'findOne' + '.save()'
        
        // 1. Find the existing document
        let userDetails = await UserDetails.findOne({ user: userId });

        if (!userDetails) {
            // 2a. If it doesn't exist, create a new one
            userDetails = new UserDetails({ ...req.body, user: userId });
        } else {
            // 2b. If it exists, update it with new data from req.body
            userDetails.set(req.body);
        }

        // 3. Save the document. This will trigger the 'pre-save' hook.
        // The hook calculates 'caloriesGoal' before it hits the DB.
        const savedUserDetails = await userDetails.save();
        
        console.log(`✅ User details successfully saved for user: ${userId}`);
        // 'savedUserDetails' now contains the calculated caloriesGoal

        // 4. Generate a fresh weekly meal plan based on the new details
        console.log('⚙️ Generating new meal plan...');
        const mealPlan = await generateWeeklyMealPlan(savedUserDetails, req.user);

        // 5. Respond with success
        res.status(201).json({
            message: "Profile saved and weekly meal plan generated successfully!",
            details: savedUserDetails,
            mealPlan,
        });

    } catch (error) {
        console.error("❌ Critical error in saveMyProfile:", error);
        if (error.name === 'ValidationError') {
            return res.status(400).json({ message: 'Validation failed. Please check your input.', errors: error.message });
        }
        res.status(500).json({ message: error.message || "An internal server error occurred." });
    }
};

/**
 * @desc    Get the profile for the currently logged-in user
 * @route   GET /api/user-details/my-profile
 * @access  Private
 */
const getMyProfile = async (req, res) => {
    try {
        const userDetails = await UserDetails.findOne({ user: req.user.id });
        if (!userDetails) {
            return res.status(404).json({ message: 'User profile not yet created.' });
        }
        res.status(200).json(userDetails);
    } catch (error) {
        console.error("❌ getMyProfile failed:", error.message);
        res.status(500).send('Server Error');
    }
};

// ======================================================================
// ⚙️ Admin & Utility Controller Functions
// ======================================================================

/**
 * @desc    Get all user profiles (Admin Only)
 * @route   GET /api/user-details
 * @access  Private/Admin
 */
const getAllUserDetails = async (req, res) => {
    try {
        const allDetails = await UserDetails.find().populate('user', 'name email');
        res.status(200).json(allDetails);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

/**
 * @desc    Delete a user profile by its ID (Admin Only)
 * @route   DELETE /api/user-details/:id
 * @access  Private/Admin
 */
const deleteUserDetails = async (req, res) => {
    try {
        const userDetails = await UserDetails.findById(req.params.id);
        if (!userDetails) {
            return res.status(404).json({ message: "Cannot find user details to delete." });
        }
        await userDetails.deleteOne();
        res.json({ message: "User details deleted successfully." });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

module.exports = {
    saveMyProfile,
    getMyProfile,
    getAllUserDetails,
    deleteUserDetails,
};