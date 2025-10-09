const mongoose = require("mongoose");

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
  // --- ✅ NEW FIELD ---
  // Stores the timestamp when a meal is logged. Defaults to null.
  loggedAt: {
    type: Date,
    default: null,
  },
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
  of: new mongoose.Schema({
    date: { type: Date, required: true },
    meals: { type: Array, required: true },
    nutrients: { type: Object, default: {} },
  }),
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
