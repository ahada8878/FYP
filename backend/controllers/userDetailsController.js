const UserDetails = require("../models/userDetails.js");
const User = require("../models/User.js");
const axios = require("axios");
const { getExcludedIngredientsFromHealthConcerns } = require("../utils/diseaseMapping.js");
const { mapEatingStylesToDiet } = require("../utils/eatingStylesMapping.js");
const MealPlan = require("../models/mealPlan.js");
const { calculateCalories } = require("../utils/calculateCalories.js");
const { extractRecipeDetails } = require("../utils/extractRecipeDetails.js");



const getAllUserDetails = async (req, res) => {
  try {
    const userDetails = await UserDetails.find();
    res.status(200).json(userDetails);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const getUserDetailsById = async (req, res) => {
  res.json(res.userDetails);
};

const createUserDetails = async (req, res) => {
  const {
    user,
    authToken,
    userName,
    selectedMonth,
    selectedDay,
    selectedYear,
    height,
    currentWeight,
    targetWeight,
    selectedSubGoals,
    selectedHabits,
    activityLevels,
    scheduleIcons,
    healthConcerns,
    levels,
    options,
    mealOptions,
    waterOptions,
    restrictions,
    eatingStyles,
    startTimes,
    endTimes,
  } = req.body;

  try {
    console.log("🟡 Incoming req.body received for user:", userName);

    // 1️⃣ Save user details
    const userDetails = new UserDetails({
      user,
      authToken,
      userName,
      selectedMonth,
      selectedDay,
      selectedYear,
      height,
      currentWeight,
      targetWeight,
      selectedSubGoals,
      selectedHabits,
      activityLevels,
      scheduleIcons,
      healthConcerns,
      levels,
      options,
      mealOptions,
      waterOptions,
      restrictions,
      eatingStyles,
      startTimes,
      endTimes,
    });
    const newUserDetails = await userDetails.save();

    // 2️⃣ Fetch linked user
    const linkedUser = await User.findById(user).lean();
    if (!linkedUser || !linkedUser.spoonacular) {
      return res.status(400).json({ message: "User not connected to Spoonacular" });
    }
    const { username, hash } = linkedUser.spoonacular;

    // 3️⃣ Calculate calories (with activity level)
    const targetCalories = calculateCalories(height, currentWeight, targetWeight, activityLevels);
    console.log(`📊 Target calories: ${targetCalories}`);

    // 4️⃣ Get excluded ingredients
    const ingredientExclusions = getExcludedIngredientsFromHealthConcerns(healthConcerns);
    if (ingredientExclusions) console.log(`🚫 Excluding: ${ingredientExclusions}`);

    // 5️⃣ Determine diet
    const diet = mapEatingStylesToDiet(eatingStyles);
    if (diet) console.log(`🥗 Diet: ${diet}`);

    // 6️⃣ Generate weekly meal plan
    const weekPlan = {};
    const allRecipeIds = new Set();
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
              dailyMeals.push(meal);
              if (dailyMeals.length >= MEALS_PER_DAY) break;
            }
          }
        } catch (err) {
          console.error(`❌ API error for ${dayName}:`, err.response?.data || err.message);
        }
      }

      if (dailyMeals.length < MEALS_PER_DAY) {
        return res.status(500).json({
          message: `Failed to find enough unique recipes for ${dayName}. Try adjusting your restrictions.`,
        });
      }

      weekPlan[dayName] = { date, meals: dailyMeals, nutrients: finalNutrients };
    }

    // ✅ Fetch full recipe info
    if (allRecipeIds.size === 0) {
      return res.status(200).json({
        message: "User details saved, but no recipes generated.",
        details: newUserDetails,
      });
    }

    console.log(`🔍 Fetching details for ${allRecipeIds.size} recipes...`);
    const idsParam = Array.from(allRecipeIds).join(",");
    const recipeDetailsResponse = await axios.get(
      `https://api.spoonacular.com/recipes/informationBulk`,
      {
        params: {
          apiKey: process.env.SPOONACULAR_API_KEY,
          ids: idsParam,
          includeNutrition: true,
        },
      }
    );

    const allRecipes = recipeDetailsResponse.data;
    const filteredRecipes = allRecipes.map(extractRecipeDetails);
    console.log("✅ Filtered recipe data ready:", filteredRecipes.length);

    // 7️⃣ Save meal plan in MongoDB
    console.log("🟢 Saving MealPlan for user:", user);
    console.log("🟢 Week plan keys:", Object.keys(weekPlan));

    const newMealPlan = new MealPlan({
      userId: user,
      meals: weekPlan,
      detailedRecipes: filteredRecipes,
      nutrients: {},
    });

    const savedPlan = await newMealPlan.save();
    console.log("✅ Meal plan saved:", savedPlan._id);

    // 8️⃣ Respond
    res.status(201).json({
      message: "User details saved & weekly meal plan generated",
      details: newUserDetails,
      mealPlan: savedPlan,
    });

  } catch (error) {
    console.error("❌ Critical error in createUserDetails:", error);
    if (!res.headersSent) {
      res.status(500).json({ message: error.message || "Internal server error" });
    }
  }
};



const updateUserDetails = async (req, res) => {
  const updatableFields = [
    "authToken",
    "userName",
    "selectedMonth",
    "selectedDay",
    "selectedYear",
    "height",
    "currentWeight",
    "targetWeight",
    "selectedSubGoals",
    "selectedHabits",
    "activityLevels",
    "scheduleIcons",
    "healthConcerns",
    "levels",
    "options",
    "mealOptions",
    "waterOptions",
    "restrictions",
    "eatingStyles",
    "startTimes",
    "endTimes",
  ];

  updatableFields.forEach((field) => {
    if (req.body[field] != null) {
      res.userDetails[field] = req.body[field];
    }
  });

  try {
    const updatedUserDetails = await res.userDetails.save();
    res.json(updatedUserDetails);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

const deleteUserDetails = async (req, res) => {
  try {
    await res.userDetails.deleteOne();
    res.json({ message: "User details deleted successfully" });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Middleware
const getUserDetail = async (req, res, next) => {
  let userDetails;
  try {
    userDetails = await UserDetails.findById(req.params.id);
    if (userDetails == null) {
      return res.status(404).json({ message: "Cannot find user details" });
    }
  } catch (error) {
    return res.status(500).json({ message: error.message });
  }

  res.userDetails = userDetails;
  next();
};

module.exports = {
  getUserDetail,
  getAllUserDetails,
  getUserDetailsById,
  createUserDetails,
  updateUserDetails,
  deleteUserDetails,
};
