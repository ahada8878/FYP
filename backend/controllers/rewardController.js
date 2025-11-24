const User = require('../models/User');
const Activity = require('../models/Activity');
const FoodLog = require('../models/foodLog'); // ✅ Required for logging
const WaterLog = require('../models/waterLog');

// ... (Keep isSameDay, isSameWeek, checkStreak helpers exactly as they were) ...
const isSameDay = (d1, d2) => {
  return d1.getFullYear() === d2.getFullYear() &&
         d1.getMonth() === d2.getMonth() &&
         d1.getDate() === d2.getDate();
};

const isSameWeek = (d1, d2) => {
  const oneJan = new Date(d1.getFullYear(), 0, 1);
  const numberOfDays = Math.floor((d1 - oneJan) / (24 * 60 * 60 * 1000));
  const week1 = Math.ceil((d1.getDay() + 1 + numberOfDays) / 7);
  const oneJan2 = new Date(d2.getFullYear(), 0, 1);
  const numberOfDays2 = Math.floor((d2 - oneJan2) / (24 * 60 * 60 * 1000));
  const week2 = Math.ceil((d2.getDay() + 1 + numberOfDays2) / 7);
  return d1.getFullYear() === d2.getFullYear() && week1 === week2;
};

function checkStreak(logs, daysRequired) {
    if (!logs || logs.length === 0) return false;
    const sortedLogs = logs.sort((a, b) => new Date(b.date) - new Date(a.date));
    const uniqueDays = new Set();
    sortedLogs.forEach(log => uniqueDays.add(new Date(log.date).toDateString()));
    return uniqueDays.size >= daysRequired;
}

// ⭐️ 1. REDEFINED SHOP: CHEAT FOODS ONLY
// These items will be automatically logged to the food diary upon purchase.
const CHEAT_SHOP_ITEMS = {
  'cheat_pizza': { 
    name: "Pepperoni Pizza Slice", 
    cost: 500, 
    nutrients: { calories: 298, protein: 13, fat: 12, carbohydrates: 34, sugar: 3 } 
  },
  'cheat_burger': { 
    name: "Cheeseburger", 
    cost: 600, 
    nutrients: { calories: 303, protein: 16, fat: 14, carbohydrates: 30, sugar: 5 } 
  },
  'cheat_donut': { 
    name: "Glazed Donut", 
    cost: 250, 
    nutrients: { calories: 269, protein: 4, fat: 15, carbohydrates: 31, sugar: 15 } 
  },
  'cheat_soda': { 
    name: "Cola Can (330ml)", 
    cost: 150, 
    nutrients: { calories: 139, protein: 0, fat: 0, carbohydrates: 35, sugar: 35 } 
  },
  'cheat_icecream': { 
    name: "Vanilla Cone", 
    cost: 200, 
    nutrients: { calories: 207, protein: 3, fat: 11, carbohydrates: 23, sugar: 19 } 
  },
  'cheat_fries': { 
    name: "Medium Fries", 
    cost: 350, 
    nutrients: { calories: 365, protein: 4, fat: 17, carbohydrates: 48, sugar: 0 } 
  }
};

// ... (Keep getRewards and checkAndUnlockRewards exactly as they were) ...
// @desc    Get active rewards
const getRewards = async (req, res) => {
    // ... (Previous implementation of getRewards)
    try {
      const user = await User.findById(req.user.id);
      if (!user) return res.status(404).json({ message: 'User not found' });
  
      const now = new Date();
      // Filter to only show valid rewards for current cycle
      const activeRewards = user.rewards.filter(reward => {
        const rewardDate = new Date(reward.dateUnlocked);
        if (reward.name.startsWith('daily_')) return isSameDay(now, rewardDate);
        if (reward.name.startsWith('weekly_')) return isSameWeek(now, rewardDate);
        return true;
      });
  
      res.json({
          rewards: activeRewards,
          xp: user.xp || 0,
          coins: user.coins || 0,
          level: user.level || 1,
          inventory: user.inventory || []
      });
  
    } catch (error) {
      res.status(500).json({ message: error.message });
    }
};

const checkAndUnlockRewards = async (req, res) => {
    // ... (Previous implementation of checkAndUnlockRewards)
    const userId = req.user.id;
    const { currentSteps = 0, weeklySteps = [] } = req.body; 
  
    const now = new Date();
    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0);
  
    const weekStart = new Date();
    weekStart.setDate(weekStart.getDate() - 7); 
  
    try {
      const user = await User.findById(userId);
      if (!user) return res.status(404).json({ message: "User not found" });
  
      // 1. FETCH DATA
      const todaysWater = await WaterLog.find({ user: userId, date: { $gte: todayStart } });
      const todaysFood = await FoodLog.find({ user: userId, date: { $gte: todayStart } });
      const todaysActivity = await Activity.find({ userId: userId, date: { $gte: todayStart } });
      const weekFood = await FoodLog.find({ user: userId, date: { $gte: weekStart } });
      const weekActivity = await Activity.find({ userId: userId, date: { $gte: weekStart } });
  
      // 2. CALCULATE STATS
      const totalWaterMl = todaysWater.reduce((acc, log) => acc + log.amount, 0);
      
      // Meal Checks
      const hasBreakfast = todaysFood.some(log => log.mealType === 'Breakfast');
      const hasLunch = todaysFood.some(log => log.mealType === 'Lunch');
      const hasDinner = todaysFood.some(log => log.mealType === 'Dinner');
  
      // Activity Checks
      const caloriesBurnedToday = todaysActivity.reduce((acc, log) => acc + (log.caloriesBurned || 0), 0);
      const totalWeeklySteps = weeklySteps.reduce((a, b) => a + b, 0);
  
      // 3. DEFINE REWARDS (Updated)
      const potentialRewards = [
        // --- DAILY ---
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
          id: 'daily_3_meals',
          check: hasBreakfast && hasLunch && hasDinner, 
          xp: 50, coins: 25 
        },
        { 
          id: 'daily_steps_6k', 
          check: currentSteps >= 6000, 
          xp: 30, coins: 15 
        },
        {
          id: 'daily_burn_300', 
          check: caloriesBurnedToday >= 300,
          xp: 40, coins: 20
        },
        
        // --- WEEKLY ---
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
  
      // 4. PROCESS UNLOCKS
      let newlyUnlocked = [];
      
      for (const reward of potentialRewards) {
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
  
        if (reward.check && !isAlreadyClaimedCycle) {
          user.rewards.push({ name: reward.id, unlocked: true, dateUnlocked: now });
          user.xp += reward.xp;
          user.coins += reward.coins;
          newlyUnlocked.push(reward.id);
        }
      }
  
      // Level Up
      const calculatedLevel = Math.floor(1 + Math.sqrt(user.xp) * 0.2);
      if (calculatedLevel > user.level) user.level = calculatedLevel;
  
      if (newlyUnlocked.length > 0 || user.isModified('level')) {
        await user.save();
      }
  
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
      res.status(500).json({ message: error.message });
    }
};


// ⭐️ 2. REDEEM ITEM & LOG FOOD
// @route   POST /api/rewards/redeem
const redeemItem = async (req, res) => {
  const userId = req.user.id;
  const { itemId } = req.body;

  try {
    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ message: "User not found" });

    // 1. Validate Item
    const item = CHEAT_SHOP_ITEMS[itemId];
    if (!item) return res.status(400).json({ message: "Invalid item ID" });

    // 2. Check Coins
    if (user.coins < item.cost) {
      return res.status(400).json({ message: "Insufficient coins" });
    }

    // 3. Deduct Coins
    user.coins -= item.cost;
    
    // 4. Create Food Log Entry automatically
    // We default to 'Snack' for cheat items
    const newLog = new FoodLog({
      user: userId,
      date: new Date(),
      mealType: 'Snack', 
      product_name: `[Reward] ${item.name}`,
      brands: 'Cheat Shop',
      image_url: '', // Could use a static asset URL here
      nutrients: item.nutrients
    });

    await newLog.save();
    await user.save();

    res.json({
      success: true,
      message: `Redeemed ${item.name}! Logged to your diary.`,
      coins: user.coins,
      inventory: user.inventory // Keeping inventory array in case we need history later
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