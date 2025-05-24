import 'package:flutter/material.dart';

class CameraOverlayController extends ChangeNotifier {
  bool _showOverlay = false;
  bool get showOverlay => _showOverlay;

  void show() {
    _showOverlay = true;
    notifyListeners();
  }

  void hide() {
    _showOverlay = false;
    notifyListeners();
  }
}