// models/weightLog.js

const mongoose = require("mongoose");
const { Schema } = mongoose;

const weightLogSchema = new Schema(
  {
    user: {
      type: mongoose.SchemaTypes.ObjectId,
      ref: "User",
      required: true,
    },
    weight: {
      type: Number,
      required: true,
    },
    date: {
      type: Date,
      required: true,
      default: Date.now,
    },
  },
  {
    // This adds 'createdAt' and 'updatedAt' fields automatically
    timestamps: true, 
  }
);

// This ensures a user can only have one weight entry per day
weightLogSchema.index({ user: 1, date: 1 }, { unique: true });

module.exports = mongoose.models.WeightLog
  ? mongoose.model("WeightLog")
  : mongoose.model("WeightLog", weightLogSchema);