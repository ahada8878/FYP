// calorie_tracker_controller.dart
import 'package:flutter/foundation.dart';

class CalorieTrackerController extends ChangeNotifier {
  int _totalCalories = 0;
  int _dailyGoal = 2239;

  int get totalCalories => _totalCalories;
  int get dailyGoal => _dailyGoal;

   int _totalBurnedCalories = 0;
  int get totalBurnedCalories => _totalBurnedCalories;

  String? _latestActivity;
  int? _latestDuration;
  int? _latestCalories;

  String? get latestActivity => _latestActivity;
  int? get latestDuration => _latestDuration;
  int? get latestCalories => _latestCalories;

  void updateLatestActivity(String activity, int duration, int calories) {
    _latestActivity = activity;
    _latestDuration = duration;
    _latestCalories = calories;
    notifyListeners();
  }
  
  void addBurnedCalories(int calories) {
    _totalBurnedCalories += calories;
    notifyListeners();
  }

  void setTotalCalories(int total) {
    _totalCalories = total;
    notifyListeners();
  }

  void setDailyGoal(int goal) {
    _dailyGoal = goal;
    notifyListeners();
  }
}