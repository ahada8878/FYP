import 'package:flutter/material.dart';

enum RewardCategory {
  daily,
  weekly,
}

class Reward {
  final String title;
  final String description;
  final IconData icon; // ✅ Changed to IconData for better visuals
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (reward.achieved)
            BoxShadow(
              color: Colors.orange.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
          else
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // 1. Background
            Container(
              decoration: BoxDecoration(
                gradient: reward.achieved
                    ? const LinearGradient(
                        colors: [Color(0xFFFF9800), Color(0xFFFF5722)], // Orange Glow
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [Colors.grey.shade200, Colors.grey.shade300],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
              ),
            ),

            // 2. Content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icon Container
                  Container(
                    height: 60,
                    width: 60,
                    decoration: BoxDecoration(
                      color: reward.achieved
                          ? Colors.white.withOpacity(0.2)
                          : Colors.white.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      reward.icon,
                      size: 32,
                      color: reward.achieved ? Colors.white : Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Title
                  Text(
                    reward.title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: reward.achieved ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Description
                  Text(
                    reward.description,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: reward.achieved
                          ? Colors.white.withOpacity(0.9)
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            // 3. Lock Overlay (If not achieved)
            if (!reward.achieved)
              Positioned(
                top: 8,
                right: 8,
                child: Icon(
                  Icons.lock_rounded,
                  color: Colors.grey.shade500,
                  size: 18,
                ),
              ),
              
            // 4. Checkmark Overlay (If achieved)
            if (reward.achieved)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.orange,
                    size: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}