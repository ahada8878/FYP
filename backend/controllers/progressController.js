const UserDetails = require("../models/userDetails.js");
const WeightLog = require("../models/weightLog.js");
const WaterLog = require("../models/waterLog.js"); 

/**
 * @desc    Get all progress data for the 'My Hub' screen
 * @route   GET /api/progress/my-hub
 * @access  Private
 */
const getMyHub = async (req, res) => {
  try {
    const userId = req.user.id;
    // ✅ 1. READ STEP DATA FROM THE FLUTTER APP'S REQUEST
    const { stepsToday, weeklySteps } = req.body;

    // 2. Fetch user details
    const details = await UserDetails.findOne({ user: userId })
      .select("startWeight currentWeight targetWeight stepGoal height waterGoal")
      .lean();

    if (!details) {
      return res.status(404).json({ message: "User profile not found." });
    }

    // 3. Fetch last 7 weight logs
    const weightLogs = await WeightLog.find({ user: userId })
      .sort({ date: "desc" })
      .limit(7)
      .select("weight")
      .lean();

    // --- 2. Fetch last 7 water logs ---
    const waterLogs = await WaterLog.find({ user: userId })
      .sort({ date: "desc" })
      .limit(7)
      .select("amount date")
      .lean();
    
    // 4. Process the data
    const heightCm = parseFloat(details.height?.replace(" cm", "")) || 170;
    const userHeightInMeters = heightCm / 100;
    const startWeight = parseFloat(details.startWeight) || 0;
    const currentWeight = parseFloat(details.currentWeight) || 0;
    const targetWeight = parseFloat(details.targetWeight) || 0;
    const weeklyWeightData = weightLogs.map((log) => log.weight).reverse();

    // --- 3. Process Water Data ---
    // Get today's date at 00:00:00 to find today's specific log
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    
    const todaysWaterLog = waterLogs.find(log => 
        new Date(log.date).getTime() === today.getTime()
    );
    const waterConsumedToday = todaysWaterLog ? todaysWaterLog.amount : 0;
    const weeklyWaterData = waterLogs.map(log => log.amount).reverse();

    // 5. Send the full response, including the step data
    res.status(200).json({
      currentWeight,
      startWeight,
      targetWeight,
      stepGoal: details.stepGoal,
      waterGoal: details.waterGoal || 2000, // Default to 2000 if not set
      waterConsumedToday,                   // Send today's water consumption
      userHeightInMeters,
      weeklyWeightData,
      weeklyWaterData,                     // Send weekly water data
      achievements: [], // We'll build this logic next
      steps: stepsToday || 0, // Pass through the data from the app
      weeklyStepsData: weeklySteps || [], // Pass through the data from the app
    });
    
  } catch (error) {
    console.error("❌ getMyHub failed:", error.message);
    res.status(500).send("Server Error");
  }
};

/**
 * @desc    Log a new weight entry for the user
 * @route   POST /api/progress/log-weight
 * @access  Private
 */
const logWeight = async (req, res) => {
  try {
    const userId = req.user.id;
    const { weight } = req.body;

    if (!weight) {
      return res.status(400).json({ message: "Weight is required." });
    }

    // Get the start of today's date to prevent multiple entries per day
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    // 1. Update or create the weight log for today
    // This (upsert: true) will create a new log if one for 'today' doesn't exist,
    // or update the existing one if it does.
    const newLog = await WeightLog.findOneAndUpdate(
      { user: userId, date: today },
      { weight: weight },
      { new: true, upsert: true, runValidators: true }
    );

    // 2. Also update the 'currentWeight' in the main UserDetails
    await UserDetails.updateOne(
      { user: userId },
      { currentWeight: weight.toString()+" kg" } // Update the main profile
    );

    res.status(201).json({
      message: "Weight logged successfully.",
      log: newLog,
    });
    
  } catch (error) {
    console.error("❌ logWeight failed:", error.message);
    res.status(500).send("Server Error");
  }
};

/**
 * @desc    Log water intake (Add or Update)
 * @route   POST /api/progress/log-water
 * @access  Private
 */
const logWater = async (req, res) => {
  try {
    const userId = req.user.id;
    // accept 'amount' to add (e.g., 250) 
    const { amount } = req.body; 

    if (amount === undefined) {
      return res.status(400).json({ message: "Water amount is required." });
    }

    // Get start of today to ensure we aggregate by day
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    // Use $inc to increment the existing amount, or create new if it doesn't exist
    // upsert: true creates the doc if missing
    // new: true returns the updated doc
    const updatedLog = await WaterLog.findOneAndUpdate(
      { user: userId, date: today },
      { $inc: { amount: amount } }, 
      { new: true, upsert: true, runValidators: true }
    );

    res.status(201).json({
      message: "Water logged successfully.",
      todayTotal: updatedLog.amount,
      log: updatedLog,
    });
    
  } catch (error) {
    console.error("❌ logWater failed:", error.message);
    res.status(500).send("Server Error");
  }
};

module.exports = {
  getMyHub,
  logWeight,
  logWater,
};