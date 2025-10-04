// models/MealPlan.js
const mongoose = require("mongoose");

const mealSchema = new mongoose.Schema({
  id: Number,
  title: String,
  imageType: String,
  readyInMinutes: Number,
  servings: Number,
  sourceUrl: String,
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
    type: Object, // stores the full "week" object from Spoonacular
    required: true,
  },
  nutrients: {
    type: Object,
    default: {},
  },
});

module.exports = mongoose.model("MealPlan", mealPlanSchema);
