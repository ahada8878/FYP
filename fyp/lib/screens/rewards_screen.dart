// lib/screens/rewards_screen.dart

import 'package:flutter/material.dart';
import '../Widgets/reward_card.dart';
import '../services/reward_service.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  late Future<List<Reward>> _rewardsFuture;
  final RewardService _rewardService = RewardService();

  @override
  void initState() {
    super.initState();
    _rewardsFuture = _rewardService.getRewards();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rewards'),
      ),
      body: FutureBuilder<List<Reward>>(
        future: _rewardsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No rewards to display.'));
          }

          final allRewards = snapshot.data!;

          // ✅ 1. Filter the rewards into separate lists by category
          final dailyRewards = allRewards
              .where((reward) => reward.category == RewardCategory.daily)
              .toList();
          final weeklyRewards = allRewards
              .where((reward) => reward.category == RewardCategory.weekly)
              .toList();

          // ✅ 2. Use a ListView to display multiple sections
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // --- Daily Rewards Section ---
              if (dailyRewards.isNotEmpty) ...[
                _buildSectionHeader('Daily Rewards'),
                _buildRewardGrid(dailyRewards),
                const SizedBox(height: 24),
              ],

              // --- Weekly Rewards Section ---
              if (weeklyRewards.isNotEmpty) ...[
                _buildSectionHeader('Weekly Rewards'),
                _buildRewardGrid(weeklyRewards),
              ],
            ],
          );
        },
      ),
    );
  }

  // ✅ 3. Helper widget for section headers
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  // ✅ 4. Reusable GridView builder for rewards
  Widget _buildRewardGrid(List<Reward> rewards) {
    return GridView.builder(
      // These properties are important inside a ListView
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(), 
      
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: rewards.length,
      itemBuilder: (context, index) {
        return RewardCard(reward: rewards[index]);
      },
    );
  }
}