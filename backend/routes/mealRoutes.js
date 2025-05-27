const express = require("express");
const {
  getMeal,
  getAllMeals,
  getMealById,
  createMeal,
  updateMeal,
  deleteMeal,
} = require( "../controllers/mealController.js");

const router = express.Router();

router.get("/", getAllMeals);
router.get("/:id", getMeal, getMealById);
router.post("/", createMeal);
router.patch("/:id", getMeal, updateMeal);
router.delete("/:id", getMeal, deleteMeal);

module.exports = router;
