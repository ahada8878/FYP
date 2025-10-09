const mongoose = require('mongoose');

const activitySchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  activityType: {
    type: String,
    required: true,
  },
  date: {
    type: Date,
    default: Date.now,
  },
  duration: { // in minutes
    type: Number,
    required: true
  },
  caloriesBurned: {
    type: Number,
    required: true
  }
});

module.exports = mongoose.model('Activity', activitySchema);