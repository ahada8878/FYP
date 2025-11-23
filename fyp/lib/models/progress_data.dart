import 'package:flutter/material.dart';
import 'package:fyp/LocalDB.dart'; 

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

  factory Achievement.fromJson(Map<String, dynamic> json) {
    // NOTE: IconData cannot be serialized, so we use a placeholder or conditional logic.
    return Achievement(
      icon: Icons.workspace_premium, 
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
  final double height; 
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
    required this.height,
  });

  // 🌟 Helper function to parse strings/nums safely
  static double _parseUnitString(dynamic value, double defaultValue) {
    if (value == null) {
      return defaultValue;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      final numberMatch = RegExp(r'(\d+(\.\d+)?)').firstMatch(value);
      if (numberMatch != null) {
        return double.tryParse(numberMatch.group(0)!) ?? defaultValue;
      }
    }
    return defaultValue;
  }

  // =======================================================
  // 1. FACTORY CONSTRUCTOR: Load from API/Server JSON
  // =======================================================
  factory ProgressData.fromJson(Map<String, dynamic> json) {

    final double rawCurrentWeight = _parseUnitString(json['currentWeight'], 0.0);
    final double rawStartWeight = _parseUnitString(json['startWeight'], 0.0);
    final double rawTargetWeight = _parseUnitString(json['targetWeight'], 0.0);
    final double rawHeightFeet = _parseUnitString(json['height'], 0.0);

    final int rawSteps = _parseUnitString(json['steps'], 0.0).toInt();
    final int rawStepGoal = _parseUnitString(json['stepGoal'], 0.0).toInt();

    final double calculatedHeightInMeters = rawHeightFeet * 0.3048;


    return ProgressData(
      currentWeight: rawCurrentWeight,
      startWeight: rawStartWeight,
      targetWeight: rawTargetWeight,
      steps: rawSteps,
      stepGoal: rawStepGoal,
      height: rawHeightFeet,
      userHeightInMeters: calculatedHeightInMeters,

      weeklyWeightData: List<double>.from(
          (json['weeklyWeightData'] as List? ?? [])
              .map((x) => _parseUnitString(x, 0.0))),

      weeklyStepsData: List<int>.from((json['weeklyStepsData'] as List? ?? [])
          .map((x) => _parseUnitString(x, 0.0).toInt())),

      achievements: List<Achievement>.from((json['achievements'] as List? ?? [])
          .map((x) => Achievement.fromJson(x as Map<String, dynamic>))),
    );
  }

  // =======================================================
  // ✅ 2. FIX: STATIC ASYNC METHOD: Load from LocalDB Fallback
  // =======================================================
  /// Now an async method to correctly handle the LocalDB Future returns.
  static Future<ProgressData> fromLocalDB() async { // 🎯 FIX 2: Added Future<ProgressData> return type and 'async'
    // ⚡️ IMPORTANT: Must use 'await' since LocalDB getters are asynchronous
    final double rawCurrentWeight =
        _parseUnitString(await LocalDB.getCurrentWeight(), 0.0);
    final double rawStartWeight = 
        _parseUnitString(await LocalDB.getStartWeight(), 0.0);
    final double rawTargetWeight =
        _parseUnitString(await LocalDB.getTargetWeight(), 0.0);
    final double rawHeightFeet = 
        _parseUnitString(await LocalDB.getHeight(), 0.0);

    final int rawSteps = _parseUnitString(await LocalDB.getSteps(), 0.0).toInt();
    final int rawStepGoal = 
        _parseUnitString(await LocalDB.getStepsGoal(), 0.0).toInt();

    final double calculatedHeightInMeters = rawHeightFeet * 0.3048;

    // Retrieving list data (must be awaited)
    final List<Map<String, dynamic>> rawAchievements =
        [];
    final List<dynamic> rawWeeklyWeightData =
        [];
    final List<dynamic> rawWeeklyStepsData =
        [];
   
    return ProgressData(
      currentWeight: rawCurrentWeight,
      startWeight: rawStartWeight,
      targetWeight: rawTargetWeight,
      steps: rawSteps,
      stepGoal: rawStepGoal,
      height: rawHeightFeet,
      userHeightInMeters: calculatedHeightInMeters,
      weeklyWeightData: List<double>.from(
          rawWeeklyWeightData.map((x) => _parseUnitString(x, 0.0))),
      weeklyStepsData: List<int>.from(
          rawWeeklyStepsData.map((x) => _parseUnitString(x, 0.0).toInt())),
      achievements: rawAchievements.map((x) => Achievement.fromJson(x)).toList(),
    );
  }


  // =======================================================
  // ✅ 3. FIX: STATIC ASYNC METHOD: Save to LocalDB
  // =======================================================
  /// Now an async method to correctly handle the LocalDB Future returns.
  static Future<void> saveToLocalDB(Map<String, dynamic> json) async { // 🎯 FIX 1: Added Future<void> return type and 'async'
    // ⚡️ IMPORTANT: Must use 'await' for all LocalDB setter calls

    LocalDB.setCurrentWeight(json['currentWeight']);
    print(json['startWeight']);
    LocalDB.setTargetWeight(json['targetWeight']);
  LocalDB.setStartWeight(json['startWeight']);
    LocalDB.setHeight(json['height']);
    LocalDB.setSteps(json['steps']);
    LocalDB.setStepsGoal(json['stepGoal']); 
    

  }

  // Add this method inside the ProgressData class
  ProgressData copyWith({
    double? currentWeight,
    double? startWeight,
    double? targetWeight,
    int? steps,
    int? stepGoal,
    double? height,
    List<Achievement>? achievements,
    double? userHeightInMeters,
    List<double>? weeklyWeightData,
    List<int>? weeklyStepsData,
  }) {
    return ProgressData(
      currentWeight: currentWeight ?? this.currentWeight,
      startWeight: startWeight ?? this.startWeight,
      targetWeight: targetWeight ?? this.targetWeight,
      steps: steps ?? this.steps,
      stepGoal: stepGoal ?? this.stepGoal,
      height: height ?? this.height,
      achievements: achievements ?? this.achievements,
      userHeightInMeters: userHeightInMeters ?? this.userHeightInMeters,
      weeklyWeightData: weeklyWeightData ?? this.weeklyWeightData,
      weeklyStepsData: weeklyStepsData ?? this.weeklyStepsData,
    );
  }

}