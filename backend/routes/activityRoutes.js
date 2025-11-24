const express = require("express");
const router = express.Router();
const authMiddleware = require("../middleware/authMiddleware");
const { logActivity, getRecentActivities, getActivityHistory } = require("../controllers/activityController");

// POST /api/activities/log
// Requires Auth Token
router.post("/log", authMiddleware.protect, logActivity);

// GET /api/activities/history
// Optional: If you want to show history later
router.get("/history", authMiddleware.protect, getRecentActivities);
router.get("/full-history", authMiddleware.protect, getActivityHistory);


module.exports = router;