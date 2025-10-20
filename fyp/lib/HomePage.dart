import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;
import 'package:flutter/services.dart';
import 'package:fyp/screens/Features/cravings_page.dart';
import 'package:fyp/screens/Features/label_scanner_page.dart';
import 'package:fyp/screens/Features/nutrition_tips_page.dart';
import 'package:fyp/screens/Features/recipe_suggestions.dart';
import 'package:fyp/screens/settings_screen.dart';
import 'package:fyp/screens/userMealPlanScreen.dart';
import 'package:fyp/screens/describe_meal_screen.dart';
import 'package:fyp/screens/ai_scanner_result_page.dart';
import 'package:fyp/screens/camera_screen.dart';
import 'package:fyp/services/config_service.dart';
import 'package:fyp/Widgets/log_water_overlay.dart';
import 'package:fyp/Widgets/activity_log_sheet.dart';
import 'package:intl/intl.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:confetti/confetti.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'camera_overlay_controller.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

// --- Service to handle fetching the auth token ---
class AuthService {
  static const String _tokenKey = 'auth_token';

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }
}

// --- Screen for scanning a meal ---
class ScanMealScreen extends StatelessWidget {
  const ScanMealScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan Meal")),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "This is where the meal scanning feature will be implemented.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ),
      ),
    );
  }
}

// --- UPDATED: Bottom sheet for manually logging food ---
class ManualLogFoodSheet extends StatefulWidget {
  final void Function(LoggedFood food) onLog;

  const ManualLogFoodSheet({super.key, required this.onLog});

  @override
  State<ManualLogFoodSheet> createState() => _ManualLogFoodSheetState();
}

class _ManualLogFoodSheetState extends State<ManualLogFoodSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _carbsController = TextEditingController();
  final _proteinController = TextEditingController();
  final _fatController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _carbsController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final newFood = LoggedFood(
        name: _nameController.text.trim(),
        // UPDATED: Use a single, generic emoji for all manually logged items
        icon: '🍴',
        calories: int.parse(_caloriesController.text),
      );

      widget.onLog(newFood);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Helper function for consistent input field styling
    InputDecoration inputDecoration(String label, IconData icon) {
      return InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        labelText: label,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.never,
      );
    }
 
    return Padding(
      // Adjust padding to avoid the keyboard
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      // Use SingleChildScrollView to prevent overflow when keyboard is visible
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle for the sheet
              Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Log Food Manually',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: inputDecoration('Food Name', Icons.restaurant_menu_rounded),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _caloriesController,
                      decoration: inputDecoration('Calories (kcal)', Icons.local_fire_department_rounded),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || int.tryParse(value) == null || int.parse(value) < 0) {
                          return 'Please enter a valid positive number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _carbsController,
                      decoration: inputDecoration('Carbs (g)', Icons.grain_rounded),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _proteinController,
                      decoration: inputDecoration('Protein (g)', Icons.egg_alt_outlined),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _fatController,
                      decoration: inputDecoration('Fat (g)', Icons.opacity_rounded),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Log Meal',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// class CameraScreen extends StatelessWidget {
//   const CameraScreen({super.key});
//   @override
//   Widget build(BuildContext context) => Scaffold(
//       appBar: AppBar(), body: const Center(child: Text("Camera Screen")));
// }

// --- Data Models ---
class DailySummary {
  final int caloriesGoal;
  final int caloriesConsumed;
  final double carbsGoal, carbsConsumed;
  final double proteinGoal, proteinConsumed;
  final double fatGoal, fatConsumed;
  int get caloriesRemaining => caloriesGoal - caloriesConsumed;
  double get calorieProgress =>
      caloriesGoal == 0 ? 0 : (caloriesConsumed / caloriesGoal).clamp(0.0, 1.0);
  double get carbProgress => carbsGoal == 0 ? 0 : (carbsConsumed / carbsGoal).clamp(0.0, 1.0);
  double get proteinProgress => proteinGoal == 0 ? 0 : (proteinConsumed / proteinGoal).clamp(0.0, 1.0);
  double get fatProgress => fatGoal == 0 ? 0 : (fatConsumed / fatGoal).clamp(0.0, 1.0);
  double get totalMacrosConsumed =>
      carbsConsumed + proteinConsumed + fatConsumed;
  double get carbsPercent =>
      totalMacrosConsumed == 0 ? 0 : carbsConsumed / totalMacrosConsumed;
  double get proteinPercent =>
      totalMacrosConsumed == 0 ? 0 : proteinConsumed / totalMacrosConsumed;
  double get fatPercent =>
      totalMacrosConsumed == 0 ? 0 : fatConsumed / totalMacrosConsumed;

  DailySummary({
    required this.caloriesGoal,
    this.caloriesConsumed = 1255,
    this.carbsGoal = 310,
    this.carbsConsumed = 150.0,
    this.proteinGoal = 125,
    this.proteinConsumed = 80.0,
    this.fatGoal = 83,
    this.fatConsumed = 45.0,
  });
}

class Meal {
  final String name;
  final IconData icon;
  final int goal;
  final List<LoggedFood> loggedFoods;
  int get consumed => loggedFoods.fold(0, (sum, item) => sum + item.calories);
  double get progress => goal == 0 ? 0.0 : (consumed / goal).clamp(0.0, 1.0);
  Meal(
      {required this.name,
      required this.icon,
      required this.goal,
      this.loggedFoods = const []});
}

class LoggedFood {
  final String name;
  final String icon;
  final int calories;
  LoggedFood({required this.name, required this.icon, required this.calories});
}

// --- Main Page Widget ---
class MealTrackingPage extends StatefulWidget {
  const MealTrackingPage({super.key});
  @override
  State<MealTrackingPage> createState() => _MealTrackingPageState();
}

class _MealTrackingPageState extends State<MealTrackingPage>
    with TickerProviderStateMixin {
  late Future<Map<String, dynamic>> _userDataFuture;
  late AnimationController _headerAnimController;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  final ScrollController _scrollController = ScrollController();
  late final ScrollController _recipeScrollController;
  final AuthService _authService = AuthService();

  late List<Meal> _meals;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _userDataFuture = _fetchUserData();

    _meals = [
      Meal(
          name: 'Breakfast',
          icon: Icons.breakfast_dining_rounded,
          goal: 600,
          loggedFoods: [
            LoggedFood(name: 'Oatmeal', icon: '🥣', calories: 350),
            LoggedFood(name: 'Banana', icon: '🍌', calories: 105),
            LoggedFood(name: 'Almonds', icon: '🥜', calories: 150),
          ]),
      Meal(
          name: 'Lunch',
          icon: Icons.lunch_dining_rounded,
          goal: 800,
          loggedFoods: [
            LoggedFood(name: 'Chicken Salad', icon: '🥗', calories: 450),
            LoggedFood(name: 'Apple', icon: '🍎', calories: 150),
          ]),
      Meal(name: 'Dinner', icon: Icons.dinner_dining_rounded, goal: 800),
      Meal(name: 'Snacks', icon: Icons.cookie_outlined, goal: 300),
    ];

    _headerAnimController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..forward();
    _recipeScrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_recipeScrollController.hasClients && mounted) {
        const double cardWidth = 160;
        const double spacing = 16;
        final screenWidth = MediaQuery.of(context).size.width;
        final double targetOffset =
            (cardWidth + spacing) - (screenWidth / 2) + (cardWidth / 2);
        _recipeScrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<Map<String, dynamic>> _fetchUserData() async {
    const String apiUrl = 'http://$apiIpAddress:5000/api/user/profile-summary';
    final token = await _authService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('You are not logged in. Please log in to continue.');
    }

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return {
            'userName': data['userName'] as String? ?? 'User',
            'caloriesGoal': data['caloriesGoal'] as int? ?? 2000,
          };
        } else {
          throw Exception('Failed to load user data: ${data['message']}');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Your session has expired. Please log in again.');
      } else {
        throw Exception(
            'Server error. Please try again later. (Code: ${response.statusCode})');
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
      throw Exception(
          'Could not connect to the server. Please check your network connection.');
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _userDataFuture = _fetchUserData();
    });
  }

  void _initAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

    Future<void> _openCameraScreen() async {
    Provider.of<CameraOverlayController>(context, listen: false).hide();
    final imagePath = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const CameraScreen()),
    );
    if (imagePath != null) {
      final imageFile = File(imagePath);
      _navigateToResultPage(imageFile, true);
    }
  }

  void _navigateToResultPage(File imageFile, bool fromCamera) {
    Provider.of<CameraOverlayController>(context, listen: false).hide();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AiScannerResultPage(
          imageFile: imageFile,
          fromCamera: fromCamera,
        ),
      ),
    );
  }


  @override
  void dispose() {
    _headerAnimController.dispose();
    _animationController.dispose();
    _scrollController.dispose();
    _recipeScrollController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  // --- Handle adding a new food item to a meal ---
  void _handleLogFood(Meal meal, LoggedFood newFood) {
    setState(() {
      final mealIndex = _meals.indexWhere((m) => m.name == meal.name);
      if (mealIndex != -1) {
        // Create a new list of foods by adding the new one
        final updatedFoods =
            List<LoggedFood>.from(_meals[mealIndex].loggedFoods)..add(newFood);

        // Create a new Meal instance with the updated list to trigger rebuild
        _meals[mealIndex] = Meal(
          name: _meals[mealIndex].name,
          icon: _meals[mealIndex].icon,
          goal: _meals[mealIndex].goal,
          loggedFoods: updatedFoods,
        );
      }
    });
  }

  // --- Show the manual food log bottom sheet ---
  void _showManualLogSheet(BuildContext context, Meal meal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ManualLogFoodSheet(
        onLog: (newFood) {
          _handleLogFood(meal, newFood);
        },
      ),
    );
  }

  // --- Show options for logging food ---
  void _showAddFoodOptions(BuildContext context, Meal meal) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.edit_note_rounded),
                title: const Text('Log Manually'),
                onTap: () {
                  Navigator.pop(ctx); // Close the options sheet
                  _showManualLogSheet(context, meal);
                },
              ),
              ListTile(
                leading: const Icon(Icons.qr_code_scanner_rounded),
                title: const Text('Scan Meal'),
                onTap: () {
                  Navigator.pop(ctx); // Close the options sheet
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ScanMealScreen()),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final overlayController = Provider.of<CameraOverlayController>(context);
    return Scaffold(
      body: Stack(
        children: [
          const _LivingAnimatedBackground(),
          FutureBuilder<Map<String, dynamic>>(
            future: _userDataFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            color: Colors.red.shade400, size: 60),
                        const SizedBox(height: 16),
                        Text(
                          "Failed to Load Data",
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error
                              .toString()
                              .replaceFirst("Exception: ", ""),
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(color: Colors.grey[700], fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text("Try Again"),
                          onPressed: _refreshData,
                        )
                      ],
                    ),
                  ),
                );
              }

              if (snapshot.hasData) {
                final fetchedData = snapshot.data!;
                final String userName = fetchedData['userName']!;
                final int caloriesGoal = fetchedData['caloriesGoal']!;
                final summary = DailySummary(caloriesGoal: caloriesGoal);

                return RefreshIndicator(
                  onRefresh: _refreshData,
                  child: Stack(
                    children: [
                      CustomScrollView(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics()),
                        slivers: [
                          _buildHeader(context, summary, userName),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
                            sliver: SliverList(
                              delegate: SliverChildListDelegate([
                                _buildSectionHeader(context, "Today's Timeline"),
                                _buildMealTimeline(),
                                const SizedBox(height: 24),
                                _buildSectionHeader(context, 'For You'),
                                _buildRecipeSection(
                                    scrollController: _recipeScrollController),
                                const SizedBox(height: 24),
                                const _DailyInsightCard(),
                                const SizedBox(height: 24),
                                _buildSectionHeader(context, 'Daily Breakdown'),
                                _MacroBreakdownCard(summary: summary),
                                const SizedBox(height: 24),
                                _buildSectionHeader(context, 'See Your Meal Plan'),
                                const _MealPlanCard(),
                                const SizedBox(height: 24),
                                _buildSectionHeader(context, 'Quick Actions'),
                                _buildQuickActions(),
                              ]),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }

              return const Center(
                  child: Text("No data found for your profile."));
            },
          ),
          if (overlayController.showOverlay) _buildCameraPageOverlay(),
        ],
      ),
    );
  }

  Widget _buildCameraPageOverlay() {
    final overlayController = Provider.of<CameraOverlayController>(context);
    // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('hehehaha')));
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      bottom: overlayController.showOverlay ? 0 : -MediaQuery.of(context).size.height * 0.7,
      left: 0,
      right: 0,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary,
                    colorScheme.primary.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'AI Scanner',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      overlayController.hide();
                      if (context.read<PersistentTabController>().index != 0) {
                        context.read<PersistentTabController>().index = 0;
                      }
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: ScannerPulseAnimation(
                child: Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        colorScheme.primary.withOpacity(0.3),
                        colorScheme.primary.withOpacity(0.1),
                      ],
                    ),
                    border: Border.all(
                      color: colorScheme.primary.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: AnimatedRotation(
                      duration: const Duration(seconds: 8),
                      turns: _animationController.value * 2,
                      child: Icon(
                        Icons.auto_awesome,
                        size: 40,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ListView(
                  children: [
                    AnimatedScannerButton(
                      icon: Icons.chat_bubble_outline,
                      text: 'Describe Meal to AI',
                      subtitle: 'Get nutritional analysis by description',
                      color: Colors.blue,
                      delay: 100,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DescribeMealScreen(),
                          ),
                        );
                      },
                    ),
                    AnimatedScannerButton(
                      icon: Icons.bookmark_border,
                      text: 'Saved Meals',
                      subtitle: 'Your frequently logged meals',
                      color: Colors.green,
                      delay: 200,
                      onTap: () {},
                    ),
                    AnimatedScannerButton(
                      icon: Icons.local_drink_outlined,
                      text: 'Log Water',
                      subtitle: 'Track your daily water intake',
                      color: Colors.lightBlue,
                      delay: 300,
                      onTap: () {
                        Provider.of<CameraOverlayController>(context, listen: false).hide();
                        showLogWaterOverlay(context);
                      },
                    ),
                    AnimatedScannerButton(
                      icon: Icons.monitor_weight_outlined,
                      text: 'Log Weight',
                      subtitle: 'Update your current weight',
                      color: Colors.orange,
                      delay: 400,
                      onTap: () {},
                    ),
                    AnimatedScannerButton(
                      icon: Icons.directions_run,
                      text: 'Log Activity',
                      subtitle: 'Add exercise or physical activity',
                      color: Colors.red,
                      delay: 500,
                      onTap: () {
                        Provider.of<CameraOverlayController>(context, listen: false).hide();
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => const ActivityLogSheet(),
                        ).then((selectedActivity) {
                          if (selectedActivity != null) {
                            // ignore: avoid_print
                            print('Logged activity: ${selectedActivity.name}');
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: _openCameraScreen,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 5,
                  shadowColor: colorScheme.primary.withOpacity(0.4),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.scanner, color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      'SCAN NOW',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  SliverAppBar _buildHeader(
      BuildContext context, DailySummary summary, String userName) {
    final String currentDate =
        DateFormat('MMMM d, yyyy').format(DateTime.now());

    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: ClipRRect(
          borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(40)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl:
                    'https://images.unsplash.com/photo-1498837167922-ddd27525d352?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1770&q=80',
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    Container(color: Colors.grey[300]),
                errorWidget: (context, url, error) =>
                    Container(color: Colors.grey[300]),
              ),
              Container(
                  decoration:
                      BoxDecoration(color: Colors.black.withOpacity(0.5))),
              AnimatedBuilder(
                animation: _scrollController,
                builder: (context, child) {
                  final offset = _scrollController.hasClients
                      ? _scrollController.offset
                      : 0;
                  return Transform.translate(
                      offset: Offset(0, offset * 0.5), child: child);
                },
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _AnimatedHeaderGreeting(
                            greeting: _getGreeting(), name: userName),
                        Text(currentDate,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 16)),
                        const Spacer(),
                        _TodaySummaryHeader(
                            summary: summary, animation: _headerAnimController),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined,
              color: Colors.white, size: 28),
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (context) => const SettingsScreen())),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return StaggeredAnimation(
      index: 0,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16, top: 8),
        child: Center(
            child: Text(title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold, color: Colors.grey[800]))),
      ),
    );
  }

  Widget _buildMealTimeline() {
    bool nextMealFound = false;
    final timelineItems = <Widget>[];

    for (int index = 0; index < _meals.length; index++) {
      final meal = _meals[index];
      bool isActive =
          !nextMealFound && meal.consumed > 0 && meal.progress < 1.0;
      if (!nextMealFound && meal.consumed == 0) {
        isActive = true;
      }
      if (isActive) {
        nextMealFound = true;
      }

      timelineItems.add(
        StaggeredAnimation(
          index: index + 1,
          child: _CreativeTimelineMealItem(
            meal: _meals[index],
            isFirst: index == 0,
            isLast: false,
            isActive: isActive,
            onAddFood: () => _showAddFoodOptions(context, _meals[index]),
          ),
        ),
      );
    }

    final waterIndex = _meals.length + 1;
    timelineItems.add(
      StaggeredAnimation(
          index: waterIndex,
          child: const _CreativeTimelineHydrationItem(isLast: true)),
    );

    return Column(children: timelineItems);
  }

  Widget _buildRecipeSection({required ScrollController scrollController}) {
    final recipes = [
      {
        'title': 'Avocado Salad',
        'image':
            'https://images.pexels.com/photos/1279330/pexels-photo-1279330.jpeg'
      },
      {
        'title': 'Grilled Salmon',
        'image':
            'https://images.pexels.com/photos/376464/pexels-photo-376464.jpeg'
      },
      {
        'title': 'Berry Smoothie',
        'image':
            'https://images.pexels.com/photos/2144112/pexels-photo-2144112.jpeg'
      },
    ];

    const double cardWidth = 161;
    const double spacing = 18;

    return SizedBox(
      height: 260,
      child: ListView.builder(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: recipes.length,
        padding: const EdgeInsets.symmetric(horizontal: spacing),
        itemBuilder: (context, index) {
          final recipe = recipes[index];
          return StaggeredAnimation(
            index: index + _meals.length + 2,
            child: Padding(
              padding: const EdgeInsets.only(right: spacing),
              child: _TiltableRecipeCard(
                child: SizedBox(
                  width: cardWidth,
                  child: Stack(fit: StackFit.expand, children: [
                    ClipRRect(
                        borderRadius: BorderRadius.circular(20.0),
                        child: CachedNetworkImage(
                            imageUrl: recipe['image'] as String,
                            fit: BoxFit.cover,
                            placeholder: (c, u) =>
                                Container(color: Colors.grey[200]))),
                    Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20.0),
                            gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.center,
                                colors: [
                                  Colors.black.withOpacity(0.8),
                                  Colors.transparent
                                ]))),
                    Positioned(
                      bottom: 12,
                      left: 12,
                      right: 12,
                      child: Text(recipe['title'] as String,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                    ),
                  ]),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {
        'icon': Icons.qr_code_scanner_rounded,
        'label': 'Label Scan',
        'subtitle': 'Nutrition info'
      },
      {
        'icon': Icons.search_rounded,
        'label': 'Craving?',
        'subtitle': 'Find healthy alternatives'
      },
      {
        'icon': Icons.lightbulb_outline_rounded,
        'label': 'Recipes',
        'subtitle': 'Get meal ideas'
      },
      {
        'icon': Icons.article_outlined,
        'label': 'Nutrition Tips',
        'subtitle': 'Learn something new'
      },
    ];

    final destinations = [
      const LabelScannerPage(),
      const CravingsPage(),
      const RecipeSuggestion(),
      const NutritionTipsPage(),
    ];

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1),
      itemCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final action = actions[index];
        return StaggeredAnimation(
          index: index,
          child: _QuickActionButton(
            icon: action['icon'] as IconData,
            label: action['label'] as String,
            subtitle: action['subtitle'] as String,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => destinations[index]),
              );
            },
          ),
        );
      },
    );
  }
}

// --- ALL HELPER WIDGETS ---

class AnimatedScannerButton extends StatefulWidget {
  final IconData icon;
  final String text;
  final String subtitle;
  final Color color;
  final int delay;
  final VoidCallback onTap;

  const AnimatedScannerButton({
    super.key,
    required this.icon,
    required this.text,
    required this.subtitle,
    required this.color,
    required this.delay,
    required this.onTap,
  });

  @override
  State<AnimatedScannerButton> createState() => _AnimatedScannerButtonState();
}

class _AnimatedScannerButtonState extends State<AnimatedScannerButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.5, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 50, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1, curve: Curves.easeOutBack),
      ),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.translate(
            offset: Offset(_slideAnimation.value, 0),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              widget.color.withOpacity(0.1),
              Colors.transparent,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  widget.color.withOpacity(0.3),
                  widget.color.withOpacity(0.1),
                ],
              ),
            ),
            child: Icon(widget.icon, color: widget.color),
          ),
          title: Text(
            widget.text,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            widget.subtitle,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: Colors.grey[400],
          ),
          onTap: widget.onTap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }
}

class ScannerPulseAnimation extends StatefulWidget {
  final Widget child;

  const ScannerPulseAnimation({super.key, required this.child});

  @override
  State<ScannerPulseAnimation> createState() => _ScannerPulseAnimationState();
}

class _ScannerPulseAnimationState extends State<ScannerPulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _LivingAnimatedBackground extends StatefulWidget {
  const _LivingAnimatedBackground();
  @override
  State<_LivingAnimatedBackground> createState() =>
      _LivingAnimatedBackgroundState();
}

class _LivingAnimatedBackgroundState extends State<_LivingAnimatedBackground>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 40))
          ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = [
      Color.lerp(
          const Color(0xffa8edea), const Color(0xfffed6e3), _controller.value)!,
      Color.lerp(
          const Color(0xfffed6e3), const Color(0xffa8edea), _controller.value)!,
    ];
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors))),
    );
  }
}

class _TodaySummaryHeader extends StatelessWidget {
  final DailySummary summary;
  final Animation<double> animation;
  const _TodaySummaryHeader({required this.summary, required this.animation});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Calories Remaining',
                    style: TextStyle(color: Colors.white70, fontSize: 16)),
                AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    final progress = CurvedAnimation(
                            parent: animation, curve: Curves.easeOutQuart)
                        .value;
                    return Text(
                        '${(summary.caloriesRemaining * progress).toInt()}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold));
                  },
                ),
              ],
            ),
            SizedBox(
              width: 80,
              height: 80,
              child: AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  final progress = CurvedAnimation(
                          parent: animation, curve: Curves.easeInOutCubic)
                      .value;
                  return CustomPaint(
                    painter: _CalorieRingPainter(
                        progress: progress * summary.calorieProgress,
                        color: Colors.white,
                        isGoalComplete: summary.calorieProgress >= 1.0),
                    child: Center(
                        child: Icon(
                            summary.calorieProgress >= 1.0
                                ? Icons.star_rounded
                                : Icons.local_fire_department_rounded,
                            color: summary.calorieProgress >= 1.0
                                ? Colors.amber
                                : Colors.white,
                            size: 32)),
                  );
                },
              ),
            )
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _MacroPill(
                label: 'Carbs',
                progress: summary.carbProgress,
                value: '${summary.carbsConsumed.toInt()}g',
                color: Colors.orange,
                animation: animation),
            _MacroPill(
                label: 'Protein',
                progress: summary.proteinProgress,
                value: '${summary.proteinConsumed.toInt()}g',
                color: Colors.lightBlue,
                animation: animation),
            _MacroPill(
                label: 'Fat',
                progress: summary.fatProgress,
                value: '${summary.fatConsumed.toInt()}g',
                color: Colors.purple,
                animation: animation),
          ],
        )
      ],
    );
  }
}

class _MacroPill extends StatelessWidget {
  final String label, value;
  final double progress;
  final Color color;
  final Animation<double> animation;
  const _MacroPill(
      {required this.label,
      required this.value,
      required this.progress,
      required this.color,
      required this.animation});
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final animValue =
            CurvedAnimation(parent: animation, curve: Curves.easeOut).value;
        return Column(
          children: [
            Text(label,
                style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w800,
                    fontSize: 12)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.2))),
              child: Text(
                  (double.tryParse(value.replaceAll('g', ''))! * animValue)
                          .toInt()
                          .toString() +
                      'g',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800)),
            ),
          ],
        );
      },
    );
  }
}

class _AnimatedHeaderGreeting extends StatelessWidget {
  final String greeting;
  final String name;
  const _AnimatedHeaderGreeting({required this.greeting, required this.name});
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: Colors.white70)),
                Text(name,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InteractiveCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool isActive;
  final EdgeInsetsGeometry padding;
  const _InteractiveCard(
      {required this.child,
      this.onTap,
      this.isActive = false,
      this.padding = EdgeInsets.zero});
  @override
  State<_InteractiveCard> createState() => _InteractiveCardState();
}

class _InteractiveCardState extends State<_InteractiveCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24.0),
            boxShadow: [
              BoxShadow(
                color: widget.isActive
                    ? primaryColor.withOpacity(0.2)
                    : Colors.black.withOpacity(0.07),
                blurRadius: 15,
                spreadRadius: widget.isActive ? 1 : -5,
                offset: const Offset(0, 5),
              )
            ],
          ),
          child: Container(
            padding: widget.padding,
            decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.85),
                    Colors.white.withOpacity(0.75)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24.0),
                border: Border.all(color: Colors.white.withOpacity(0.3))),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _CreativeTimelineMealItem extends StatefulWidget {
  final Meal meal;
  final bool isFirst;
  final bool isLast;
  final bool isActive;
  final VoidCallback onAddFood;
  const _CreativeTimelineMealItem(
      {required this.meal,
      this.isFirst = false,
      this.isLast = false,
      this.isActive = false,
      required this.onAddFood});
  @override
  State<_CreativeTimelineMealItem> createState() =>
      _CreativeTimelineMealItemState();
}

class _CreativeTimelineMealItemState extends State<_CreativeTimelineMealItem>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _shimmerController;
  late AnimationController _progressController;
  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _progressController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    if (widget.meal.progress > 0) {
      _progressController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant _CreativeTimelineMealItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.meal.progress < 1.0 && widget.meal.progress >= 1.0) {
      _shimmerController.forward(from: 0.0);
    }
    if (widget.meal.progress != oldWidget.meal.progress) {
      if (widget.meal.progress > 0) {
        _progressController.animateTo(widget.meal.progress,
            curve: Curves.easeOutCubic);
      } else if (widget.meal.progress == 0) {
        _progressController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isComplete = widget.meal.progress >= 1.0;
    final primaryColor = Theme.of(context).colorScheme.primary;

    Widget cardContent = _InteractiveCard(
      isActive: widget.isActive,
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _isExpanded = !_isExpanded);
      },
      padding: const EdgeInsets.all(16.0),
      child: RepaintBoundary(
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (isComplete ? Colors.green : primaryColor)
                          .withOpacity(0.2)),
                  child: Center(
                      child: isComplete
                          ? const Icon(Icons.check_circle,
                              color: Colors.green, size: 24)
                          : Icon(widget.meal.icon,
                              color: primaryColor, size: 20)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.meal.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF333333))),
                      const SizedBox(height: 8),
                      Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          Container(
                              height: 20,
                              decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(10))),
                          LayoutBuilder(builder: (context, constraints) {
                            return AnimatedBuilder(
                              animation: _progressController,
                              builder: (context, child) {
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeOutCubic,
                                  height: 20,
                                  width: constraints.maxWidth *
                                      widget.meal.progress,
                                  decoration: BoxDecoration(
                                      color: (isComplete
                                              ? Colors.green
                                              : primaryColor)
                                          .withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(10)),
                                );
                              },
                            );
                          }),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                                '${widget.meal.consumed} / ${widget.meal.goal} kcal',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(_isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[800]),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: SizedBox(
                height: _isExpanded ? null : 0,
                child: Column(
                  children: [
                    const Divider(height: 24, indent: 58),
                    ...widget.meal.loggedFoods.map((food) => ListTile(
                        dense: true,
                        leading: Text(food.icon,
                            style: const TextStyle(fontSize: 20)),
                        title: Text(food.name),
                        trailing: Text('${food.calories} kcal',
                            style: TextStyle(color: Colors.grey[800])))),
                    ListTile(
                      dense: true,
                      leading: Icon(Icons.add_circle_outline,
                          color: primaryColor, size: 24),
                      title: Text('Add Food',
                          style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold)),
                      onTap: widget.onAddFood,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topLeft,
      children: [
        Positioned(
          left: 28,
          top: widget.isFirst ? 32 : 0,
          bottom: widget.isLast ? null : -12,
          height: widget.isFirst ? null : (widget.isLast ? 32 : null),
          child: Container(width: 2.5, color: Colors.white.withOpacity(0.2)),
        ),
        AnimatedBuilder(
          animation: _shimmerController,
          builder: (context, child) {
            if (!_shimmerController.isAnimating) return child!;
            final alignment = Alignment.lerp(const Alignment(-1.5, 0),
                const Alignment(1.5, 0), _shimmerController.value)!;
            return ShaderMask(
              blendMode: BlendMode.srcATop,
              shaderCallback: (bounds) => LinearGradient(
                  begin: alignment,
                  end: const Alignment(5, 0),
                  colors: const [
                    Colors.transparent,
                    Colors.white70,
                    Colors.transparent
                  ],
                  stops: const [
                    0.4,
                    0.5,
                    0.6
                  ]).createShader(bounds),
              child: child,
            );
          },
          child: cardContent,
        ),
      ],
    );
  }
}

class _CreativeTimelineHydrationItem extends StatefulWidget {
  final bool isLast;
  const _CreativeTimelineHydrationItem({this.isLast = false});
  @override
  State<_CreativeTimelineHydrationItem> createState() =>
      _CreativeTimelineHydrationItemState();
}

class _CreativeTimelineHydrationItemState
    extends State<_CreativeTimelineHydrationItem>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  int _currentWaterMl = 1250;
  final int _goalWaterMl = 2000;
  final int _servingSizeMl = 250;
  late AnimationController _progressController;
  late ConfettiController _confettiController;
  static const int _dropletCount = 8;
  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 1));
    _progressController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _progressController.animateTo(_progress, curve: Curves.easeOutCubic);
  }

  @override
  void didUpdateWidget(covariant _CreativeTimelineHydrationItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    _progressController.animateTo(_progress, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _progressController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _updateWater(int change) {
    HapticFeedback.lightImpact();
    final newAmount = (_currentWaterMl + change).clamp(0, _goalWaterMl);
    if (newAmount != _currentWaterMl) {
      setState(() {
        _currentWaterMl = newAmount;
        if (_currentWaterMl == _goalWaterMl) {
          _confettiController.play();
        }
        _progressController.animateTo(_progress, curve: Curves.easeOutCubic);
      });
    }
  }

  double get _progress => _currentWaterMl / _goalWaterMl;
  bool get _isComplete => _progress >= 1.0;
  @override
  Widget build(BuildContext context) {
    final blueColor = Colors.lightBlue;
    Widget cardContent = _InteractiveCard(
        isActive: true,
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _isExpanded = !_isExpanded);
        },
        padding: const EdgeInsets.all(16.0),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              children: [
                Row(
                  children: [
                    Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: (_isComplete ? Colors.green : blueColor)
                                .withOpacity(0.2)),
                        child: Center(
                            child: Icon(Icons.water_drop_rounded,
                                color: _isComplete ? Colors.green : blueColor,
                                size: 20))),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Hydration Goal',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF333333))),
                          const SizedBox(height: 8),
                          Stack(
                            alignment: Alignment.centerLeft,
                            children: [
                              Container(
                                  height: 20,
                                  decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(10))),
                              LayoutBuilder(builder: (context, constraints) {
                                return AnimatedBuilder(
                                  animation: _progressController,
                                  builder: (context, child) {
                                    return AnimatedContainer(
                                      duration: Duration.zero,
                                      curve: Curves.easeOutCubic,
                                      height: 20,
                                      width: constraints.maxWidth *
                                          _progressController.value,
                                      decoration: BoxDecoration(
                                          color: (_isComplete
                                                  ? Colors.green
                                                  : blueColor)
                                              .withOpacity(1),
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                    );
                                  },
                                );
                              }),
                              Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  child: Text(
                                      '$_currentWaterMl / $_goalWaterMl ml',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold))),
                            ],
                          )
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(_isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.grey[800]),
                  ],
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: SizedBox(
                    height: _isExpanded ? null : 0,
                    child: Column(
                      children: [
                        const Divider(height: 24, indent: 58),
                        Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            child: _DropletProgressIndicator(
                                dropletCount: _dropletCount,
                                progressController: _progressController,
                                color: blueColor,
                                servingSizeMl: _servingSizeMl)),
                        const SizedBox(height: 24),
                        Center(
                            child: _LogActionButton(
                                servingSize: _servingSizeMl,
                                onTap: () => _updateWater(_servingSizeMl),
                                color: blueColor,
                                icon: Icons.add_circle_rounded,
                                label: 'Log Water')),
                        if (_currentWaterMl > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: InkWell(
                                onTap: () => _updateWater(-_servingSizeMl),
                                child: Text('Remove ${_servingSizeMl}ml',
                                    style: TextStyle(
                                        color: Colors.grey[600],
                                        decoration: TextDecoration.underline))),
                          ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                emissionFrequency: 0.5),
          ],
        ));
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topLeft,
      children: [
        Positioned(
            left: 28,
            top: 0,
            bottom: widget.isLast ? null : -12,
            height: widget.isLast ? null : null,
            child: Container(width: 2.5, color: Colors.white.withOpacity(0.2))),
        cardContent,
      ],
    );
  }
}

class _TiltableCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _TiltableCard({required this.child, this.onTap});
  @override
  Widget build(BuildContext context) => Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateX(0.02)
        ..rotateY(-0.02),
      alignment: FractionalOffset.center,
      child: _InteractiveCard(onTap: onTap, child: child));
}

class _PlanProgressIndicator extends StatelessWidget {
  final int plannedDays;
  final int totalDays;
  const _PlanProgressIndicator({this.totalDays = 7, required this.plannedDays});
  double get progress => plannedDays / totalDays;
  @override
  Widget build(BuildContext context) => SizedBox(
      width: 50,
      height: 50,
      child: Stack(alignment: Alignment.center, children: [
        SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 4,
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white))),
        Text('$plannedDays/$totalDays',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))
      ]));
}

class _MealPlanCard extends StatelessWidget {
  const _MealPlanCard();
  @override
  Widget build(BuildContext context) {
    const String imageUrl =
        'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1780&q=80';
    final cardColor = Colors.teal;
    return SizedBox(
        height: 200,
        child: StaggeredAnimation(
            index: 10,
            child: _TiltableCard(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const UserMealPlanScreen())),
                child: Stack(fit: StackFit.expand, children: [
                  ClipRRect(
                      borderRadius: BorderRadius.circular(24.0),
                      child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          color: cardColor.withOpacity(0.5),
                          colorBlendMode: BlendMode.colorBurn,
                          errorWidget: (context, error, stackTrace) =>
                              Container(color: cardColor.shade400))),
                  ClipRRect(
                      borderRadius: BorderRadius.circular(24.0),
                      child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                          child: Container(
                              decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.5)),
                                  borderRadius: BorderRadius.circular(24.0)),
                              padding: const EdgeInsets.all(24.0),
                              child: const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text('Weekly Nutrition',
                                                    style: TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w500)),
                                                SizedBox(height: 4),
                                                Text('Meal Plan Ready!',
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 26,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        letterSpacing: 0.5))
                                              ]),
                                          _PlanProgressIndicator(plannedDays: 0)
                                        ]),
                                    _MealPlanCtaChip(accentColor: Colors.white)
                                  ]))))
                ]))));
  }
}

class _MealPlanCtaChip extends StatelessWidget {
  final Color accentColor;
  const _MealPlanCtaChip({required this.accentColor});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
          color: accentColor,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                spreadRadius: 1)
          ]),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.fastfood_rounded, color: Colors.teal.shade700, size: 20),
        const SizedBox(width: 8),
        Text('Explore Your Week',
            style: TextStyle(
                color: Colors.teal.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 15))
      ]));
}

class _DropletProgressIndicator extends StatelessWidget {
  final int dropletCount;
  final AnimationController progressController;
  final Color color;
  final int servingSizeMl;
  const _DropletProgressIndicator(
      {required this.dropletCount,
      required this.progressController,
      required this.color,
      required this.servingSizeMl});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: progressController,
      builder: (context, child) {
        final currentDropletsFilled = progressController.value * dropletCount;
        return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(dropletCount, (index) {
              final fillOpacity =
                  (currentDropletsFilled - index).clamp(0.0, 1.0);
              return Column(children: [
                Icon(Icons.water_drop_rounded,
                    color: color.withOpacity(0.2 + fillOpacity * 0.8),
                    size: 32),
                if (index % 2 == 0)
                  Text('${(index + 1) * servingSizeMl}ml',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                if (index % 2 != 0) const SizedBox(height: 14)
              ]);
            }));
      });
}

class _LogActionButton extends StatelessWidget {
  final int servingSize;
  final VoidCallback onTap;
  final Color color;
  final IconData icon;
  final String label;
  const _LogActionButton(
      {required this.servingSize,
      required this.onTap,
      required this.color,
      required this.icon,
      required this.label});
  @override
  Widget build(BuildContext context) => InkWell(
      onTap: onTap,
      child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 10,
                    spreadRadius: 2)
              ]),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: Colors.white, size: 40),
            const SizedBox(height: 4),
            Text('${label}',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
            Text('+${servingSize}ml',
                style: const TextStyle(color: Colors.white70, fontSize: 12))
          ])));
}

class _InteractiveWaterBottleTracker extends StatefulWidget {
  const _InteractiveWaterBottleTracker();
  @override
  State<_InteractiveWaterBottleTracker> createState() =>
      _InteractiveWaterBottleTrackerState();
}

class _InteractiveWaterBottleTrackerState
    extends State<_InteractiveWaterBottleTracker>
    with TickerProviderStateMixin {
  int _currentWaterMl = 1250;
  final int _goalWaterMl = 2000;
  final int _servingSizeMl = 250;
  late AnimationController _fillController;
  late Animation<double> _fillAnimation;
  late AnimationController _waveController;
  late ConfettiController _confettiController;
  double _tilt = 0.0;
  @override
  void initState() {
    super.initState();
    _waveController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 1));
    _fillController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fillAnimation =
        Tween<double>(begin: 0, end: _currentWaterMl / _goalWaterMl).animate(
            CurvedAnimation(parent: _fillController, curve: Curves.elasticOut));
    _fillController.forward();
    accelerometerEvents.listen((AccelerometerEvent event) {
      if (mounted) {
        setState(() => _tilt = (event.x / 10).clamp(-0.4, 0.4));
      }
    });
  }

  void _updateWater(int change) {}
  @override
  void dispose() {
    _fillController.dispose();
    _waveController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container();
}

class _WaterControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _WaterControlButton({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              child:
                  Icon(icon, color: Theme.of(context).colorScheme.primary))));
}

class _WaterBottlePainter extends CustomPainter {
  final double progress;
  final Animation<double> waveAnimation;
  final double tilt;
  _WaterBottlePainter(
      {required this.progress, required this.waveAnimation, required this.tilt})
      : super(repaint: waveAnimation);
  @override
  void paint(Canvas canvas, Size size) {
    final neckWidth = size.width * 0.4;
    final neckHeight = size.height * 0.15;
    final bodyWidth = size.width;
    final bodyHeight = size.height - neckHeight;
    final bottlePath = Path()
      ..moveTo((bodyWidth - neckWidth) / 2, neckHeight)
      ..lineTo((bodyWidth + neckWidth) / 2, neckHeight)
      ..lineTo((bodyWidth + neckWidth) / 2, 0)
      ..lineTo((bodyWidth - neckWidth) / 2, 0)
      ..lineTo((bodyWidth - neckWidth) / 2, neckHeight)
      ..cubicTo(0, neckHeight, 0, neckHeight + bodyHeight * 0.2, 0,
          neckHeight + bodyHeight * 0.5)
      ..lineTo(0, size.height)
      ..lineTo(bodyWidth, size.height)
      ..lineTo(bodyWidth, neckHeight + bodyHeight * 0.5)
      ..cubicTo(bodyWidth, neckHeight + bodyHeight * 0.2, bodyWidth, neckHeight,
          (bodyWidth + neckWidth) / 2, neckHeight);
    final bodyPaint = Paint()
      ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.25),
            Colors.white.withOpacity(0.9)
          ],
          stops: const [
            0.0,
            1.0
          ]).createShader(Offset.zero & size);
    canvas.drawPath(bottlePath, bodyPaint);
    final borderPaint = Paint()
      ..color = const Color.fromARGB(0, 39, 19, 19).withOpacity(0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(bottlePath, borderPaint);
    canvas.clipPath(bottlePath);
    if (progress > 0) {
      final waterLevel = size.height * (1.0 - progress);
      final waterPath = Path();
      final startPoint =
          Offset(-size.width * 0.5, waterLevel + size.height * tilt);
      final endPoint =
          Offset(size.width * 1.5, waterLevel - size.height * tilt);
      waterPath.moveTo(startPoint.dx, startPoint.dy);
      for (double x = -size.width * 0.5; x <= size.width * 1.5; x++) {
        final yLerp = lerpDouble(startPoint.dy, endPoint.dy,
            (x + size.width * 0.5) / (size.width * 2))!;
        final waveHeight = math.sin((x / (size.width * 0.5)) * 2 * math.pi +
                (waveAnimation.value * 2 * math.pi)) *
            4 *
            progress;
        waterPath.lineTo(x, yLerp + waveHeight);
      }
      waterPath.lineTo(size.width, size.height);
      waterPath.lineTo(0, size.height);
      waterPath.close();
      final waterPaint = Paint()
        ..shader = const LinearGradient(colors: [
          Color.fromARGB(148, 55, 170, 253),
          Color.fromARGB(148, 55, 170, 253)
        ], begin: Alignment.topCenter, end: Alignment.bottomCenter)
            .createShader(Rect.fromLTWH(
                0, waterLevel, size.width, size.height - waterLevel));
      canvas.drawPath(waterPath, waterPaint);
    }
    final markingPaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..strokeWidth = 1.5;
    for (int i = 1; i <= 3; i++) {
      final y = size.height * (1 - (i * 0.25));
      canvas.drawLine(
          Offset(size.width * 0.9, y), Offset(size.width, y), markingPaint);
    }
    canvas.restore();
    final highlightPath = Path()
      ..moveTo(size.width * 0.2, neckHeight)
      ..quadraticBezierTo(size.width * 0.1, size.height * 0.5, size.width * 0.3,
          size.height * 0.9);
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(highlightPath, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant _WaterBottlePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.tilt != tilt;
}

class _MacroBreakdownCard extends StatefulWidget {
  final DailySummary summary;
  const _MacroBreakdownCard({required this.summary});
  @override
  State<_MacroBreakdownCard> createState() => _MacroBreakdownCardState();
}

class _MacroBreakdownCardState extends State<_MacroBreakdownCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _InteractiveCard(
      padding: const EdgeInsets.all(16.0),
      child: Row(children: [
        SizedBox(
            width: 120,
            height: 120,
            child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) => CustomPaint(
                    painter: _MacroRingsPainter(
                        animation: _controller,
                        carbsPercent: widget.summary.carbsPercent,
                        proteinPercent: widget.summary.proteinPercent,
                        fatPercent: widget.summary.fatPercent),
                    child: const Center(
                        child: Text('Macros',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF333333))))))),
        const SizedBox(width: 24),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _MacroLegend(
              color: Colors.orange,
              label: 'Carbs',
              grams: widget.summary.carbsConsumed,
              percent: widget.summary.carbsPercent),
          const SizedBox(height: 12),
          _MacroLegend(
              color: Colors.lightBlue,
              label: 'Protein',
              grams: widget.summary.proteinConsumed,
              percent: widget.summary.proteinPercent),
          const SizedBox(height: 12),
          _MacroLegend(
              color: Colors.purple,
              label: 'Fat',
              grams: widget.summary.fatConsumed,
              percent: widget.summary.fatPercent)
        ]))
      ]));
}

class _MacroRingsPainter extends CustomPainter {
  final Animation<double> animation;
  final double carbsPercent;
  final double proteinPercent;
  final double fatPercent;
  _MacroRingsPainter(
      {required this.animation,
      required this.carbsPercent,
      required this.proteinPercent,
      required this.fatPercent})
      : super(repaint: animation);
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final strokeWidth = 10.0;
    final progress = Curves.easeOut.transform(animation.value);
    void drawArc(double percent, Color color, double radius) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      final backgroundPaint = Paint()
        ..color = color.withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
          -math.pi / 2, 2 * math.pi, false, backgroundPaint);
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
          -math.pi / 2, 2 * math.pi * percent * progress, false, paint);
    }

    drawArc(carbsPercent, Colors.orange, size.width / 2 - strokeWidth * 0.5);
    drawArc(
        proteinPercent, Colors.lightBlue, size.width / 2 - strokeWidth * 1.8);
    drawArc(fatPercent, Colors.purple, size.width / 2 - strokeWidth * 3.1);
  }

  @override
  bool shouldRepaint(covariant _MacroRingsPainter oldDelegate) => true;
}

class _MacroLegend extends StatelessWidget {
  final Color color;
  final String label;
  final double grams;
  final double percent;
  const _MacroLegend(
      {required this.color,
      required this.label,
      required this.grams,
      required this.percent});
  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Color(0xFF333333))),
        const Spacer(),
        Text('${grams.toInt()}g', style: TextStyle(color: Colors.grey[800])),
        const SizedBox(width: 8),
        SizedBox(
            width: 40,
            child: Text('${(percent * 100).toInt()}%',
                textAlign: TextAlign.right,
                style: TextStyle(fontWeight: FontWeight.bold, color: color)))
      ]);
}

class _DailyInsightCard extends StatefulWidget {
  const _DailyInsightCard();
  @override
  State<_DailyInsightCard> createState() => _DailyInsightCardState();
}

class _DailyInsightCardState extends State<_DailyInsightCard> {
  late String _insight;
  static const List<String> _insights = [
    "Staying hydrated can boost your metabolism by up to 30%.",
    "Protein is essential for muscle repair and growth. Aim for a source with every meal.",
    "Healthy fats from avocados and nuts are crucial for brain health.",
    "A colorful plate is a healthy plate! Different colors indicate different nutrients.",
    "Getting 7-9 hours of sleep is as important for your health as diet and exercise."
  ];
  @override
  void initState() {
    super.initState();
    _insight = _insights[math.Random().nextInt(_insights.length)];
  }

  @override
  Widget build(BuildContext context) => _InteractiveCard(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        Icon(Icons.lightbulb_outline_rounded,
            color: Colors.amber[800], size: 32),
        const SizedBox(width: 16),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Daily Insight',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF333333))),
          const SizedBox(height: 4),
          Text(_insight,
              style: TextStyle(color: Colors.grey[800], fontSize: 14))
        ]))
      ]));
}

class _TiltableRecipeCard extends StatefulWidget {
  final Widget child;
  const _TiltableRecipeCard({required this.child});
  @override
  State<_TiltableRecipeCard> createState() => _TiltableRecipeCardState();
}

class _TiltableRecipeCardState extends State<_TiltableRecipeCard> {
  double _tiltX = 0;
  double _tiltY = 0;
  @override
  void initState() {
    super.initState();
    gyroscopeEvents.listen((GyroscopeEvent event) {
      if (mounted) {
        setState(() {
          _tiltX += event.y * 0.03;
          _tiltY += event.x * 0.03;
          _tiltX = _tiltX.clamp(-0.2, 0.2);
          _tiltY = _tiltY.clamp(-0.2, 0.2);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder(
      tween: Tween<double>(begin: _tiltX, end: _tiltX),
      duration: const Duration(milliseconds: 100),
      builder: (context, double tiltX, child) => TweenAnimationBuilder(
          tween: Tween<double>(begin: _tiltY, end: _tiltY),
          duration: const Duration(milliseconds: 100),
          builder: (context, double tiltY, child) => Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateX(tiltX)
                ..rotateY(-tiltY),
              alignment: FractionalOffset.center,
              child: _InteractiveCard(child: widget.child))));
}

class _CalorieRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isGoalComplete;
  _CalorieRingPainter(
      {required this.progress,
      required this.color,
      this.isGoalComplete = false});
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: size.width / 2);
    final backgroundPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    final progressPaint = Paint()
      ..shader = SweepGradient(
              colors: [color.withOpacity(0.5), color],
              transform: const GradientRotation(-math.pi / 2))
          .createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi, false, backgroundPaint);
    canvas.drawArc(
        rect, -math.pi / 2, 2 * math.pi * progress, false, progressPaint);
    if (isGoalComplete) {
      final glowPaint = Paint()
        ..color = Colors.amberAccent.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawArc(
          rect, -math.pi / 2, 2 * math.pi * progress, false, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CalorieRingPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      isGoalComplete != oldDelegate.isGoalComplete;
}

class StaggeredAnimation extends StatefulWidget {
  final Widget child;
  final int index;
  const StaggeredAnimation(
      {super.key, required this.child, required this.index});
  @override
  State<StaggeredAnimation> createState() => _StaggeredAnimationState();
}

class _StaggeredAnimationState extends State<StaggeredAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    final delay = (widget.index * 80).clamp(0, 400);
    _opacity = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _slide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child));
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  const _QuickActionButton(
      {required this.icon,
      required this.label,
      required this.subtitle,
      required this.onTap});
  @override
  Widget build(BuildContext context) => _InteractiveCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF333333))),
            const SizedBox(height: 4),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[800]))
          ]));
}