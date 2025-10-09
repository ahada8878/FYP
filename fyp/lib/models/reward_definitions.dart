import 'package:fyp/Widgets/reward_card.dart'; // Or wherever your Reward model is

/// This map is the single source of truth for all possible rewards in the app.
/// The `achieved` status is handled dynamically by the RewardService and should not be set here.
final Map<String, Reward> allRewardDefinitions = {
  // --- Daily Rewards ---
  'Morning Walk': const Reward(
    title: 'Morning Walk',
    description: 'Walk 2km',
    icon: 'assets/images/achievement_icon.png',
    category: RewardCategory.daily,
  ),
  'Hydration Hero': const Reward(
    title: 'Hydration Hero',
    description: 'Drink 8 glasses of water',
    icon: 'assets/images/achievement_icon.png',
    category: RewardCategory.daily,
  ),
  'Healthy Start': const Reward(
    title: 'Healthy Start',
    description: 'Log a healthy breakfast',
    icon: 'assets/images/achievement_icon.png',
    category: RewardCategory.daily,
  ),
  'Mindful Minute': const Reward(
    title: 'Mindful Minute',
    description: 'Complete a meditation session',
    icon: 'assets/images/achievement_icon.png',
    category: RewardCategory.daily,
  ),

  // --- Weekly Rewards ---
  'Workout Warrior': const Reward(
    title: 'Workout Warrior',
    description: 'Complete 3 workouts',
    icon: 'assets/images/achievement_icon.png',
    category: RewardCategory.weekly,
  ),
  'Meal Master': const Reward(
    title: 'Meal Master',
    description: 'Log meals for 5 consecutive days',
    icon: 'assets/images/achievement_icon.png',
    category: RewardCategory.weekly,
  ),
  'Sleep Champion': const Reward(
    title: 'Sleep Champion',
    description: 'Get 7-8 hours of sleep for 3 nights',
    icon: 'assets/images/achievement_icon.png',
    category: RewardCategory.weekly,
  ),
  'Step Superstar': const Reward(
    title: 'Step Superstar',
    description: 'Reach 50,000 steps in a week',
    icon: 'assets/images/achievement_icon.png',
    category: RewardCategory.weekly,
  ),
};