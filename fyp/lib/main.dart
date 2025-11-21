import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fyp/LocalDB.dart';
import 'package:fyp/MissingRouteDataForSignUp.dart';
import 'package:fyp/calorie_tracker_controller.dart';
import 'package:fyp/camera_overlay_controller.dart';
import 'package:fyp/water_tracker_controller.dart';
import 'package:provider/provider.dart';

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
  bool _isSplashFinished = false;

  @override
  void initState() {
    super.initState();

    // Splash delay
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isSplashFinished = true;
        });
      }
    });
  }

  void restartApp() {
    setState(() {
      _key = UniqueKey();
      _isSplashFinished = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: _key,
      child: MaterialApp(
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
        home: _isSplashFinished
            ? getIncompleteStepView()
            : const _SplashScreenContent(),
      ),
    );
  }
}

class _SplashScreenContent extends StatelessWidget {
  const _SplashScreenContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/icon_splash.png', width: 100, height: 100),
            const SizedBox(height: 20),
            const CircularProgressIndicator(color: Colors.deepPurple),
          ],
        ),
      ),
    );
  }
}