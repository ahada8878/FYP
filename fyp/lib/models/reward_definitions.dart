import 'package:flutter/material.dart';
import 'package:fyp/Widgets/reward_card.dart'; 

final Map<String, Reward> allRewardDefinitions = {
  // ==================================================
  // 🟢 DAILY REWARDS
  // ==================================================
  
  'daily_login': const Reward(
    title: 'Early Bird',
    description: 'Open the app to start your day right',
    icon: Icons.wb_sunny_rounded, 
    category: RewardCategory.daily,
  ),
  'daily_water_8': const Reward(
    title: 'Hydro Homie',
    description: 'Drink 2000ml (8 cups) of water',
    icon: Icons.water_drop_rounded,
    category: RewardCategory.daily,
  ),
  'daily_breakfast': const Reward(
    title: 'Breakfast Club',
    description: 'Log a breakfast meal',
    icon: Icons.egg_alt_rounded,
    category: RewardCategory.daily,
  ),
  'daily_steps_6k': const Reward(
    title: 'Step Up',
    description: 'Walk 6,000 steps today',
    icon: Icons.directions_walk_rounded,
    category: RewardCategory.daily,
  ),
  'daily_no_sugar': const Reward(
    title: 'Sugar Free',
    description: 'Keep sugar under 30g today',
    icon: Icons.block_rounded,
    category: RewardCategory.daily,
  ),

  // ==================================================
  // 🟡 WEEKLY REWARDS
  // ==================================================

  'weekly_streak_7': const Reward(
    title: 'On Fire!',
    description: 'Log food for 7 days in a row',
    icon: Icons.local_fire_department_rounded,
    category: RewardCategory.weekly,
  ),
  'weekly_steps_50k': const Reward(
    title: 'Marathoner',
    description: 'Walk 50k steps this week',
    icon: Icons.map_rounded,
    category: RewardCategory.weekly,
  ),
  'weekly_diverse_diet': const Reward(
    title: 'Variety King',
    description: 'Eat 10 different ingredients',
    icon: Icons.restaurant_menu_rounded,
    category: RewardCategory.weekly,
  ),
  'weekly_workout_3': const Reward(
    title: 'Gym Beast',
    description: 'Log 3 workouts this week',
    icon: Icons.fitness_center_rounded,
    category: RewardCategory.weekly,
  ),
  'weekly_deficit': const Reward(
    title: 'On Target',
    description: 'Hit calorie goal 5 days',
    icon: Icons.track_changes_rounded,
    category: RewardCategory.weekly,
  ),
};