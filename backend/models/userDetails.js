const mongoose = require("mongoose");
const { Schema } = mongoose;

const userDetailsSchema = new Schema({
  user: {
    type: mongoose.SchemaTypes.ObjectId,
    ref: "User",
    required: true,
  },
  authToken: {
    type: String,
    required: true,
    default: "",
  },
  userName: {
    type: String,
    required: true,
    default: "",
  },
  selectedMonth: {
    type: String,
    required: true,
    default: "",
  },
  selectedDay: {
    type: String,
    required: true,
    default: "",
  },
  selectedYear: {
    type: String,
    required: true,
    default: "",
  },
  height: {
    type: String,
    required: true,
    default: "",
  },
  currentWeight: {
    type: String,
    required: true,
    default: "",
  },
  targetWeight: {
    type: String,
    required: true,
    default: "",
  },
  selectedSubGoals: {
    type: [String],
    required: true,
    default: [],
  },
  selectedHabits: {
    type: [Number],
    required: true,
    default: [],
  },
  activityLevels: {
    type: String,
    required: true,
    default: "{}",
  },
  scheduleIcons: {
    type: String,
    required: true,
    default: "{}",
  },
  // ✅ This structure is correct for fetching your health data
  healthConcerns: {
    type: Map,
    of: Boolean,
    required: true,
    default: {},
  },
  levels: {
    type: String,
    required: true,
    default: "{}",
  },
  options: {
    type: String,
    required: true,
    default: "{}",
  },
  mealOptions: {
    type: String,
    required: true,
    default: "{}",
  },
  waterOptions: {
    type: String,
    required: true,
    default: "{}",
  },
  // ✅ This structure is correct for fetching your restrictions
  restrictions: {
    type: Map,
    of: Schema.Types.Mixed,
    required: true,
    default: {},
  },
  eatingStyles: {
    type: Map,
    of: Schema.Types.Mixed,
    required: true,
    default: {},
  },
  startTimes: {
    type: [
      {
        type: Map,
        of: Schema.Types.Mixed,
      },
    ],
    required: true,
    default: [],
  },
  endTimes: {
    type: [
      {
        type: Map,
        of: Schema.Types.Mixed,
      },
    ],
    required: true,
    default: [],
  },
});

// 🔥 CRITICAL FIX: The export handles the compilation conditionally
module.exports = mongoose.models.UserDetails 
  ? mongoose.model('UserDetails') 
  : mongoose.model('UserDetails', userDetailsSchema);