const express = require("express");
const {
  getUserDetail,
  getAllUserDetails,
  getUserDetailsById,
  createUserDetails,
  updateUserDetails,
  deleteUserDetails,
  getMyProfile, // 1. Must be added to your controller file
} = require( "../controllers/userDetailsController.js");

// 2. Import the authentication middleware
const authMiddleware = require('../middleware/authMiddleware'); 

const router = express.Router();

// ======================================================================
// ✅ FIX: Fixed path must come BEFORE the dynamic path to resolve conflict
// ======================================================================

// 3. Define the fixed route for the authenticated user's profile
router.get("/my-profile", authMiddleware, getMyProfile);

// Dynamic routes (will not conflict with /my-profile now)
router.get("/", getAllUserDetails);
router.get("/:id", getUserDetail, getUserDetailsById);
router.post("/", createUserDetails);
router.patch("/:id", getUserDetail, updateUserDetails);
router.delete("/:id", getUserDetail, deleteUserDetails);

module.exports = router;