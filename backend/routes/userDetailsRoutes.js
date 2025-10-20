const express = require("express");
const router = express.Router();

const {
  getMyProfile,
  saveMyProfile,
  getAllUserDetails,
  deleteUserDetails,
} = require("../controllers/userDetailsController.js");

const authMiddleware = require('../middleware/authMiddleware');

// === PRIMARY USER PROFILE ROUTES ===

// GET /api/user-details/my-profile
// Securely fetches the profile for the currently logged-in user.
router.get("/my-profile", authMiddleware.protect, getMyProfile);

// POST /api/user-details/my-profile
// Securely CREATES or UPDATES the profile for the logged-in user.
router.post("/my-profile", authMiddleware.protect, saveMyProfile);


// === OPTIONAL ADMIN ROUTES ===

// GET /api/user-details/
router.get("/", authMiddleware.protect, getAllUserDetails);

// DELETE /api/user-details/:id
router.delete("/:id", authMiddleware.protect, deleteUserDetails);


module.exports = router;