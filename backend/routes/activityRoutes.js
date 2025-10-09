const express = require('express');
const router = express.Router();
const { logActivity } = require('../controllers/activityController');
const protect = require('../middleware/authMiddleware');

router.route('/').post(protect, logActivity);

module.exports = router;