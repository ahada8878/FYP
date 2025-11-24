// routes/progressRoutes.js

const express = require("express");
const router = express.Router();
const { getMyHub, logWeight, logWater } = require("../controllers/progressController.js"); // Import logWater

const { protect } = require("../middleware/authMiddleware.js");

// --- Progress Hub Routes ---

// GET /api/progress/my-hub
router.route("/my-hub").post(protect, getMyHub);

// POST /api/progress/log-weight
router.route("/log-weight").post(protect, logWeight);

// POST /api/progress/log-water  <--- NEW ROUTE
router.route("/log-water").post(protect, logWater);

module.exports = router;