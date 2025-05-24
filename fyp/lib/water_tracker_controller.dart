import 'package:flutter/material.dart';

class WaterTrackerController extends ChangeNotifier {
  int _filledGlasses = 0;

  int get filledGlasses => _filledGlasses;
  
  void updateGlasses(int glasses) {
    _filledGlasses = glasses.clamp(0, 12);
    notifyListeners();
  }
  
  void addWater(double milliliters) {
    final glasses = (milliliters / 200).floor(); // 200ml per glass
    _filledGlasses = (_filledGlasses + glasses).clamp(0, 12);
    notifyListeners();
  }
}