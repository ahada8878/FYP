const Meal = require("../models/meal.js");

const getAllMeals = async (req, res) => {
  try {
    const { dietaryRestrictions } = req.query;
    let query = {};

    if (dietaryRestrictions) {
      // Convert query string to object of boolean values
      const restrictions = {};
      const restrictionTypes = Array.isArray(dietaryRestrictions)
        ? dietaryRestrictions
        : dietaryRestrictions.split(",");

      restrictionTypes.forEach((restriction) => {
        restrictions[restriction] = true;
      });

      // Find meals that match the specified dietary restrictions
      query.dietaryRestrictions = restrictions;
    }

    const meals = await Meal.find(query);
    res.status(200).json(meals);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const getMealById = async (req, res) => {
  res.json(res.meal);
};

const createMeal = async (req, res) => {
  const {
    name,
    imageUrl,
    time,
    calories,
    type,
    cookingTime,
    macronutrients,
    ingredients,
    cookingSteps,
    dietaryRestrictions,
  } = req.body;

  const meal = new Meal({
    name,
    imageUrl,
    time,
    calories,
    type,
    cookingTime,
    macronutrients,
    ingredients,
    cookingSteps,
    dietaryRestrictions,
  });

  try {
    const newMeal = await meal.save();
    res.status(201).json(newMeal);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

const updateMeal = async (req, res) => {
  const updatableFields = [
    "name",
    "imageUrl",
    "time",
    "calories",
    "type",
    "cookingTime",
    "macronutrients",
    "ingredients",
    "cookingSteps",
    "dietaryRestrictions",
  ];

  updatableFields.forEach((field) => {
    if (req.body[field] != null) {
      res.meal[field] = req.body[field];
    }
  });

  try {
    const updatedMeal = await res.meal.save();
    res.json(updatedMeal);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

const deleteMeal = async (req, res) => {
  try {
    await res.meal.deleteOne();
    res.json({ message: "Meal deleted successfully" });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Middleware
const getMeal = async (req, res, next) => {
  let meal;
  try {
    meal = await Meal.findById(req.params.id);
    if (meal == null) {
      return res.status(404).json({ message: "Meal not found" });
    }
  } catch (error) {
    return res.status(500).json({ message: error.message });
  }

  res.meal = meal;
  next();
};

module.exports = {
  getMeal,
  getAllMeals,
  getMealById,
  createMeal,
  updateMeal,
  deleteMeal,
};
