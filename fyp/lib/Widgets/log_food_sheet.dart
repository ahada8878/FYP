import 'package:flutter/material.dart';
import 'package:fyp/screens/describe_meal_screen.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

class LogFoodSheet extends StatelessWidget {
  const LogFoodSheet({super.key});
 
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Log Food',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _LogOptionCard(
            icon: Icons.scanner,
            title: 'AI Scanner',
            onTap: () => _handleAIScanner(context),
          ),
          _LogOptionCard(
            icon: Icons.chat_bubble_outline,
            title: 'Describe meal to AI',
            onTap: () => _handleDescribeMeal(context),
          ),
          _LogOptionCard(
            icon: Icons.bookmark_border,
            title: 'Saved meals',
            onTap: () => _handleSavedMeals(context),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _handleAIScanner(BuildContext context) {
    Navigator.pop(context);
    // Add AI scanner functionality
  }

  void _handleDescribeMeal(BuildContext context) {
    Navigator.pop(context);
    PersistentNavBarNavigator.pushNewScreen(
        context,
        screen: const DescribeMealScreen(),
        withNavBar: false, 
        pageTransitionAnimation: PageTransitionAnimation.cupertino,
    ); 
  }

  void _handleSavedMeals(BuildContext context) {
    Navigator.pop(context);
    // Add saved meals functionality
  }
}

class _LogOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  const _LogOptionCard({
    required this.icon,
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 28, color: Colors.grey[600]),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
