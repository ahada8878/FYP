const UserDetails = require("../models/userDetails.js");
const User = require("../models/User.js");
const axios = require("axios");
const { getExcludedIngredientsFromHealthConcerns } = require("../utils/diseaseMapping.js");
const { mapEatingStylesToDiet } = require("../utils/eatingStylesMapping.js");
const MealPlan = require("../models/mealPlan.js");


const getAllUserDetails = async (req, res) => {
  try {
    const userDetails = await UserDetails.find();
    res.status(200).json(userDetails);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// ======================================================================
// ✅ FIX: New controller function for fetching the currently authenticated 
// user's profile details. This relies on the ID provided by authMiddleware.
// ======================================================================
const getMyProfile = async (req, res) => {
    try {
        // ID comes from the JWT via authMiddleware, stored as req.user.id
        const userId = req.user.id; 
        
        // Find the UserDetails document linked to the User ID.
        // Assuming the UserDetails schema has a field named 'user' that references the User model.
        const userDetails = await UserDetails.findOne({ user: userId }); 

        if (!userDetails) {
            // It's common for a user to exist but not have set up their details yet.
            return res.status(404).json({ message: 'User profile details not set up.' });
        }

        // Return only the fields required by the Flutter app's CravingsPage
        // (which are typically healthConcerns and restrictions for validation logic)
        res.json({
            healthConcerns: userDetails.healthConcerns, 
            restrictions: userDetails.restrictions,
        });

    } catch (err) {
        console.error("❌ getMyProfile failed:", err.message);
        res.status(500).send('Server Error');
    }
};


const getUserDetailsById = async (req, res) => {
  res.json(res.userDetails);
};

function calculateCalories(height, currentWeight, targetWeight) {
  try {
    const hMeters = parseFloat(height) / 100; // cm → m
    const cWeight = parseFloat(currentWeight);
    const tWeight = parseFloat(targetWeight);

    if (!hMeters || !cWeight) return 2000; // default

    const bmi = cWeight / (hMeters * hMeters);

    // Rough calorie estimate based on BMI + goal
    let calories = 2000;
    if (bmi < 18.5) calories = 2500; // underweight
    else if (bmi >= 18.5 && bmi < 25) calories = 2200; // normal
    else if (bmi >= 25 && bmi < 30) calories = 1800; // overweight
    else calories = 1600; // obese

    // Adjust if target weight < current weight → reduce calories
    if (tWeight && tWeight < cWeight) calories -= 200;

    return calories;
  } catch (err) {
    console.error("⚠️ BMI calculation failed:", err.message);
    return 2000;
  }
}

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
    console.log("🟡 Incoming req.body:", req.body);

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

    // 3️⃣ Calculate calories
    const calories = calculateCalories(height, currentWeight, targetWeight);

    // 4️⃣ Exclude ingredients based on diseases
    const exclude = getExcludedIngredientsFromHealthConcerns(healthConcerns);

    // 5️⃣ Diet from eating styles
    const diet = mapEatingStylesToDiet(eatingStyles);

    // 6️⃣ Generate Meal Plan from Spoonacular
    let mealPlan = {};
    try {
      const response = await axios.get(
        `https://api.spoonacular.com/mealplanner/generate`,
        {
          params: {
            apiKey: process.env.SPOONACULAR_API_KEY,
            timeFrame: "week",
            targetCalories: calories,
            diet,
            exclude,
          },
        }
      );
      mealPlan = response.data;
    } catch (err) {
      console.error("❌ Meal plan fetch failed:", err.response?.data || err.message);
      return res.status(500).json({ message: "Meal plan generation failed" });
    }

    // 7️⃣ Store meal plan in MongoDB
    const newMealPlan = new MealPlan({
      userId: user,
      meals: mealPlan.week,
      nutrients: mealPlan.nutrients || {},
    });
    await newMealPlan.save();
    console.log("✅ Meal plan saved in MongoDB for user:", user);

    // 8️⃣ Store meal plan on Spoonacular
    // 8️⃣ Store each meal on Spoonacular
try {
  const addMealPromises = [];

  // Loop through each day in the week
  for (const [day, data] of Object.entries(mealPlan.week)) {
    if (data.meals && Array.isArray(data.meals)) {
      for (const meal of data.meals) {
        addMealPromises.push(
          axios.post(
            `https://api.spoonacular.com/mealplanner/${username}/items`,
            {
              date: Math.floor(Date.now() / 1000), // you could offset by day if needed
              slot: 1,
              position: 0,
              type: "RECIPE", // ✅ correct enum
              value: {
                id: meal.id,
                title: meal.title,
                imageType: meal.imageType,
              },
            },
            {
              params: {
                apiKey: process.env.SPOONACULAR_API_KEY,
                hash,
              },
            }
          )
        );
      }
    }
  }

  await Promise.all(addMealPromises);
  console.log("✅ All meals saved individually on Spoonacular");
} catch (spoonErr) {
  console.error("⚠️ Failed to save meal plan on Spoonacular:", spoonErr.response?.data || spoonErr.message);
}


    // 9️⃣ Respond
    res.status(201).json({
      message: "User details saved & meal plan generated",
      details: newUserDetails,
      mealPlan: newMealPlan,
    });

  } catch (error) {
    console.error("❌ createUserDetails failed:", error);
    res.status(400).json({ message: error.message });
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
    // This middleware is used for routes like /:id, /:id/update, /:id/delete
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
  getMyProfile, // ✅ FIX: Export the new function
};
