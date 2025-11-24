import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;
import 'package:flutter/services.dart';
import 'package:fyp/LocalDB.dart';
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
import 'package:fyp/services/meal_service.dart';
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
import 'package:fyp/services/food_log_service.dart';
import 'package:fyp/models/food_log.dart'; 

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

class ManualLogFoodSheet extends StatefulWidget {
  final Function(dynamic) onLog; 
  const ManualLogFoodSheet({Key? key, required this.onLog}) : super(key: key);

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
  final FoodLogService _foodLogService = FoodLogService();

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
      _showMealTypeDialog();
    }
  }

  void _showMealTypeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _MealTypeSelectorDialog(
          onMealSelected: (String selectedMealType) {
            _logToBackend(selectedMealType);
            Navigator.pop(context);
          },
        );
      },
    );
  }

  Future<void> _logToBackend(String mealType) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saving to food log...')),
    );
    try {
      final nutrients = {
        'calories': int.tryParse(_caloriesController.text) ?? 0,
        'carbohydrates': double.tryParse(_carbsController.text) ?? 0.0,
        'protein': double.tryParse(_proteinController.text) ?? 0.0,
        'fat': double.tryParse(_fatController.text) ?? 0.0,
      };

      final success = await _foodLogService.logFood(
        mealType: mealType,
        productName: _nameController.text.trim(),
        nutrients: nutrients,
        date: DateTime.now(),
        imageUrl: null, 
      );

      if (success) {
        if (mounted) {
          widget.onLog(true);
          Navigator.of(context).pop(); 
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Food logged successfully! 脂'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to log food. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                      decoration: inputDecoration(
                          'Food Name', Icons.restaurant_menu_rounded),
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
                      decoration: inputDecoration('Calories (kcal)',
                          Icons.local_fire_department_rounded),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null ||
                            int.tryParse(value) == null ||
                            int.parse(value) < 0) {
                          return 'Please enter a valid positive number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _carbsController,
                      decoration:
                          inputDecoration('Carbs (g)', Icons.grain_rounded),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _proteinController,
                      decoration: inputDecoration(
                          'Protein (g)', Icons.egg_alt_outlined),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _fatController,
                      decoration:
                          inputDecoration('Fat (g)', Icons.opacity_rounded),
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
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
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

class _MealTypeSelectorDialog extends StatefulWidget {
  final Function(String) onMealSelected;
  const _MealTypeSelectorDialog({Key? key, required this.onMealSelected})
      : super(key: key);

  @override
  State<_MealTypeSelectorDialog> createState() =>
      _MealTypeSelectorDialogState();
}

class _MealTypeSelectorDialogState extends State<_MealTypeSelectorDialog> {
  String? _selectedType;
  final List<String> _options = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Log as...',
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 8,
            children: _options.map((type) {
              final isSelected = _selectedType == type;
              return ChoiceChip(
                label: Text(type),
                selected: isSelected,
                selectedColor: Theme.of(context).colorScheme.primary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                onSelected: (selected) {
                  setState(() {
                    _selectedType = selected ? type : null;
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _selectedType == null
              ? null
              : () => widget.onMealSelected(_selectedType!),
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Log'),
        ),
      ],
    );
  }
}

// --- Data Models ---
class DailySummary {
  int caloriesGoal = 0;
  int caloriesConsumed = 0;
  double carbsGoal = 0, carbsConsumed = 0;
  double proteinGoal = 0, proteinConsumed = 0;
  double fatGoal = 0, fatConsumed = 0;
  int get caloriesRemaining => caloriesGoal - caloriesConsumed;
  double get calorieProgress =>
      caloriesGoal == 0 ? 0 : (caloriesConsumed / caloriesGoal).clamp(0.0, 1.0);
  double get carbProgress =>
      carbsGoal == 0 ? 0 : (carbsConsumed / carbsGoal).clamp(0.0, 1.0);
  double get proteinProgress =>
      proteinGoal == 0 ? 0 : (proteinConsumed / proteinGoal).clamp(0.0, 1.0);
  double get fatProgress =>
      fatGoal == 0 ? 0 : (fatConsumed / fatGoal).clamp(0.0, 1.0);
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
    required this.caloriesConsumed,
    this.carbsGoal = 310,
    required this.carbsConsumed,
    this.proteinGoal = 125,
    required this.proteinConsumed,
    this.fatGoal = 71,
    required this.fatConsumed,
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
  // FIX 1: Added the missing Future variable for TodayMealPlan
  late Future<TodayMealPlan> _todayMealsFuture;
  
  late AnimationController _headerAnimController;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  final ScrollController _scrollController = ScrollController();
  late final ScrollController _recipeScrollController;
  final AuthService _authService = AuthService();
  final FoodLogService _foodLogService = FoodLogService();

  List<Meal> _meals = [];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _userDataFuture = _fetchUserData();
    
    // FIX 2: Initialize the missing Future
    _todayMealsFuture = _fetchTodayMealPlan();

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

  // FIX 3: Added the missing fetch method for TodayMealPlan
Future<TodayMealPlan> _fetchTodayMealPlan() async {
    try {
      // 1. Fetch data from your existing service
      final Map<String, dynamic> data = await MealService.fetchUserMealPlan();
      
      // 2. Extract the list of meals safely
      final List<dynamic> mealsData = data['meals'] as List<dynamic>? ?? [];

      // 3. Helper function to map raw JSON to your MealPlanItem model
      MealPlanItem mapToItem(Map<String, dynamic> json) {
        // Safely extract calories (handling potential double/int differences)
        int calories = 0;
        if (json['nutrients'] != null && json['nutrients']['calories'] != null) {
          calories = (json['nutrients']['calories'] as num).toInt();
        } else if (json['calories'] != null) {
           calories = (json['calories'] as num).toInt();
        }

        // Construct image URL (using fallback logic similar to your other screens if image is missing)
        String imageUrl = json['image'] ?? 
            "https://spoonacular.com/recipeImages/${json['id']}-556x370.${json['imageType'] ?? 'jpg'}";

        return MealPlanItem(
          id: json['id'].toString(),
          title: json['title'] ?? 'Unknown Meal',
          calories: calories,
          imageUrl: imageUrl,
          // 'readyInMinutes' is a standard Spoonacular field for prep time
          prepTimeMinutes: json['readyInMinutes'] ?? 15, 
        );
      }

      // 4. Distribute meals into categories based on their index
      // Index 0 = Breakfast, Index 1 = Lunch, Index 2 = Dinner
      List<MealPlanItem> breakfast = [];
      List<MealPlanItem> lunch = [];
      List<MealPlanItem> dinner = [];

      if (mealsData.isNotEmpty) breakfast.add(mapToItem(mealsData[0]));
      if (mealsData.length > 1) lunch.add(mapToItem(mealsData[1]));
      if (mealsData.length > 2) dinner.add(mapToItem(mealsData[2]));

      // 5. Return the populated TodayMealPlan
      return TodayMealPlan(
        breakfast: breakfast,
        lunch: lunch,
        dinner: dinner,
      );

    } catch (e) {
      print("Error fetching today's meal plan: $e");
      // Return empty plan or handle error appropriately
      return TodayMealPlan(breakfast: [], lunch: [], dinner: []);
    }
  }
  
  // FIX 4: Added the missing navigation method
  void _navigateToMealDetails(MealPlanItem item) {
    // Replace with your actual detail screen or a dialog
    showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: Text(item.title),
        content: Text("Calories: ${item.calories}\nPrep time: ${item.prepTimeMinutes} mins"),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))],
      )
    );
  }

  Future<Map<String, dynamic>> _fetchUserData() async {
    final token = await _authService.getToken();
    
    if (token == null || token.isEmpty) {
      debugPrint('No token found. Using local data.');
      return _getLocalFallbackData();
    }

    try {
      final results = await Future.wait([
        http.get(
          Uri.parse('$baseURL/api/user/profile-summary'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
        _foodLogService.getFoodLogsForDate(DateTime.now())
      ]);

      final profileResponse = results[0] as http.Response;
      final foodLogs = results[1] as List<FoodLog>;

      if (profileResponse.statusCode == 200) {
        final profileData = json.decode(profileResponse.body);
        if (profileData['success'] == true) {
          
          LocalDB.setCarbs(profileData['carbs']);
          LocalDB.setProtein(profileData['protein']);
          LocalDB.setFats(profileData['fat']);
          LocalDB.setUserName(profileData['userName']);
          LocalDB.setGoalCalories(profileData['caloriesGoal']);
          LocalDB.setWaterGoal(profileData['waterGoal']);
          LocalDB.setWaterConsumed(profileData['waterConsumed']);

          List<Meal> processedMeals = [
            Meal(name: 'Breakfast', icon: Icons.breakfast_dining_rounded, goal: 600, loggedFoods: []),
            Meal(name: 'Lunch', icon: Icons.lunch_dining_rounded, goal: 800, loggedFoods: []),
            Meal(name: 'Dinner', icon: Icons.dinner_dining_rounded, goal: 800, loggedFoods: []),
            Meal(name: 'Snack', icon: Icons.cookie_outlined, goal: 300, loggedFoods: []), 
          ];

          int totalCaloriesConsumed = 0;
          double totalCarbs = 0;
          double totalProtein = 0;
          double totalFat = 0;

          for (var log in foodLogs) {
            totalCaloriesConsumed += log.nutrients.calories.toInt();
            totalCarbs += log.nutrients.carbohydrates;
            totalProtein += log.nutrients.protein;
            totalFat += log.nutrients.fat;

            final loggedFood = LoggedFood(
              name: log.productName, 
              icon: '･｣', 
              calories: log.nutrients.calories.toInt()
            );

            String targetMeal = log.mealType;
            if (targetMeal == 'Snack') targetMeal = 'Snack'; 
            
            final mealIndex = processedMeals.indexWhere((m) => m.name == targetMeal);
            if (mealIndex != -1) {
               List<LoggedFood> newFoods = List.from(processedMeals[mealIndex].loggedFoods);
               newFoods.add(loggedFood);
               
               processedMeals[mealIndex] = Meal(
                 name: processedMeals[mealIndex].name, 
                 icon: processedMeals[mealIndex].icon, 
                 goal: processedMeals[mealIndex].goal, 
                 loggedFoods: newFoods
               );
            }
          }
          
          LocalDB.setConsumedCalories(totalCaloriesConsumed);

          return {
            'userName': profileData['userName'] as String? ?? 'User',
            'caloriesGoal': profileData['caloriesGoal'] as int? ?? 2000,
            'caloriesConsumed': totalCaloriesConsumed,
            'carbsConsumed': totalCarbs,
            'proteinConsumed': totalProtein,
            'fatConsumed': totalFat,
            'carbsGoal': profileData['carbs'] as int? ?? 150,
            'proteinGoal': profileData['protein'] as int? ?? 80,
            'fatGoal': profileData['fat'] as int? ?? 45,
            'waterGoal': profileData['waterGoal'] as int? ?? 2000,
            'waterConsumed': profileData['waterConsumed'] as int? ?? 0,
            'processedMeals': processedMeals
          };
        }
      }
      return _getLocalFallbackData();
      
    } catch (e) {
      debugPrint("Error fetching user data: $e");
      return _getLocalFallbackData();
    }
  }

  Map<String, dynamic> _getLocalFallbackData() {
    return {
      'userName': LocalDB.getUserName() as String? ?? 'User',
      'caloriesGoal': LocalDB.getGoalCalories(),
      'caloriesConsumed': LocalDB.getConsumedCalories(),
      'carbsConsumed': 0.0,
      'proteinConsumed': 0.0,
      'fatConsumed': 0.0,
      'carbsGoal': LocalDB.getCarbs(),
      'proteinGoal': LocalDB.getProtein(),
      'fatGoal': LocalDB.getFats(),
      'processedMeals': [
          Meal(name: 'Breakfast', icon: Icons.breakfast_dining_rounded, goal: 600),
          Meal(name: 'Lunch', icon: Icons.lunch_dining_rounded, goal: 800),
          Meal(name: 'Dinner', icon: Icons.dinner_dining_rounded, goal: 800),
          Meal(name: 'Snack', icon: Icons.cookie_outlined, goal: 300),
      ]
    };
  }

  Future<void> _refreshData() async {
    setState(() {
      _userDataFuture = _fetchUserData();
      _todayMealsFuture = _fetchTodayMealPlan();
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

  void _handleLogFood(dynamic result) {
     _refreshData();
  }

  void _showManualLogSheet(BuildContext context, Meal meal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ManualLogFoodSheet(
        onLog: (result) {
          _handleLogFood(result);
        },
      ),
    );
  }

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
                  Navigator.pop(ctx); 
                  _showManualLogSheet(context, meal);
                },
              ),
              ListTile(
                leading: const Icon(Icons.qr_code_scanner_rounded),
                title: const Text('Scan Meal'),
                onTap: () {
                  Navigator.pop(ctx); 
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
                          snapshot.error.toString().replaceFirst("Exception: ", ""),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[700], fontSize: 16),
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

                _meals = fetchedData['processedMeals'] as List<Meal>;

                final summary = DailySummary(
                  caloriesGoal: caloriesGoal,
                  caloriesConsumed: (fetchedData['caloriesConsumed'] as int),
                  carbsConsumed: (fetchedData['carbsConsumed'] as num).toDouble(),
                  proteinConsumed: (fetchedData['proteinConsumed'] as num).toDouble(),
                  fatConsumed: (fetchedData['fatConsumed'] as num).toDouble(),
                  carbsGoal: (fetchedData['carbsGoal'] as num).toDouble(),
                  proteinGoal: (fetchedData['proteinGoal'] as num).toDouble(),
                  fatGoal: (fetchedData['fatGoal'] as num).toDouble(),
                );

                return RefreshIndicator(
                  onRefresh: _refreshData,
                  child: CustomScrollView(
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
                            _buildMealTimeline(fetchedData),
                            
                            const SizedBox(height: 30),
                            
                            const DailyStepsChartCard(),
                            
                            const SizedBox(height: 24),
                            _buildSectionHeader(context, 'Today\'s Meals'),
                            FutureBuilder<TodayMealPlan>(
                              future: _todayMealsFuture,
                              builder: (context, mealSnapshot) {
                                if (mealSnapshot.connectionState == ConnectionState.waiting) {
                                  return const SizedBox(
                                    height: 260,
                                    child: Center(child: CircularProgressIndicator()),
                                  );
                                }
                                if (mealSnapshot.hasError || !mealSnapshot.hasData) {
                                  return const SizedBox(
                                    height: 260,
                                    child: Center(child: Text('Failed to load meal plan')),
                                  );
                                }
                                final todayMealPlan = mealSnapshot.data!;
                                final List<MealPlanItem> allMeals = [
                                  ...todayMealPlan.breakfast,
                                  ...todayMealPlan.lunch,
                                  ...todayMealPlan.dinner,
                                  ...todayMealPlan.snacks,
                                ];
                                return _buildRecipeSection(
                                  scrollController: _recipeScrollController,
                                  meals: allMeals,
                                );
                              },
                            ),
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
                );
              }

              return const Center(child: Text("No data found for your profile."));
            },
          ),
          
          if (overlayController.showOverlay) _buildCameraPageOverlay(),
        ],
      ),
    );
  }

// ... (The rest of your helper widgets like _buildHeader, _buildMealTimeline etc. remain here)

  Widget _buildRecipeSection({
    required ScrollController scrollController,
    required List<MealPlanItem> meals,
  }) {
    const double cardWidth = 161;
    const double spacing = 18;

    return SizedBox(
      height: 260,
      child: ListView.builder(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: meals.length,
        padding: const EdgeInsets.symmetric(horizontal: spacing),
        itemBuilder: (context, index) {
          final meal = meals[index];
          return StaggeredAnimation(
            index: index + _meals.length + 2,
            child: Padding(
              padding: const EdgeInsets.only(right: spacing),
              child: _TiltableRecipeCard(
                onTap: () => _navigateToMealDetails(meal),
                child: SizedBox(
                  width: cardWidth,
                  child: Stack(fit: StackFit.expand, children: [
                    ClipRRect(
                        borderRadius: BorderRadius.circular(20.0),
                        child: CachedNetworkImage(
                            imageUrl: meal.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (c, u) =>
                                Container(color: Colors.grey[200]),
                            errorWidget: (c, u, e) => Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.broken_image)))),
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
                      child: Text(meal.title,
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

  // --- Kept but effectively unused if you bypass the overlay controller ---
  Widget _buildCameraPageOverlay() {
    final overlayController = Provider.of<CameraOverlayController>(context);
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      bottom: overlayController.showOverlay
          ? 0
          : -MediaQuery.of(context).size.height * 0.7,
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
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(30)),
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
                        Provider.of<CameraOverlayController>(context,
                                listen: false)
                            .hide();
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
                        Provider.of<CameraOverlayController>(context,
                                listen: false)
                            .hide();
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => const ActivityLogSheet(),
                        ).then((selectedActivity) {
                          if (selectedActivity != null) {
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
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
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
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
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

  // ... (Keeping _buildHeader, _buildSectionHeader, _buildMealTimeline, _buildQuickActions, and other widgets as they were)
  
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
                    'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%D%3D&auto=format&fit=crop&q=80&w=687',
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

  Widget _buildMealTimeline(Map<String, dynamic> fetchedData) {
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
          child: _CreativeTimelineHydrationItem(
          isLast: true,
          initialWaterGoal: fetchedData['waterGoal'] as int? ?? LocalDB.getWaterGoal(),
          initialWaterConsumed: fetchedData['waterConsumed'] as int? ?? LocalDB.getWaterConsumed(),
      )),
    );

    return Column(children: timelineItems);
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

} // End of _MealTrackingPageState

// --- ALL HELPER WIDGETS ---
// (Included from previous context for a complete file)

// Model for Step Analysis (Assuming this structure)
class StepAnalysis {
  final bool okData;
  final List<int> steps;

  StepAnalysis({required this.okData, required this.steps});

  factory StepAnalysis.fromJson(Map<String, dynamic> json) {
    // Ensure steps are parsed as int
    final List<dynamic> stepsData = json['steps'] ?? [];
    final List<int> parsedSteps = stepsData.map((s) => s as int? ?? 0).toList();
    
    return StepAnalysis(
      okData: json['OkData'] as bool? ?? false,
      steps: parsedSteps,
    );
  }
}

class DailyStepsChartCard extends StatefulWidget {
  const DailyStepsChartCard({super.key});

  @override
  State<DailyStepsChartCard> createState() => _DailyStepsChartCardState();
}

class _DailyStepsChartCardState extends State<DailyStepsChartCard> {
  late Future<StepAnalysis> _stepAnalysisFuture;
  final AuthService _authService = AuthService();

  // Color palette for the new dark card
  final Color darkYellow =
      const Color(0xFFFFA000); // Amber 700 (Used for achievement)
  final Color cardBackgroundColor =
      const Color(0xFF1A2E35); // Dark Teal/Blue
  final Color cardBackgroundGradientEnd =
      const Color(0xFF1A2E35); // Darker shade
  final Color progressTrackColor = Colors.white.withOpacity(0.1);
  final Color lightTextColor = Colors.white.withOpacity(0.8);
  final Color veryLightTextColor = Colors.white.withOpacity(0.4);

  final stepGoal = 10000.0; // The fixed goal

  @override
  void initState() {
    super.initState();
    _stepAnalysisFuture = _fetchStepAnalysis();
  }

  // UNCHANGED: Fetch logic for step data
  Future<StepAnalysis> _fetchStepAnalysis() async {
    final String apiUrl = '$baseURL/api/get_last_7days_steps';
    final token = await _authService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Authentication required for step data.');
    }

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonBody = json.decode(response.body);
        return StepAnalysis.fromJson(jsonBody);
      } else {
        // Fallback for failed API, keeping the existing structure
        print(
            'Step API failed with status ${response.statusCode}. Falling back to mock data.');
        final mockData = {
          'OkData': true,
          'steps': [8000, 12000, 9500, 10500, 7000, 11000, 10000]
        };
        return StepAnalysis.fromJson(mockData);
      }
    } catch (e) {
      // Fallback for network error
      print(
          'Network error for step data: ${e.toString()}. Falling back to mock data.');
      final mockData = {
        'OkData': true,
        'steps': [8000, 12000, 9500, 10500, 7000, 11000, 10000]
      };
      return StepAnalysis.fromJson(mockData);
    }
  }

  // --- NEW WIDGETS FOR CREATIVE UI ---

  // 1. The main dark container for all states (loading, error, success)
  Widget _buildDarkContainer({required Widget child}) {
    return StaggeredAnimation(
      index: 2, // Keeps its place in the page animation
      child: Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cardBackgroundColor, cardBackgroundGradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: -5,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: child,
      ),
    );
  }

  // 2. Custom Painter for the Radial "Speedometer"
  /* (MOVED b-SIDE b) */

  // 3. Vertical bar for the weekly chart
  Widget _buildVerticalBar({
    required String dayLabel,
    required int steps,
    required double goal,
    required double maxSteps, // Max steps in the week for scaling
    required Color color,
  }) {
    const double maxBarHeight = 80.0;
    final bool achieved = steps >= goal;
    // Ensure maxSteps is not zero to avoid division by zero
    final double barHeight = maxSteps > 0 ? (steps / maxSteps) * maxBarHeight : 0.0;
    final barColor =
        achieved ? color : Colors.white.withOpacity(0.6);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // The animated bar
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: barHeight),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (context, height, child) {
            return Container(
              width: 18,
              height: height,
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        // Day label
        Text(
          dayLabel,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: achieved ? Colors.white : veryLightTextColor,
          ),
        ),
      ],
    );
  }

  // 4. NEW: Dark-themed widget for when data is not available
  Widget _buildDataNotAvailable(BuildContext context, StepAnalysis? analysis) {
    final bool notEnoughData = analysis?.okData == false;
    final String title;
    final String message;
    final IconData icon;

    // Use light text colors for the dark card
    final Color color = Colors.white.withOpacity(0.7);

    if (notEnoughData) {
      title = 'Insufficient Data';
      message = 'Need 7 full days of step history to show your dashboard.';
      icon = Icons.calendar_today_rounded;
    } else {
      title = 'Data Unavailable';
      message =
          'Feature isn\'t available, Server issue. Please try again later.';
      icon = Icons.gpp_bad_rounded;
    }

    return Container(
      height: 300, // Give it a fixed height
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: color.withOpacity(0.6)),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 5. NEW: Rebuilt Chart UI with "Speedometer" and Vertical Bars
  Widget _buildChartUI(BuildContext context, List<int> dailySteps) {
    // 1. Calculate Averages and Status
    final int recentSteps = dailySteps.isNotEmpty ? dailySteps.last : 0; // Get the most recent day
    final double progress = (recentSteps / stepGoal).clamp(0.0, 1.0);
    // Find max steps for scaling the bar chart
    final double maxWeeklySteps = (dailySteps.isNotEmpty ? (dailySteps.reduce(math.max) * 1.1) : stepGoal);

    // Logic for dynamic day labels (Mon, Tue, etc.)
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final todayIndex = (DateTime.now().weekday - 1) % 7;

    List<String> chartDays = [];
    for (int i = 0; i < dailySteps.length; i++) {
      final dayOffset = (todayIndex - (dailySteps.length - 1) + i) % 7;
      final chartDayIndex = (dayOffset < 0 ? dayOffset + 7 : dayOffset);
      chartDays.add(days[chartDayIndex]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // --- HEADER ---
        Row(
          children: [
            Icon(Icons.directions_run_rounded, color: darkYellow, size: 28),
            const SizedBox(width: 10),
            Text(
              'Step Dashboard',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 50),

        // --- HERO SECTION: RADIAL "SPEEDOMETER" ---
        SizedBox(
          width: 200,
          height: 200,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: progress),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (context, animatedProgress, child) {
              return CustomPaint(
                painter: _StepRadialPainter(
                  progress: animatedProgress,
                  color: darkYellow,
                  trackColor: progressTrackColor,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20), // Offset for dial
                      Text(
                        '${recentSteps.toInt()}',
                        style: const TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '/ ${stepGoal.toInt()} steps',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: lightTextColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: recentSteps >= stepGoal
                              ? darkYellow.withOpacity(0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: recentSteps >= stepGoal
                                ? darkYellow
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          recentSteps >= stepGoal ? 'GOAL MET!' : 'Recent Day',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: recentSteps >= stepGoal
                                ? darkYellow
                                : lightTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 30),
        const Divider(height: 40, color: Colors.white24, thickness: 1),

        // --- VISUALIZATION: WEEKLY VERTICAL BARS ---
        Text(
          'Weekly Review',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: lightTextColor,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 110, // Fixed height for bars + labels
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: dailySteps.asMap().entries.map((entry) {
              final index = entry.key;
              final steps = entry.value;

              return _buildVerticalBar(
                dayLabel: chartDays.length > index ? chartDays[index] : '...',
                steps: steps,
                goal: stepGoal,
                maxSteps: maxWeeklySteps,
                color: darkYellow,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // --- Main Build Method (FutureBuilder) ---
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StepAnalysis>(
      future: _stepAnalysisFuture,
      builder: (context, snapshot) {
        // STATE 1: LOADING
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildDarkContainer(
            child: const SizedBox(
              height: 300, // Give it a fixed height
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFFFA000), // Use darkYellow
                  strokeWidth: 2.0,
                ),
              ),
            ),
          );
        }

        // STATE 2: ERROR or OK_DATA = FALSE
        if (snapshot.hasError || (snapshot.hasData && !snapshot.data!.okData)) {
          return _buildDarkContainer(
            child: _buildDataNotAvailable(context, snapshot.data),
          );
        }

        // STATE 3: SUCCESS
        if (snapshot.hasData && snapshot.data!.okData) {
           final dailySteps = snapshot.data!.steps;
           return _buildDarkContainer(
             child: _buildChartUI(context, dailySteps),
           );
        }

        // Fallback state
        return _buildDarkContainer(
          child: _buildDataNotAvailable(context, null),
        );
      },
    );
  }
}

class _StepRadialPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final Color color;
  final Color trackColor;

  _StepRadialPainter(
      {required this.progress,
      required this.color,
      required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    const double strokeWidth = 12.0;
    final Offset center = size.center(Offset.zero);
    final double radius = (size.width - strokeWidth) / 3;

    // Define the "speedometer" arcs
    const double startAngle = -math.pi * 0.85; // ~2 o'clock
    const double totalAngle = math.pi * 1.7; // ~10 o'clock

    // Paint for the background track
    final Paint trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Paint for the progress arc
    final Paint progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Draw the track
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      totalAngle,
      false,
      trackPaint,
    );

    // Draw the progress
    final double progressAngle = progress * totalAngle;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      progressAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _StepRadialPainter oldDelegate) => 
    oldDelegate.progress != progress ||
    oldDelegate.color != color ||
    oldDelegate.trackColor != trackColor;
}

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
  final int initialWaterGoal; 
  final int initialWaterConsumed;
  // NEW: Callback to signal parent page to refresh data

  const _CreativeTimelineHydrationItem({
    super.key, 
    this.isLast = false,
    required this.initialWaterGoal,
    required this.initialWaterConsumed,
  });
  @override
  State<_CreativeTimelineHydrationItem> createState() =>
      _CreativeTimelineHydrationItemState();
}

class _CreativeTimelineHydrationItemState
    extends State<_CreativeTimelineHydrationItem>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  
  // State variables for dynamic data
  late int _currentWaterMl;
  late int _goalWaterMl;
  
  // Dynamically calculated properties
  late int _servingSizeMl; // Calculated as 1/8th of the goal
  static const int _dropletCount = 8; // Constant number of visual icons

  late AnimationController _progressController;
  late ConfettiController _confettiController;
  
  @override
  void initState() {
    super.initState();
    
    _goalWaterMl = widget.initialWaterGoal; 
    LocalDB.setWaterGoal(_goalWaterMl);
    _currentWaterMl = widget.initialWaterConsumed;
    LocalDB.setWaterConsumed(_currentWaterMl);

    
    // FIX: Calculate serving size dynamically (1/8th of the goal)
    _servingSizeMl = (_goalWaterMl > 0 ? (_goalWaterMl / _dropletCount) : 250).round();
    
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 1));
    _progressController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _progressController.animateTo(_progress, curve: Curves.easeOutCubic);
  }

  @override
  void didUpdateWidget(covariant _CreativeTimelineHydrationItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update goal and consumed if the parent widget passes new values
    if (widget.initialWaterGoal != oldWidget.initialWaterGoal ||
        widget.initialWaterConsumed != oldWidget.initialWaterConsumed) {
        
        if (widget.initialWaterConsumed != _currentWaterMl || 
            widget.initialWaterGoal != _goalWaterMl) {
            
            setState(() {
                _goalWaterMl = widget.initialWaterGoal;
                _currentWaterMl = widget.initialWaterConsumed;
                _servingSizeMl = (_goalWaterMl > 0 ? (_goalWaterMl / _dropletCount) : 250).round();
                LocalDB.setWaterConsumed(_currentWaterMl);
                LocalDB.setWaterGoal(_goalWaterMl);

            });
            _progressController.animateTo(_progress, curve: Curves.easeOutCubic);
        }
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _updateWater(int changeType) async { // changeType is 1 for Add, -1 for Remove
    HapticFeedback.lightImpact();
    
    // Determine the actual mL amount and action
    final logAmount = changeType > 0 ? _servingSizeMl : -_servingSizeMl;
    final newAmount = (_currentWaterMl + logAmount).clamp(0, _goalWaterMl);

    if (newAmount != _currentWaterMl) {
        
        // 1. OPTIMISTIC UI UPDATE
        setState(() {
            _currentWaterMl = newAmount;
            LocalDB.setWaterConsumed(_currentWaterMl);

            if (_currentWaterMl == _goalWaterMl) {
                _confettiController.play();
            }
            _progressController.animateTo(_progress, curve: Curves.easeOutCubic);
        });
        

        
        // 3. SEND API REQUEST
        final token = await AuthService().getToken();
        if (token != null) {
            final body = json.encode({
                'newAmount': LocalDB.getWaterConsumed(),
            });
            
            try {
                final response = await http.post(
                    Uri.parse('$baseURL/api/user-details/my-profile/updateWaterConsumption'),
                    headers: {
                        'Content-Type': 'application/json',
                        'Authorization': 'Bearer $token',
                    },
                    body: body,
                );

                if (response.statusCode == 200) {
                } else {
                    debugPrint('Water update failed on server: ${response.statusCode}');
                }
            } catch (e) {
                debugPrint('Network error during water update: $e');
            }
        }
    }
  }

  double get _progress => _goalWaterMl > 0 ? _currentWaterMl / _goalWaterMl : 0.0;
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
                                onTap: () => _updateWater(1),
                                color: blueColor,
                                icon: Icons.add_circle_rounded,
                                label: 'Log Water')),
                        if (_currentWaterMl > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: InkWell(
                                onTap: () => _updateWater(-1),
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

// ... (The rest of your code up to _PlanProgressIndicator remains the same)

class _PlanProgressIndicator extends StatelessWidget {
  final int plannedDays;
  final int totalDays;
  const _PlanProgressIndicator({this.totalDays = 7, required this.plannedDays});

  // FIX: Use the plannedDays for progress calculation
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
                value: progress, // Uses the calculated progress
                strokeWidth: 4,
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white))),

        // FIX: Display plannedDays / totalDays (e.g., 2/7)
        Text('$plannedDays/$totalDays',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))
      ]));
}

class _MealPlanCard extends StatelessWidget {
  const _MealPlanCard();

  // Helper to determine the current day number (1=Monday, 7=Sunday)
  int _getCurrentDayOfWeek() {
    // Dart's DateTime.weekday returns 1 for Monday through 7 for Sunday.
    return DateTime.now().weekday;
  }

  @override
  Widget build(BuildContext context) {
    const String imageUrl =
        'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1780&q=80';
    final cardColor = Colors.teal;

    // Calculate the current day count to pass to the indicator
    final currentDay = _getCurrentDayOfWeek();

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
                              child: Column(
                                  // Removed const here to allow dynamic widget below
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
                                          const Column(
                                              // Added const back to static Column
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

                                          // FIX: Pass the dynamically calculated currentDay
                                          _PlanProgressIndicator(
                                              plannedDays: currentDay)
                                        ]),
                                    const _MealPlanCtaChip(
                                        accentColor: Colors.white)
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
  final int servingSizeMl; // Now dynamic value

  const _DropletProgressIndicator(
      {super.key,
      required this.dropletCount,
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
              
              // We want to show labels at the 4th (halfway) and 8th (full) segment marks
              final bool isMidpoint = (index + 1) == dropletCount ~/ 2; 
              final bool isFinalPoint = (index + 1) == dropletCount;
              final bool showLabel = isMidpoint || isFinalPoint;
              
              // The cumulative volume achieved up to this segment's end.
              final cumulativeVolume = (index + 1) * servingSizeMl;
              
              return Column(children: [
                Icon(Icons.water_drop_rounded,
                    color: color.withOpacity(0.2 + fillOpacity * 0.8),
                    size: 32),
                
                // FIX: Only show label for 4th and 8th segment (if 8 droplets)
                if (showLabel)
                  Text('${cumulativeVolume}ml', 
                      style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                
                // Keep space if no label is shown
                if (!showLabel) const SizedBox(height: 14) 
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
              // Removed: percent: widget.summary.carbsPercent
              ),
          const SizedBox(height: 12),
          _MacroLegend(
              color: Colors.lightBlue,
              label: 'Protein',
              grams: widget.summary.proteinConsumed,
              // Removed: percent: widget.summary.proteinPercent
              ),
          const SizedBox(height: 12),
          _MacroLegend(
              color: Colors.purple,
              label: 'Fat',
              grams: widget.summary.fatConsumed,
              // Removed: percent: widget.summary.fatPercent
              )
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
  // Removed: final double percent; // Removed the percentage field

  const _MacroLegend(
      {required this.color,
      required this.label,
      required this.grams,
      // Removed: required this.percent // Removed from constructor
      });

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
        
        // Only display the grams value
        Text('${grams.toInt()}g', style: TextStyle(color: Colors.grey[800])),
        
        // Removed the percentage display SizedBox completely
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
  final VoidCallback? onTap; // Added onTap support

  const _TiltableRecipeCard({required this.child, this.onTap});

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
              // Wrap the child in _InteractiveCard and pass the onTap
              child: _InteractiveCard(
                onTap: widget.onTap, 
                child: widget.child,
              ))));
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

// --- FIX 5: Add these missing Data Models at the end of the file ---

class MealPlanItem {
  final String id;
  final String title;
  final String imageUrl;
  final int calories;
  final int prepTimeMinutes;
  
  MealPlanItem({
    required this.id, 
    required this.title, 
    required this.imageUrl, 
    required this.calories, 
    required this.prepTimeMinutes
  });
}

class TodayMealPlan {
  final List<MealPlanItem> breakfast;
  final List<MealPlanItem> lunch;
  final List<MealPlanItem> dinner;
  final List<MealPlanItem> snacks;
  
  TodayMealPlan({
    this.breakfast = const [], 
    this.lunch = const [], 
    this.dinner = const [], 
    this.snacks = const []
  });
}


