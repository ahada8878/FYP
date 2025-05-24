import 'package:flutter/material.dart';
import 'package:fyp/Loginpage.dart';
import 'package:fyp/camera_overlay_controller.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => CameraOverlayController(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutriWise',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          background: Colors.grey[50]!,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.grey[50],
        useMaterial3: true,
      ),
      home: const CreativeLoginPage(), // Start with login page
    );
  }
}