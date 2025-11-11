import 'dart:async'; // Required for the Timer
import 'package:flutter/material.dart';
// Assuming these imports are correctly defined in your project
import 'package:fyp/LocalDB.dart';
import 'package:fyp/MissingRouteDataForSignUp.dart';
import 'package:fyp/calorie_tracker_controller.dart';
import 'package:fyp/camera_overlay_controller.dart';
import 'package:fyp/water_tracker_controller.dart';
import 'package:provider/provider.dart';

// IMPORTANT: Ensure you have run the following command 
// after setting up your icon in pubspec.yaml:
// flutter pub run flutter_native_splash:create

void main() async {
  // Ensure that Flutter bindings are initialized before calling native code.
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize the local database before running the app.
  await LocalDB.init();
  runApp(
    // Use MultiProvider to provide multiple controllers to the widget tree.
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CameraOverlayController()),
        ChangeNotifierProvider(create: (_) => WaterTrackerController()),
        ChangeNotifierProvider(create: (_) => CalorieTrackerController()),
      ],
      child: const MyApp(),
    ),
  );
}

/// The root widget of the application.
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  /// A static method to find the nearest `_MyAppState` and trigger a restart.
  static void restartApp(BuildContext context) {
    context.findAncestorStateOfType<_MyAppState>()?.restartApp();
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // A unique key that, when changed, forces the widget subtree to be rebuilt.
  Key _key = UniqueKey();
  
  // State to track if the custom splash screen delay is over.
  bool _isSplashFinished = false;

  @override
  void initState() {
    super.initState();
    // Start a timer for the 2-second display delay.
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isSplashFinished = true;
        });
      }
    });
  }

  /// Changes the key to trigger a rebuild of the widget tree.
  // 🚀 FIXED: Removed the reset of _isSplashFinished.
  void restartApp() {
    setState(() {
      _key = UniqueKey();
      // NOTE: _isSplashFinished remains true, forcing an immediate transition
      // to getIncompleteStepView() to re-check the logged-in status.
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: _key,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
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
        // Determine which screen to show based on the splash state
        home: _isSplashFinished 
            ? getIncompleteStepView() // Show the real app content after delay
            : const _SplashScreenContent(), // Show the custom splash screen content
      ),
    );
  }
}

/// A dedicated widget to display the content during the 2-second splash delay.
class _SplashScreenContent extends StatelessWidget {
  const _SplashScreenContent();

  @override
  Widget build(BuildContext context) {
    // This should match your native splash screen's appearance (usually white 
    // background with your icon centered) for a smooth transition.
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        // Placeholder for the main icon. 
        // Use Image.asset('assets/images/splash_icon.png') if you 
        // have a dedicated asset path for the icon.
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Example: Replace this with your actual app icon image widget
            Image.asset('assets/images/icon_splash.png', width: 100, height: 100),
            const SizedBox(height: 20),
            CircularProgressIndicator(color: Colors.deepPurple),
          ],
        ),
      ),
    );
  }
}

// Mock implementation of the function used in your original code:
// Widget getIncompleteStepView() {
//   // In a real app, this function checks LocalDB and returns the 
//   // appropriate widget (e.g., SignInScreen, ProfileSetupScreen, or Dashboard).
//   return const Text("This is the Final Destination Screen."); 
// }