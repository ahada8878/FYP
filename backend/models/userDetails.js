// models/userDetails.js

const mongoose = require("mongoose");
const { Schema } = mongoose;
const { calculateCalories } = require("../utils/calculateCalories.js");

const userDetailsSchema = new Schema({
  user: {
    type: mongoose.SchemaTypes.ObjectId,
    ref: "User",
    required: true,
  },
  userName: {
    type: String,
    required: true,
  },
  height: {
    type: String,
    required: true,
  },
  currentWeight: {
    type: String,
    required: true,
  },
  targetWeight: {
    type: String,
    required: true,
  },
  caloriesGoal: {
    type: Number,
  },
  
  // --- ✅ NEW FIELDS FOR PROGRESS SCREEN ---
  startWeight: {
    type: String, // Storing as String to match 'currentWeight'
  },
  stepGoal: {
    type: Number,
    default: 10000, // Set a default goal
  },
  // ----------------------------------------

  // --- Optional Fields ---
  authToken: { type: String, default: "" },
  selectedMonth: { type: String, default: "" },
  selectedDay: { type: String, default: "" },
  selectedYear: { type: String, default: "" },
  selectedSubGoals: { type: [String], default: [] },
  selectedHabits: { type: [Number], default: [] },
  activityLevels: { type: String, default: "{}" },
  scheduleIcons: { type: String, default: "{}" },
  healthConcerns: { type: Map, of: Boolean, default: {} },
  levels: { type: String, default: "{}" },
  options: { type: String, default: "{}" },
  mealOptions: { type: String, default: "{}" },
  waterOptions: { type: String, default: "{}" },
  restrictions: { type: Map, of: Schema.Types.Mixed, default: {} },
  eatingStyles: { type: Map, of: Schema.Types.Mixed, default: {} },
  startTimes: { type: [{ type: Map, of: Schema.Types.Mixed }], default: [] },
  endTimes: { type: [{ type: Map, of:Schema.Types.Mixed }], default: [] },
});

// This pre-save hook automatically runs on create AND update
userDetailsSchema.pre("save", function (next) {

  // ✅ --- ADDED LOGIC ---
  // If 'startWeight' is not set and we are creating the user
  // or updating 'currentWeight', set 'startWeight' to 'currentWeight'.
  if (!this.startWeight || this.isModified("currentWeight") && !this.startWeight) {
    this.startWeight = this.currentWeight;
  }
  // --------------------

  if (
    this.isModified("height") ||
    this.isModified("currentWeight") ||
    this.isModified("targetWeight") ||
    this.isModified("activityLevels")
  ) {
    this.caloriesGoal = calculateCalories(
      this.height,
      this.currentWeight,
      this.targetWeight,
      this.activityLevels
    );
  }

  next(); // Continue to the save operation
});

module.exports = mongoose.models.UserDetails
  ? mongoose.model("UserDetails")
  : mongoose.model("UserDetails", userDetailsSchema);