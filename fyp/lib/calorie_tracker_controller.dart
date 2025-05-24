// calorie_tracker_controller.dart
import 'package:flutter/foundation.dart';

class CalorieTrackerController extends ChangeNotifier {
  int _totalCalories = 0;
  int _dailyGoal = 2239;

  int get totalCalories => _totalCalories;
  int get dailyGoal => _dailyGoal;

  void setTotalCalories(int total) {
    _totalCalories = total;
    notifyListeners();
  }

  void setDailyGoal(int goal) {
    _dailyGoal = goal;
    notifyListeners();
  }
}