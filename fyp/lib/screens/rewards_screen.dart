import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../Widgets/reward_card.dart';
import '../services/reward_service.dart';
import 'redemption_shop_screen.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  late Future<GamificationData> _rewardsFuture;
  final RewardService _rewardService = RewardService();

  @override
  void initState() {
    super.initState();
    _rewardsFuture = _rewardService.getGamificationData();
  }

  Future<void> _refresh() async {
    HapticFeedback.lightImpact();
    setState(() {
      _rewardsFuture = _rewardService.getGamificationData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F7FA), // Very light grey/blue background
      appBar: AppBar(
        title: const Text('Achievements',
            style:
                TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<GamificationData>(
          future: _rewardsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: Colors.orange));
            }
            if (snapshot.hasError) {
              return Center(
                  child: Text('Error loading rewards.',
                      style: TextStyle(color: Colors.grey[600])));
            }

            if (!snapshot.hasData) return const SizedBox.shrink();

            final gameData = snapshot.data!;
            final allRewards = gameData.rewards;

            final dailyRewards = allRewards
                .where((reward) => reward.category == RewardCategory.daily)
                .toList();
            final weeklyRewards = allRewards
                .where((reward) => reward.category == RewardCategory.weekly)
                .toList();

            return ListView(
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              children: [
                _buildBalanceCard(gameData),

                const SizedBox(height: 16),

                // ⭐️ NEW: Shop Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => RedemptionShopScreen(
                                  currentCoins: gameData.coins))).then(
                          (_) => _refresh()); // Refresh coins when coming back
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      side: const BorderSide(
                          color: Colors.deepPurpleAccent, width: 1),
                    ),
                    icon: const Icon(Icons.shopping_bag_outlined),
                    label: const Text("Visit Coin Shop",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),

                const SizedBox(height: 32),

                if (dailyRewards.isNotEmpty) ...[
                  _buildSectionHeader(
                      'Daily Quests', Icons.calendar_today_rounded),
                  const SizedBox(height: 16),
                  _buildRewardGrid(dailyRewards),
                  const SizedBox(height: 32),
                ],

                if (weeklyRewards.isNotEmpty) ...[
                  _buildSectionHeader(
                      'Weekly Challenges', Icons.emoji_events_rounded),
                  const SizedBox(height: 16),
                  _buildRewardGrid(weeklyRewards),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBalanceCard(GamificationData data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2C3E50),
            Color(0xFF4CA1AF)
          ], // Sleek Blue-Grey Gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          const Text("CURRENT LEVEL",
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text("${data.level}",
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on_rounded,
                    color: Colors.amberAccent, size: 28),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Total Coins",
                        style: TextStyle(color: Colors.white70, fontSize: 10)),
                    Text("${data.coins}",
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.orange, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildRewardGrid(List<Reward> rewards) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8, // Taller cards
      ),
      itemCount: rewards.length,
      itemBuilder: (context, index) {
        return RewardCard(reward: rewards[index]);
      },
    );
  }
}
