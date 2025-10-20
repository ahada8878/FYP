const mongoose = require("mongoose");

// Detailed recipe info (no more loggedAt here)
const detailedRecipeSchema = new mongoose.Schema({
  id: Number,
  title: String,
  image: String,
  readyInMinutes: Number,
  servings: Number,
  sourceUrl: String,
  ingredients: [
    {
      id: Number,
      name: String,
      amount: Number,
      unit: String,
    },
  ],
  instructions: String,
  nutrients: {
    calories: Number,
    carbs: Number,
    protein: Number,
    fat: Number,
    fiber: Number,
  },
});

// Meals for each day (✅ loggedAt moved here)
const dailyMealSchema = new mongoose.Schema({
  date: { type: Date, required: true },
  meals: [
    {
      id: Number,
      title: String,
      image: String,
      readyInMinutes: Number,
      servings: Number,
      sourceUrl: String,
      // ✅ NEW FIELD: Logged time for each individual meal
      loggedAt: {
        type: Date,
        default: null,
      },
    },
  ],
  nutrients: { type: Object, default: {} },
});

const mealPlanSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: true,
  },
  weekStart: {
    type: Date,
    default: Date.now,
  },
  meals: {
    type: Map,
    of: dailyMealSchema,
    required: true,
  },
  detailedRecipes: {
    type: [detailedRecipeSchema],
    default: [],
  },
  nutrients: {
    type: Object,
    default: {},
  },
});

module.exports = mongoose.model("MealPlan", mealPlanSchema);
