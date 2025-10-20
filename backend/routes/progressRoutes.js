// routes/progressRoutes.js

const express = require("express");
const router = express.Router();
const { getMyHub, logWeight } = require("../controllers/progressController.js");

// We need to import the 'protect' middleware.
// Based on your server.js, it's defined there but not exported.
// We will modify server.js in the next step to export it.
const { protect } = require("../middleware/authMiddleware.js"); // We'll make this work next

// --- Progress Hub Routes ---

// GET /api/progress/my-hub
router.route("/my-hub").post(protect, getMyHub);

// POST /api/progress/log-weight
router.route("/log-weight").post(protect, logWeight);

module.exports = router;