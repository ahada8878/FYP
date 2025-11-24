const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const rewardSchema = new mongoose.Schema({
  name: String,
  unlocked: { type: Boolean, default: false },
  dateUnlocked: { type: Date, default: Date.now }
});

const UserSchema = new mongoose.Schema({
  // ... (Keep email, password, spoonacular fields as they are) ...
  email: { type: String, required: true, unique: true, lowercase: true, trim: true },
  password: { type: String, required: true, minlength: 6 },
  spoonacular: { username: { type: String }, hash: { type: String } },
  
  // Gamification Fields
  xp: { type: Number, default: 0 },
  coins: { type: Number, default: 0 },
  level: { type: Number, default: 1 },
  
  rewards: [rewardSchema],
  
  // ⭐️ NEW: Store purchased item IDs here
  inventory: [{ type: String }] 
});

// ... (Keep Pre-save and ComparePassword methods) ...
UserSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next();
  try {
    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
    next();
  } catch (err) { next(err); }
});

UserSchema.methods.comparePassword = async function(candidatePassword) {
  return await bcrypt.compare(candidatePassword, this.password);
};

module.exports = mongoose.model('User', UserSchema);