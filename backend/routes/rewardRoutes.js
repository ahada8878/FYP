const express = require('express');
const router = express.Router();
const {
  getRewards,
  checkAndUnlockRewards,
  redeemItem
} = require('../controllers/rewardController');
const { protect } = require('../middleware/authMiddleware');

router.route('/').get(protect, getRewards);
router.route('/check').post(protect, checkAndUnlockRewards);
router.post('/redeem', protect, redeemItem); // ✅ Add this line

module.exports = router;