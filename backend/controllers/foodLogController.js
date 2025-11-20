// backend/controllers/foodLogController.js

const FoodLog = require('../models/foodLog');
const UserDetails = require('../models/userDetails');
const { GoogleGenerativeAI } = require("@google/generative-ai");

// Initialize Gemini
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

/**
 * @desc    Log a new, custom food item
 * @route   POST /api/foodlog
 * @access  Private
 */
const logFoodItem = async (req, res) => {
    try {
        const { date, mealType, product_name, brands, image_url, nutrients } = req.body;

        if (!mealType || !product_name || !nutrients) {
            return res.status(400).json({ 
                success: false, 
                message: 'Missing required fields: mealType, product_name, and nutrients are required.' 
            });
        }

        const foodLogEntry = new FoodLog({
            user: req.userId, 
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
 * @route   GET /api/foodlog/:date
 * @access  Private
 */
const getFoodLogForDate = async (req, res) => {
    try {
        const requestedDate = new Date(req.params.date);
        const startOfDay = new Date(requestedDate);
        startOfDay.setHours(0, 0, 0, 0);
        const endOfDay = new Date(requestedDate);
        endOfDay.setHours(23, 59, 59, 999);

        const foodLogs = await FoodLog.find({
            user: req.userId,
            date: { $gte: startOfDay, $lte: endOfDay }
        }).sort({ createdAt: 'asc' });

        res.status(200).json({ success: true, count: foodLogs.length, data: foodLogs });
    
    } catch (error) {
        console.error('Error in getFoodLogForDate:', error);
        res.status(500).json({ success: false, message: 'Server error while fetching food log.' });
    }
};

/**
 * @desc    Generate a structured JSON weekly health report
 * @route   POST /api/foodlog/generate-report
 * @access  Private
 */
const generateWeeklyReport = async (req, res) => {
    try {
        const userDetails = await UserDetails.findOne({ user: req.userId });
        if (!userDetails) {
            return res.status(404).json({ success: false, message: "User details not found." });
        }

        // Helper to stringify map keys
        const formatMapKeys = (mapObj) => {
            if (!mapObj) return "None";
            const activeKeys = [];
            for (const [key, value] of mapObj) {
                if (value === true || value === 'true') activeKeys.push(key);
            }
            return activeKeys.length > 0 ? activeKeys.join(", ") : "None";
        };

        const userProfile = `
        - Name: ${userDetails.userName}
        - Current Weight: ${userDetails.currentWeight} kg
        - Target Weight: ${userDetails.targetWeight} kg
        - Daily Calorie Goal: ${userDetails.caloriesGoal} kcal
        - Health Concerns: ${formatMapKeys(userDetails.healthConcerns)}
        - Dietary Restrictions: ${formatMapKeys(userDetails.restrictions)}
        `;

        // Get last 7 days logs
        const endDate = new Date();
        const startDate = new Date();
        startDate.setDate(endDate.getDate() - 6); 
        startDate.setHours(0, 0, 0, 0);
        endDate.setHours(23, 59, 59, 999);

        const weeklyLogs = await FoodLog.find({
            user: req.userId,
            date: { $gte: startDate, $lte: endDate }
        }).sort({ date: 'asc' });

        if (!weeklyLogs || weeklyLogs.length === 0) {
            return res.status(400).json({ success: false, message: "No food logs found for this week." });
        }

        let logSummary = "";
        weeklyLogs.forEach(log => {
            const day = log.date.toDateString();
            // We include 0 values so AI knows to estimate
            const macros = `Cal: ${log.nutrients.calories}, P: ${log.nutrients.protein}g, C: ${log.nutrients.carbohydrates}g, F: ${log.nutrients.fat}g`;
            logSummary += `- [${day}] ${log.mealType}: ${log.product_name} (${macros})\n`;
        });

        // --- UPDATED PROMPT FOR JSON ---
        const prompt = `
        You are a nutritionist API. Analyze this weekly food log for the user.
        
        ### User Profile:
        ${userProfile}

        ### Food Log:
        ${logSummary}

        ### Output Requirement:
        Return ONLY valid JSON (no markdown, no code blocks). 
        The JSON must follow this exact schema:
        {
            "summary": "A short 2-sentence summary of their week.",
            "macros_percentage": { 
                "protein": 30, 
                "carbs": 50, 
                "fat": 20 
            },
            "daily_chart": [
                { "day": "Mon", "calories": 1800, "goal": ${userDetails.caloriesGoal || 2000} },
                { "day": "Tue", "calories": 2100, "goal": ${userDetails.caloriesGoal || 2000} }
                // ... for all days present in log
            ],
            "micronutrients": [
                 { "name": "Vitamin C", "status": "Good", "insight": "High intake from oranges." },
                 { "name": "Iron", "status": "Low", "insight": "Consider adding spinach." }
            ],
            "analysis": {
                "strengths": ["Point 1", "Point 2"],
                "improvements": ["Point 1", "Point 2"]
            },
            "tips": ["Tip 1", "Tip 2", "Tip 3"]
        }

        IMPORTANT: 
        1. Estimate missing macro/calorie values based on food names.
        2. Ensure "daily_chart" has data for days listed in the log.
        3. "macros_percentage" must sum to approx 100.
        `;

        const model = genAI.getGenerativeModel({ 
            model: "gemini-2.5-flash",
            generationConfig: { responseMimeType: "application/json" } // Force JSON mode
        }); 
        
        const result = await model.generateContent(prompt);
        const response = await result.response;
        let text = response.text();

        // Clean up if model adds markdown wrapping despite instructions
        text = text.replace(/```json/g, '').replace(/```/g, '').trim();

        const reportJson = JSON.parse(text);

        res.status(200).json({ 
            success: true, 
            data: reportJson 
        });

    } catch (error) {
        console.error('Error generating report:', error);
        res.status(500).json({ success: false, message: 'AI Report Generation Failed' });
    }
};

module.exports = {
    logFoodItem,
    getFoodLogForDate,
    generateWeeklyReport
};