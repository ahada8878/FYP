import 'package:flutter/material.dart';
import 'package:fyp/LocalDB.dart';
import 'package:fyp/MissingRouteDataForSignUp.dart';
import 'package:fyp/calorie_tracker_controller.dart';
import 'package:fyp/camera_overlay_controller.dart';
import 'package:fyp/water_tracker_controller.dart';
import 'package:provider/provider.dart';

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
  /// This allows other parts of the app to force a rebuild of the entire application,
  /// which is useful for events like logging out.
  static void restartApp(BuildContext context) {
    context.findAncestorStateOfType<_MyAppState>()?.restartApp();
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // A unique key that, when changed, forces the widget subtree to be rebuilt.
  Key _key = UniqueKey();

  /// Changes the key to trigger a rebuild of the widget tree.
  void restartApp() {
    setState(() {
      _key = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    // KeyedSubtree ensures that when the key changes, the entire MaterialApp
    // is disposed and recreated. This is crucial for re-evaluating the
    // authentication state after logout.
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
        // The home widget is determined by checking the user's registration progress.
        // This is re-evaluated every time the app is restarted.
        home: getIncompleteStepView(),
      ),
    );
  }
}