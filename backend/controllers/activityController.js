const ActivityLog = require("../models/ActivityLog");
const UserDetails = require("../models/userDetails");

// MET (Metabolic Equivalent of Task) values for various activities
// These are standard estimates.
const MET_VALUES = {
  "Running": 9.8,
  "Cycling": 7.5,
  "Walking": 3.8,
  "Swimming": 8.0,
  "Yoga": 2.5,
  "HIIT": 11.0,
  "Strength Training": 5.0,
  "Jump Rope": 12.0,
  "Hiking": 6.0,
  "Dancing": 4.5
};

const logActivity = async (req, res) => {
  try {
    const userId = req.user.id; // From authMiddleware
    const { activityName, duration, date } = req.body;

    if (!activityName || !duration) {
      return res.status(400).json({ message: "Please provide activity name and duration." });
    }

    // 1. Get User's Weight for accurate calorie calculation
    // We try to find their profile, if not found, we default to 70kg (average)
    const userDetails = await UserDetails.findOne({ user: userId });
    let weightInKg = 70; 

    if (userDetails && userDetails.currentWeight) {
      // Assuming weight is stored as a string like "75.5" or just numbers
      const parsedWeight = parseFloat(userDetails.currentWeight);
      if (!isNaN(parsedWeight)) {
        weightInKg = parsedWeight;
      }
    }

    // 2. Calculate Calories
    // Formula: Calories = MET * Weight(kg) * Duration(hours)
    const met = MET_VALUES[activityName] || 4.0; // Default to moderate activity if unknown
    const durationInHours = duration / 60;
    const caloriesBurned = Math.round(met * weightInKg * durationInHours);

    // 3. Create the Log
    const newLog = new ActivityLog({
      user: userId,
      activityName,
      duration,
      caloriesBurned,
      date: date || new Date(),
      weightAtLog: weightInKg
    });

    await newLog.save();

    console.log(`✅ Activity Logged: ${activityName} for ${duration} mins (${caloriesBurned} kcal)`);

    res.status(201).json({
      message: "Activity logged successfully",
      data: newLog
    });

  } catch (error) {
    console.error("❌ Error logging activity:", error);
    res.status(500).json({ message: "Server error while logging activity" });
  }
};

const getRecentActivities = async (req, res) => {
  try {
    const userId = req.user.id;
    // Get last 10 activities, sorted by newest first
    const logs = await ActivityLog.find({ user: userId })
      .sort({ date: -1 })
      .limit(10);

    res.status(200).json(logs);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const getActivityHistory = async (req, res) => {
  try {
    const userId = req.user.id;
    
    // Fetch all logs, sorted by newest first
    const logs = await ActivityLog.find({ user: userId })
      .sort({ date: -1 });

    res.status(200).json(logs);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};


module.exports = {
  logActivity,
  getRecentActivities,
  getActivityHistory
};