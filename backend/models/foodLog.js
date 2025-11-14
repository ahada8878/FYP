const mongoose = require('mongoose');
const Schema = mongoose.Schema;

// This small schema will store the key nutrients
const nutrientSchema = new Schema({
    calories: { type: Number, default: 0 },
    protein: { type: Number, default: 0 },
    fat: { type: Number, default: 0 },
    carbohydrates: { type: Number, default: 0 }
}, { _id: false });

const foodLogSchema = new Schema({
    user: {
        type: Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    // The date the food was eaten
    date: {
        type: Date,
        default: Date.now,
        required: true
    },
    // What meal this was for (Breakfast, Lunch, etc.)
    mealType: {
        type: String,
        enum: ['Breakfast', 'Lunch', 'Dinner', 'Snack'],
        required: true
    },
    // Details from the scanned/searched product
    product_name: {
        type: String,
        required: true
    },
    brands: {
        type: String
    },
    image_url: {
        type: String
    },
    // The nutritional info for the item
    nutrients: nutrientSchema,

    // You could also add fields like 'servingSize' or 'quantity' here

}, {
    timestamps: true // Adds createdAt and updatedAt
});

// Indexing will make it much faster to fetch logs for a user on a specific date
foodLogSchema.index({ user: 1, date: -1 });

module.exports = mongoose.model('FoodLog', foodLogSchema);