const express = require("express");
const router = express.Router();

const {
  getMyProfile,
  saveMyProfile,
  getAllUserDetails,
  deleteUserDetails,
  updateUserName,
  updateHeight,
  updateCurrentWeight,
  updateGoalWeight,
  updateWaterConsumption,
  updateWaterGoal
} = require("../controllers/userDetailsController.js");

const authMiddleware = require('../middleware/authMiddleware');

// === PRIMARY USER PROFILE ROUTES ===

// GET /api/user-details/my-profile
// Securely fetches the profile for the currently logged-in user.
router.get("/my-profile", authMiddleware.protect, getMyProfile);

router.post("/my-profile/userName", authMiddleware.protect, updateUserName);
router.post("/my-profile/height", authMiddleware.protect, updateHeight);
router.post("/my-profile/currentWeight", authMiddleware.protect, updateCurrentWeight);
router.post("/my-profile/targetWeight", authMiddleware.protect, updateGoalWeight);
router.post("/my-profile/waterGoal", authMiddleware.protect, updateWaterGoal);
router.post("/my-profile/updateWaterConsumption", authMiddleware.protect, updateWaterConsumption);



// POST /api/user-details/my-profile
// Securely CREATES or UPDATES the profile for the logged-in user.
router.post("/my-profile", authMiddleware.protect, saveMyProfile);







// === OPTIONAL ADMIN ROUTES ===

// GET /api/user-details/
router.get("/", authMiddleware.protect, getAllUserDetails);

// DELETE /api/user-details/:id
router.delete("/:id", authMiddleware.protect, deleteUserDetails);


module.exports = router;