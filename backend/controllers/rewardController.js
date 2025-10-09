const User = require('../models/User');
const Activity = require('../models/Activity');

// @desc    Get all rewards for a user
// @route   GET /api/rewards
// @access  Private
const getRewards = async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    if (user) {
      res.json(user.rewards);
    } else {
      res.status(404).json({ message: 'User not found' });
    }
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// @desc    Check for and unlock rewards based on user activities
// @route   POST /api/rewards/check
// @access  Private
const checkAndUnlockRewards = async (req, res) => {
  const userId = req.user.id;

  try {
    // Example: Reward for a 2km walk (assuming 'Walking' and duration)
    const walkingActivities = await Activity.find({
      userId,
      activityType: 'Walking',
    });

    // This is a simplified example. You might want to check the date.
    if (walkingActivities.some(activity => activity.duration >= 20)) { // ~2km
      await unlockReward(userId, 'Morning Walk');
    }

    // Add more reward logic here...
    // For example, for a 7-day streak, you would query activities over the past 7 days.

    const updatedUser = await User.findById(userId);
    res.json(updatedUser.rewards);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};


// Helper function to unlock a reward if it's not already unlocked
const unlockReward = async (userId, rewardName) => {
  const user = await User.findById(userId);
  if (user) {
    const hasReward = user.rewards.some(reward => reward.name === rewardName);
    if (!hasReward) {
      user.rewards.push({ name: rewardName, unlocked: true, dateUnlocked: new Date() });
      await user.save();
    }
  }
};


module.exports = {
  getRewards,
  checkAndUnlockRewards
};