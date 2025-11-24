const mongoose = require('mongoose');
const Schema = mongoose.Schema;

const waterLogSchema = new Schema({
    user: {
        type: Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    date: {
        type: Date,
        required: true
    },
    amount: { 
        type: Number, // in milliliters (ml)
        required: true,
        default: 0 
    }
}, {
    timestamps: true
});

// Ensure we only have one water log document per user per day
waterLogSchema.index({ user: 1, date: 1 }, { unique: true });

module.exports = mongoose.model('WaterLog', waterLogSchema);