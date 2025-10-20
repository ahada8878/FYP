const express = require('express');
const router = express.Router();
const {
  getRewards,
  checkAndUnlockRewards,
} = require('../controllers/rewardController');
const { protect } = require('../middleware/authMiddleware');

router.route('/').get(protect, getRewards);
router.route('/check').post(protect, checkAndUnlockRewards);

module.exports = router;