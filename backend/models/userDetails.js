const mongoose = require("mongoose");
const { Schema } = mongoose;

// ✅ KEY FIX: `required: true` is only used for essential fields.
// This prevents the save operation from failing if optional data isn't provided.

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
  endTimes: { type: [{ type: Map, of: Schema.Types.Mixed }], default: [] },
});

module.exports = mongoose.models.UserDetails 
  ? mongoose.model('UserDetails') 
  : mongoose.model('UserDetails', userDetailsSchema);