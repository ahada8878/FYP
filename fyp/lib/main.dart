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

  void restartApp() {
    setState(() {
      _key = UniqueKey();
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
        home: getIncompleteStepView(),
      ),
    );
  }
}