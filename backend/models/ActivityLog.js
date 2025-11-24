const mongoose = require("mongoose");

const activityLogSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: true,
  },
  activityName: {
    type: String,
    required: true, 
    // e.g., "Running", "Cycling", "Swimming"
  },
  duration: {
    type: Number,
    required: true, 
    // stored in minutes
  },
  caloriesBurned: {
    type: Number,
    required: true,
  },
  date: {
    type: Date,
    default: Date.now,
  },
  // We store the snapshot of weight used for calculation
  weightAtLog: {
    type: Number, 
  }
});

module.exports = mongoose.model("ActivityLog", activityLogSchema);