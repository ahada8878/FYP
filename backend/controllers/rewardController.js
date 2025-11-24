const User = require('../models/User');
const Activity = require('../models/Activity');
const FoodLog = require('../models/foodLog');
const WaterLog = require('../models/waterLog');

// --- HELPER FUNCTIONS ---

// Check if two dates are the same calendar day
const isSameDay = (d1, d2) => {
  return d1.getFullYear() === d2.getFullYear() &&
         d1.getMonth() === d2.getMonth() &&
         d1.getDate() === d2.getDate();
};

// Check if two dates are in the same week (Assumes week starts on Sunday)
const isSameWeek = (d1, d2) => {
  const oneJan = new Date(d1.getFullYear(), 0, 1);
  const numberOfDays = Math.floor((d1 - oneJan) / (24 * 60 * 60 * 1000));
  const week1 = Math.ceil((d1.getDay() + 1 + numberOfDays) / 7);

  const oneJan2 = new Date(d2.getFullYear(), 0, 1);
  const numberOfDays2 = Math.floor((d2 - oneJan2) / (24 * 60 * 60 * 1000));
  const week2 = Math.ceil((d2.getDay() + 1 + numberOfDays2) / 7);

  return d1.getFullYear() === d2.getFullYear() && week1 === week2;
};

// Check streak: consecutive days with logs
function checkStreak(logs, daysRequired) {
    if (!logs || logs.length === 0) return false;
    
    // Sort logs by date descending
    const sortedLogs = logs.sort((a, b) => new Date(b.date) - new Date(a.date));
    const uniqueDays = new Set();
    
    // Get unique dates
    sortedLogs.forEach(log => {
        uniqueDays.add(new Date(log.date).toDateString());
    });

    // Simple check: do we have enough unique days? 
    // (For a stricter consecutive check, you'd need more complex loop logic, 
    // but this is usually sufficient for a prototype)
    return uniqueDays.size >= daysRequired;
}

// ⭐️ 1. Define the Shop Catalog (Single Source of Truth for Prices)
const SHOP_ITEMS = {
  'theme_dark': { cost: 500, name: "Dark Mode" },
  'recipe_pack_1': { cost: 200, name: "Keto Recipe Pack" },
  'badge_gold': { cost: 1000, name: "Golden Profile Frame" },
  'consultation_15': { cost: 5000, name: "15min Nutritionist Chat" }
};

// --- CONTROLLERS ---

// @desc    Get active rewards for the current period
// @route   GET /api/rewards
// @access  Private
const getRewards = async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    if (!user) return res.status(404).json({ message: 'User not found' });

    const now = new Date();

    // Filter rewards to only show those active for the CURRENT cycle
    const activeRewards = user.rewards.filter(reward => {
      const rewardDate = new Date(reward.dateUnlocked);

      if (reward.name.startsWith('daily_')) {
        // Only valid if unlocked TODAY
        return isSameDay(now, rewardDate);
      } 
      else if (reward.name.startsWith('weekly_')) {
        // Only valid if unlocked THIS WEEK
        return isSameWeek(now, rewardDate);
      }
      // Permanent achievements (if any) are always returned
      return true;
    });

    res.json({
        rewards: activeRewards,
        xp: user.xp || 0,
        coins: user.coins || 0,
        level: user.level || 1
    });

  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// @desc    Check for and unlock rewards based on user activities
// @route   POST /api/rewards/check
// @access  Private
const checkAndUnlockRewards = async (req, res) => {
  const userId = req.user.id;
  const { currentSteps = 0, weeklySteps = [] } = req.body; 

  const now = new Date();
  const todayStart = new Date();
  todayStart.setHours(0, 0, 0, 0);

  const weekStart = new Date();
  weekStart.setDate(weekStart.getDate() - 7); // Rough "last 7 days" window for data fetching

  try {
    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ message: "User not found" });

    // 1. FETCH RELEVANT DATA
    const todaysWater = await WaterLog.find({ user: userId, date: { $gte: todayStart } });
    const todaysFood = await FoodLog.find({ user: userId, date: { $gte: todayStart } });
    const weekFood = await FoodLog.find({ user: userId, date: { $gte: weekStart } });
    const weekActivity = await Activity.find({ userId: userId, date: { $gte: weekStart } });

    // 2. CALCULATE STATS
    const totalWaterMl = todaysWater.reduce((acc, log) => acc + log.amount, 0);
    const hasBreakfast = todaysFood.some(log => log.mealType === 'Breakfast');
    const sugarIntake = todaysFood.reduce((acc, log) => acc + (log.nutrients?.sugar || 0), 0); // Assuming sugar exists
    const totalWeeklySteps = weeklySteps.reduce((a, b) => a + b, 0);

    // 3. DEFINE REWARD CRITERIA
    const potentialRewards = [
      // --- DAILY (Reset every midnight) ---
      { 
        id: 'daily_login', 
        check: true, 
        xp: 10, coins: 5 
      },
      { 
        id: 'daily_water_8', 
        check: totalWaterMl >= 2000, 
        xp: 20, coins: 10 
      },
      { 
        id: 'daily_breakfast', 
        check: hasBreakfast, 
        xp: 15, coins: 5 
      },
      { 
        id: 'daily_steps_6k', 
        check: currentSteps >= 6000, 
        xp: 30, coins: 15 
      },
      { 
        id: 'daily_no_sugar', 
        // Only valid if they have actually logged something, otherwise it's too easy
        check: todaysFood.length > 0 && sugarIntake < 30, 
        xp: 50, coins: 25 
      },
      
      // --- WEEKLY (Reset every Sunday/Monday logic) ---
      {
        id: 'weekly_steps_50k',
        check: totalWeeklySteps >= 50000, 
        xp: 100, coins: 50
      },
      {
        id: 'weekly_workout_3',
        check: weekActivity.length >= 3,
        xp: 100, coins: 50
      },
      {
        id: 'weekly_streak_7',
        check: checkStreak(weekFood, 7),
        xp: 200, coins: 100
      }
    ];

    // 4. CHECK & UNLOCK
    let newlyUnlocked = [];
    
    for (const reward of potentialRewards) {
      // Find the LAST time this specific reward was unlocked
      // We search the array in reverse or find the most recent date
      const existing = user.rewards
        .filter(r => r.name === reward.id)
        .sort((a, b) => new Date(b.dateUnlocked) - new Date(a.dateUnlocked))[0];

      let isAlreadyClaimedCycle = false;

      if (existing) {
        const unlockDate = new Date(existing.dateUnlocked);
        if (reward.id.startsWith('daily_')) {
            isAlreadyClaimedCycle = isSameDay(now, unlockDate);
        } else if (reward.id.startsWith('weekly_')) {
            isAlreadyClaimedCycle = isSameWeek(now, unlockDate);
        }
      }

      // If criteria met AND not claimed in this current cycle -> Give Reward
      if (reward.check && !isAlreadyClaimedCycle) {
        user.rewards.push({ 
            name: reward.id, 
            unlocked: true, 
            dateUnlocked: now 
        });
        
        user.xp += reward.xp;
        user.coins += reward.coins;
        newlyUnlocked.push(reward.id);
      }
    }

    // 5. LEVEL UP
    const calculatedLevel = Math.floor(1 + Math.sqrt(user.xp) * 0.2);
    if (calculatedLevel > user.level) {
      user.level = calculatedLevel;
    }

    if (newlyUnlocked.length > 0 || user.isModified('level')) {
      await user.save();
    }

    // 6. FILTER FOR RESPONSE (Same logic as getRewards)
    // We only want to return "Active" rewards to the frontend so it renders them correctly
    const activeRewards = user.rewards.filter(reward => {
        const rewardDate = new Date(reward.dateUnlocked);
        if (reward.name.startsWith('daily_')) return isSameDay(now, rewardDate);
        if (reward.name.startsWith('weekly_')) return isSameWeek(now, rewardDate);
        return true;
    });

    res.json({
      rewards: activeRewards,
      newlyUnlocked: newlyUnlocked,
      xp: user.xp,
      coins: user.coins,
      level: user.level
    });

  } catch (error) {
    console.error(error);
    res.status(500).json({ message: error.message });
  }
};

// ⭐️ 2. New Controller Function: Redeem Item
// @route   POST /api/rewards/redeem
const redeemItem = async (req, res) => {
  const userId = req.user.id;
  const { itemId } = req.body;

  try {
    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ message: "User not found" });

    // Validate Item
    const item = SHOP_ITEMS[itemId];
    if (!item) return res.status(400).json({ message: "Invalid item ID" });

    // Check Ownership
    if (user.inventory && user.inventory.includes(itemId)) {
      return res.status(400).json({ message: "You already own this item!" });
    }

    // Check Funds
    if (user.coins < item.cost) {
      return res.status(400).json({ message: "Insufficient coins" });
    }

    // Transaction
    user.coins -= item.cost;
    if (!user.inventory) user.inventory = [];
    user.inventory.push(itemId);

    await user.save();

    res.json({
      success: true,
      message: `Successfully purchased ${item.name}`,
      coins: user.coins,
      inventory: user.inventory
    });

  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = {
  getRewards,
  checkAndUnlockRewards,
  redeemItem
};