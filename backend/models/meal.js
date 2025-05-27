const mongoose = require("mongoose");
const { Schema } = mongoose;

const mealSchema = new Schema(
  {
    name: {
      type: String,
      required: true,
    },
    imageUrl: {
      type: String,
      required: true,
    },
    time: {
      type: String,
      required: true,
    },
    calories: {
      type: Number,
      required: true,
    },
    type: {
      type: String,
      required: true,
    },
    cookingTime: {
      type: String,
      required: true,
    },
    macronutrients: {
      type: Map,
      of: String,
      required: true,
    },
    ingredients: {
      type: [String],
      required: true,
    },
    cookingSteps: {
      type: [String],
      required: true,
    },
    dietaryRestrictions: {
      type: Map,
      of: Boolean,
      default: {
        diabetesFriendly: false,
        hypertensionFriendly: false,
      },
    },
  },
  { timestamps: true }
);

const Meal = mongoose.model("Meal", mealSchema);

module.exports = Meal;
