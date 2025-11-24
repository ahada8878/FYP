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
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD), // Clean, airy background
      appBar: AppBar(
        title: Text(
          'Achievements',
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryColor),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: primaryColor,
        child: FutureBuilder<GamificationData>(
          future: _rewardsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                  child: CircularProgressIndicator(color: primaryColor));
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
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
              children: [
                _buildPremiumStatsCard(gameData, primaryColor),

                const SizedBox(height: 24),

                // ⭐️ Updated Shop Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
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
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: primaryColor.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.storefront_rounded, size: 24),
                    label: const Text("Visit Coin Shop",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),

                const SizedBox(height: 32),

                if (dailyRewards.isNotEmpty) ...[
                  _buildCenteredSectionHeader(
                      'Daily Quests', Icons.bolt_rounded, primaryColor),
                  const SizedBox(height: 20),
                  _buildRewardGrid(dailyRewards),
                  const SizedBox(height: 32),
                ],

                if (weeklyRewards.isNotEmpty) ...[
                  _buildCenteredSectionHeader('Weekly Challenges',
                      Icons.emoji_events_rounded, primaryColor),
                  const SizedBox(height: 20),
                  _buildRewardGrid(weeklyRewards),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPremiumStatsCard(GamificationData data, Color primaryColor) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              colors: [
                primaryColor,
                primaryColor.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Decorative Circles
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: -30,
                left: -30,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Level Section
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                "CURRENT LEVEL",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "${data.level}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 42,
                                height: 1.0,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        // Divider
                        Container(
                          height: 50,
                          width: 1,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        // Coins Section
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              "Total Balance",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.monetization_on_rounded,
                                    color: Colors.amberAccent, size: 24),
                                const SizedBox(width: 8),
                                Text(
                                  "${data.coins}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCenteredSectionHeader(
      String title, IconData icon, Color color) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: Colors.grey.withOpacity(0.3),
            thickness: 1,
            endIndent: 10,
          ),
        ),
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Colors.grey[800],
          ),
        ),
        Expanded(
          child: Divider(
            color: Colors.grey.withOpacity(0.3),
            thickness: 1,
            indent: 10,
          ),
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
        childAspectRatio: 0.75, // Slightly taller to allow breathing room
      ),
      itemCount: rewards.length,
      itemBuilder: (context, index) {
        return RewardCard(reward: rewards[index]);
      },
    );
  }
}