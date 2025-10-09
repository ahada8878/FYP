const Activity = require('../models/Activity');

// @desc    Log a new activity
// @route   POST /api/activities
// @access  Private
const logActivity = async (req, res) => {
  const { activityType, duration, caloriesBurned } = req.body;

  try {
    const activity = new Activity({
      userId: req.user.id,
      activityType,
      duration,
      caloriesBurned,
    });

    const createdActivity = await activity.save();
    res.status(201).json(createdActivity);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

module.exports = {
  logActivity,
};