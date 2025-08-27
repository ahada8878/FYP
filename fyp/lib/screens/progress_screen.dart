import 'package:flutter/material.dart';
import 'package:fyp/Registration/GoalWeightPage.dart';
import 'package:fyp/Registration/WeightPage.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:fyp/screens/settings_screen.dart';
import 'package:fyp/widgets/weight_chart.dart';
import 'package:fyp/widgets/water_intake_chart.dart';

class MyProgressScreen extends StatefulWidget {
  @override
  _MyProgressScreenState createState() => _MyProgressScreenState();
}

class _MyProgressScreenState extends State<MyProgressScreen> {
  // Dummy variables
  double currentWeight = 83.0;
  double targetWeight = 75.0;
  double bmi = 24.8;
  String bmiCategory = "Healthy";
  bool _showWeeklyWaterData = true;

  final List<Map<String, dynamic>> achievements = [
    {
      'icon': 'assets/images/achievement_icon.png',
      'title': 'New to Family',
      'achieved': true,
    },
    {
      'icon': 'assets/images/achievement_icon.png',
      'title': '1st Meal Scan',
      'achieved': false,
    },
    {
      'icon': 'assets/images/achievement_icon.png',
      'title': '5th Meal Scan',
      'achieved': false,
    },
    {
      'icon': 'assets/images/achievement_icon.png',
      'title': '10th Meal Scan',
      'achieved': false,
    },
    {
      'icon': 'assets/images/achievement_icon.png',
      'title': 'First Activity Logged',
      'achieved': false,
    },
    {
      'icon': 'assets/images/achievement_icon.png',
      'title': 'Daily Calorie Goal',
      'achieved': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Progress'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SettingsScreen()),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Achievements'),
            _buildAchievementsSection(),
            const SizedBox(height: 24),
            _buildSectionTitle('Weight Log'),
            _buildWeightLogSection(),
            const SizedBox(height: 24),
            _buildSectionTitle('Steps Tracker'),
            _buildStepsTracker(),
            const SizedBox(height: 24),
            _buildSectionTitle('BMI'),
            _buildBMICard(),
            const SizedBox(height: 24),
            _buildSectionTitle('Nutrition'),
            _buildProUpsell(),
            _buildSectionTitle('Weight Trend'),
            WeightChart(currentWeight: currentWeight),
            const SizedBox(height: 24),
            _buildSectionTitle('Water Intake'),
            WaterIntakeChart(
              showWeekly: _showWeeklyWaterData,
              onToggle: (value) => setState(() => _showWeeklyWaterData = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildAchievementsSection() {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: achievements.length,
        itemBuilder: (context, index) {
          final achievement = achievements[index];
          return _buildAchievementCard(
            iconPath: achievement['icon'] as String,
            title: achievement['title'] as String,
            achieved: achievement['achieved'] as bool,
          );
        },
      ),
    );
  }

  Widget _buildAchievementCard({
    required String iconPath,
    required String title,
    required bool achieved,
  }) {
    return Opacity(
      opacity: achieved ? 1.0 : 0.5,
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        child: Card(
          elevation: achieved ? 2 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: achieved ? Colors.white : Colors.grey[200],
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ColorFiltered(
                  colorFilter: achieved
                      ? const ColorFilter.mode(
                          Colors.transparent, BlendMode.multiply)
                      : const ColorFilter.matrix([
                          0.2126,
                          0.7152,
                          0.0722,
                          0,
                          0,
                          0.2126,
                          0.7152,
                          0.0722,
                          0,
                          0,
                          0.2126,
                          0.7152,
                          0.0722,
                          0,
                          0,
                          0,
                          0,
                          0,
                          1,
                          0,
                        ]),
                  child: Image.asset(
                    iconPath,
                    width: 40,
                    height: 40,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: achieved ? Colors.black : Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeightLogSection() {
    return Row(
      children: [
        Expanded(
            child:
                _buildWeightCard('Current Weight', currentWeight, Icons.scale)),
        const SizedBox(width: 12),
        Expanded(
            child: _buildWeightCard('Target Weight', targetWeight, Icons.flag)),
      ],
    );
  }

  Widget _buildWeightCard(String title, double weight, IconData icon) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 32, color: Colors.blueGrey),
                const SizedBox(height: 8),
                Text(title, style: const TextStyle(color: Colors.grey)),
                Text('${weight.toStringAsFixed(1)} kg',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                  icon: const Icon(Icons.edit, size: 18, color: Colors.grey),
                  onPressed: () async {
                    final updatedWeight =
                        await PersistentNavBarNavigator.pushNewScreen(
                      context,
                      screen: title == "Current Weight"
                          ? const WeightPage(isEditing: true)
                          : GoalWeightPage(
                              isEditing: true,
                              currentWeight: currentWeight,
                            ),
                      withNavBar: false,
                      pageTransitionAnimation:
                          PageTransitionAnimation.cupertino,
                    );

                    if (updatedWeight != null) {
                      setState(() {
                        if (title == 'Current Weight') {
                          currentWeight = updatedWeight;
                          bmi = currentWeight / (1.75 * 1.75);
                          if (bmi < 18.5) {
                            bmiCategory = "Underweight";
                          } else if (bmi < 25) {
                            bmiCategory = "Healthy";
                          } else if (bmi < 30) {
                            bmiCategory = "Overweight";
                          } else {
                            bmiCategory = "Obese";
                          }
                        } else {
                          targetWeight = updatedWeight;
                        }
                      });
                    }
                  }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepsTracker() {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.android,
                color: Color.fromRGBO(106, 79, 153, 1), size: 40),
            const SizedBox(width: 16),
            const Icon(Icons.directions_walk,
                color: Color.fromRGBO(106, 79, 153, 1), size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Get steps in sync with Health Connect!',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(106, 79, 153, 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () {},
                    child: const Text(
                      'Connect',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBMICard() {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Current BMI',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getBmiCategoryColor(),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(bmiCategory,
                      style: const TextStyle(color: Colors.white)),
                ),
              ],
            ),
            Text(bmi.toStringAsFixed(1),
                style:
                    const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildBMIScale(),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () {},
                child: const Text('Recommendation Source',
                    style: TextStyle(
                      color: Colors.grey,
                      decoration: TextDecoration.underline,
                    )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getBmiCategoryColor() {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }

  Widget _buildBMIScale() {
    const double minBMI = 15;
    const double maxBMI = 40;
    double normalizedBMI = bmi.clamp(minBMI, maxBMI);
    double positionFactor = (normalizedBMI - minBMI) / (maxBMI - minBMI);
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: const LinearGradient(
                  colors: [
                    Colors.blue,
                    Colors.green,
                    Colors.yellow,
                    Colors.red
                  ],
                  stops: [0.15, 0.4, 0.6, 1.0],
                ),
              ),
            ),
            Positioned(
              left: constraints.maxWidth * positionFactor - 8,
              child: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.grey, blurRadius: 2)],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProUpsell() {
    return Center(
      child: Card(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text('Will be developed Later'),
              const SizedBox(height: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                      color: const Color.fromRGBO(106, 79, 153, 1)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                onPressed: () {},
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(106, 79, 153, 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('...',
                          style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(width: 8),
                    const Text('Coming soon'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
