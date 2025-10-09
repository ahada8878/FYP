import 'package:flutter/material.dart';

enum RewardCategory {
  daily,
  weekly,
}

class Reward {
  final String title;
  final String description;
  final String icon;
  final bool achieved;
  final RewardCategory category;

  const Reward({
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
    this.achieved = false,

  });
}
  
class RewardCard extends StatelessWidget {
  final Reward reward;

  const RewardCard({super.key, required this.reward});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: reward.achieved ? Colors.white : Colors.grey[200],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              reward.icon,
              width: 50,
              height: 50,
              color: reward.achieved ? null : Colors.grey,
            ),
            const SizedBox(height: 5),
            Text(
              reward.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: reward.achieved ? Colors.black : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              reward.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: reward.achieved ? Colors.grey[700] : Colors.grey[500],
              ),
            ),
            if (reward.achieved) ...[
              const SizedBox(height: 2),
              ElevatedButton(
                onPressed: () {
                  // TODO: Implement "Log Reward" functionality
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(106, 79, 153, 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Log it',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}