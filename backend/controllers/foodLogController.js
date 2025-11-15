const FoodLog = require('../models/foodLog');
 
/**
 * @desc    Log a new, custom food item
 * @route   POST /api/foodlog
 * @access  Private
 */
const logFoodItem = async (req, res) => {
    try {
        // Get all the food details from the request body
        // The Flutter app will send this after scanning or searching
        const { date, mealType, product_name, brands, image_url, nutrients } = req.body;

        if (!mealType || !product_name || !nutrients) {
            return res.status(400).json({ 
                success: false, 
                message: 'Missing required fields: mealType, product_name, and nutrients are required.' 
            });
        }

        const foodLogEntry = new FoodLog({
            user: req.userId, // This comes from the 'protect' middleware
            date: date ? new Date(date) : new Date(),
            mealType,
            product_name,
            brands,
            image_url,
            nutrients: {
                calories: nutrients.calories || 0,
                protein: nutrients.protein || 0,
                fat: nutrients.fat || 0,
                carbohydrates: nutrients.carbohydrates || 0
            }
        });

        await foodLogEntry.save();

        res.status(201).json({ success: true, data: foodLogEntry });

    } catch (error) {
        console.error('Error in logFoodItem:', error);
        res.status(500).json({ success: false, message: 'Server error while logging food.' });
    }
};

/**
 * @desc    Get all food log items for a specific date
 * @route   GET /api/foodlog/:date (e.g., /api/foodlog/2025-11-10)
 * @access  Private
 */
const getFoodLogForDate = async (req, res) => {
    try {
        const requestedDate = new Date(req.params.date);
        
        // Set time to the start of the day
        const startOfDay = new Date(requestedDate);
        startOfDay.setHours(0, 0, 0, 0);

        // Set time to the end of the day
        const endOfDay = new Date(requestedDate);
        endOfDay.setHours(23, 59, 59, 999);

        // Find all logs for this user that fall between the start and end of the day
        const foodLogs = await FoodLog.find({
            user: req.userId,
            date: {
                $gte: startOfDay,
                $lte: endOfDay
            }
        }).sort({ createdAt: 'asc' }); // Show in the order they were logged

        res.status(200).json({ success: true, count: foodLogs.length, data: foodLogs });

    } catch (error) {
        console.error('Error in getFoodLogForDate:', error);
        res.status(500).json({ success: false, message: 'Server error while fetching food log.' });
    }
};

module.exports = {
    logFoodItem,
    getFoodLogForDate
};