import 'dart:async'; // Required for the Timer
import 'package:flutter/material.dart';
import 'package:fyp/LocalDB.dart';
import 'package:fyp/MissingRouteDataForSignUp.dart';
import 'package:fyp/calorie_tracker_controller.dart';
import 'package:fyp/camera_overlay_controller.dart';
import 'package:fyp/water_tracker_controller.dart';
import 'package:provider/provider.dart';

// ADD THIS IMPORT
import 'package:fyp/Loginpage.dart';

// ADD THIS GLOBAL KEY
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalDB.init();
  runApp(
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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static void restartApp(BuildContext context) {
    context.findAncestorStateOfType<_MyAppState>()?.restartApp();
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Key _key = UniqueKey();
  
  // NEW: State to track if the custom splash screen delay is over.
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
  void restartApp() {
    setState(() {
      _key = UniqueKey();
      // Reset splash state to false if you want the splash screen to show on restart
      _isSplashFinished = false; 
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: _key,
      child: MaterialApp(
        // ADD THIS LINE TO ATTACH THE KEY
        navigatorKey: navigatorKey,
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
            SizedBox(height: 20),
            CircularProgressIndicator(color: Colors.deepPurple),
          ],
        ),
      ),
    );
  }
}

// NOTE: Ensure your global function getIncompleteStepView() is defined somewhere, 
// and that LocalDB.init(), your controllers, and MissingRouteDataForSignUp are
// correctly implemented in their respective files.

// Mock implementation of the function used in your original code:
// Widget getIncompleteStepView() {
//   // In a real app, this function checks LocalDB and returns the 
//   // appropriate widget (e.g., SignInScreen, ProfileSetupScreen, or Dashboard).
//   return const Text("This is the Final Destination Screen."); 
// }
