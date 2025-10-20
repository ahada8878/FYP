// lib/models/progress_data.dart

import 'package:flutter/material.dart'; // For IconData

class Achievement {
  final IconData icon;
  final String title;
  final String description;
  final bool isAchieved;
  Achievement({
    required this.icon,
    required this.title,
    required this.description,
    this.isAchieved = false,
  });

  // Factory constructor to parse from JSON (for achievements)
  factory Achievement.fromJson(Map<String, dynamic> json) {
    // This is a placeholder. We will build this out when we
    // implement the achievements logic on the backend.
    return Achievement(
      icon: Icons.workspace_premium, // Default icon
      title: json['title'] ?? 'Unlocked',
      description: json['description'] ?? 'You did it!',
      isAchieved: json['isAchieved'] ?? true,
    );
  }
}

class ProgressData {
  final double currentWeight;
  final double startWeight;
  final double targetWeight;
  final int steps;
  final int stepGoal;
  final List<Achievement> achievements;
  final double userHeightInMeters;
  final List<double> weeklyWeightData;
  final List<int> weeklyStepsData;

  ProgressData({
    required this.currentWeight,
    required this.startWeight,
    required this.targetWeight,
    required this.steps,
    required this.stepGoal,
    required this.achievements,
    required this.userHeightInMeters,
    required this.weeklyWeightData,
    required this.weeklyStepsData,
  });

  /// Factory constructor to parse the JSON from our /api/progress/my-hub endpoint
  factory ProgressData.fromJson(Map<String, dynamic> json) {
    return ProgressData(
      currentWeight: (json['currentWeight'] as num).toDouble(),
      startWeight: (json['startWeight'] as num).toDouble(),
      targetWeight: (json['targetWeight'] as num).toDouble(),
      steps: (json['steps'] as num).toInt(),
      stepGoal: (json['stepGoal'] as num).toInt(),
      userHeightInMeters: (json['userHeightInMeters'] as num).toDouble(),
      
      weeklyWeightData: List<double>.from(
        json['weeklyWeightData'].map((x) => (x as num).toDouble())
      ),
      weeklyStepsData: List<int>.from(
        json['weeklyStepsData'].map((x) => (x as num).toInt())
      ),
      
      // Parse the achievements list
      achievements: List<Achievement>.from(
        json['achievements'].map((x) => Achievement.fromJson(x))
      ),
    );
  }
}