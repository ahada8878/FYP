import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fyp/services/config_service.dart'; 
import 'package:fyp/services/food_log_service.dart';

// --- DATA MODEL ---
class NutritionData {
  final bool enoughData;
  final String foodName;
  final String category;
  final String calories;
  final String protein;
  final String carbs;
  final String fat;
  final String fiber;
  final String sugar;
  final String sodium;
  final String cholesterol;

  NutritionData({
    required this.enoughData,
    required this.foodName,
    required this.category,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.sugar,
    required this.sodium,
    required this.cholesterol,
  });

  factory NutritionData.fromJson(Map<String, dynamic> json) {
    return NutritionData(
      enoughData: (json['enoughData'] as bool?) ?? false,
      foodName: (json['food_name'] as String?) ?? 'Unknown Food',
      category: (json['category'] as String?) ?? 'N/A',
      calories: (json['calories'] as String?) ?? 'N/A',
      protein: (json['protein'] as String?) ?? 'N/A',
      carbs: (json['carbs'] as String?) ?? 'N/A',
      fat: (json['fat'] as String?) ?? 'N/A',
      fiber: (json['fiber'] as String?) ?? 'N/A',
      sugar: (json['sugar'] as String?) ?? 'N/A',
      sodium: (json['sodium'] as String?) ?? 'N/A',
      cholesterol: (json['cholesterol'] as String?) ?? 'N/A',
    );
  }
}

// --------------------------------------------------------------------------
// --- DESCRIBE MEAL SCREEN (MAIN PAGE) ---
// --------------------------------------------------------------------------

class DescribeMealScreen extends StatefulWidget {
  const DescribeMealScreen({super.key});

  @override
  State<DescribeMealScreen> createState() => _DescribeMealScreenState();
}

class _DescribeMealScreenState extends State<DescribeMealScreen> {
  final TextEditingController _foodNameController = TextEditingController();
  final TextEditingController _ingredientsController = TextEditingController();
  bool _isAnalyzeEnabled = false;
  bool _isAnalyzing = false;

  // NOTE: Assuming baseURL is defined in config_service.dart
  static const String _apiUrl = '$baseURL/api/get-nutrition-data';

  @override
  void initState() {
    super.initState();
    _foodNameController.addListener(_updateAnalyzeState);
    _ingredientsController.addListener(_updateAnalyzeState);
  }

  void _updateAnalyzeState() {
    setState(() {
      _isAnalyzeEnabled = _foodNameController.text.isNotEmpty &&
          _ingredientsController.text.isNotEmpty &&
          !_isAnalyzing;
    });
  }

  @override
  void dispose() {
    _foodNameController.dispose();
    _ingredientsController.dispose();
    super.dispose();
  }

  // --- API CALL FUNCTION ---
  Future<NutritionData> fetchNutritionData(String name, String description) async {
    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'name': name,
        'description': description,
      }),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

      if (jsonResponse.containsKey('error')) {
        throw Exception(jsonResponse['error']);
      }

      return NutritionData.fromJson(jsonResponse);
    } else {
      throw Exception(
          'Failed to load nutrition data. Status: ${response.statusCode}');
    }
  }

  // --- ANALYZE MEAL HANDLER ---
  void _analyzeMeal() async {
    setState(() {
      _isAnalyzing = true;
      _updateAnalyzeState();
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext loadingContext) => const AnalyzingMealDialog(),
    );

    try {
      final results = await fetchNutritionData(
        _foodNameController.text,
        _ingredientsController.text,
      );

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      await Future.delayed(const Duration(milliseconds: 100));

      if (mounted) {
        _showResultsDialog(results);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Uh oh! Analysis failed. Please check the server connection and try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _updateAnalyzeState();
        });
      }
    }
  }

  void _showResultsDialog(NutritionData data) {
    showDialog(
      context: context,
      builder: (context) {
        return NutritionResultsDialog(
          data: data,
          onLogPressed: () {
            Navigator.pop(context); 
            _showMealTypeDialog(data); 
          },
        );
      },
    );
  }

  void _showMealTypeDialog(NutritionData data) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return MealTypeSelectionDialog(
          data: data,
          onLog: (selectedMealType) {
            _logMealToDatabase(data, selectedMealType);
            Navigator.pop(dialogContext); 
          },
        );
      },
    );
  }

  void _logMealToDatabase(NutritionData data, String mealType) async {
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Logging "${data.foodName}" as $mealType...'),
        backgroundColor: primaryColor, // Using Theme Primary Color
      ),
    );

    final FoodLogService foodLogService = FoodLogService();

    double parseNutrient(String s) {
      try {
        return double.tryParse(s.split(' ')[0]) ?? 0.0;
      } catch (e) {
        return 0.0;
      }
    }

    final nutrientsMap = {
      'calories': parseNutrient(data.calories),
      'protein': parseNutrient(data.protein),
      'fat': parseNutrient(data.fat),
      'carbohydrates': parseNutrient(data.carbs),
    };

    bool success = await foodLogService.logFood(
      mealType: mealType,
      productName: data.foodName,
      nutrients: nutrientsMap,
      imageUrl: null, 
      date: DateTime.now(), 
    );

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar(); 
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Successfully logged "${data.foodName}"! 🎉'
              : 'Failed to log meal. Please try again.'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
      Navigator.pop(context); 
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access the primary color from the theme
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Describe Meal to AI',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Food Name Field
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FOOD NAME',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _foodNameController,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: 'e.g Chicken Caesar Salad',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Ingredients Field
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'INGREDIENTS (Include quantities for better accuracy)',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _ingredientsController,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      keyboardType: TextInputType.multiline,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        hintText:
                            'e.g., 200g chicken breast, 1 cup romaine lettuce, 1 tbsp olive oil...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Analyze Button
            SizedBox(
              width: double.infinity,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  // Updated Gradient to use Theme Primary Color
                  gradient: _isAnalyzeEnabled
                      ? LinearGradient(
                          colors: [
                            primaryColor.withOpacity(0.8),
                            primaryColor,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  boxShadow: _isAnalyzeEnabled
                      ? [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : null,
                ),
                child: ElevatedButton(
                  onPressed: _isAnalyzeEnabled ? _analyzeMeal : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _isAnalyzing ? 'MIXING NUTRIENTS...' : 'ANALYZE MEAL',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _isAnalyzeEnabled || _isAnalyzing
                          ? Colors.white
                          : Colors.grey[400],
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// --- Custom Widget for Loading Screen ---
class AnalyzingMealDialog extends StatelessWidget {
  const AnalyzingMealDialog({super.key});

  @override
  Widget build(BuildContext context) {
    // Access Primary Color
    final primaryColor = Theme.of(context).colorScheme.primary;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            // Use Primary Color
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
          ),
          const SizedBox(height: 16),
          const Text(
            'The AI Chef is calculating...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Analyzing every ingredient\'s nutritional DNA.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

// --- Custom Widget for Results Dialogue ---
class NutritionResultsDialog extends StatelessWidget {
  final NutritionData data;
  final VoidCallback onLogPressed;

  const NutritionResultsDialog({
    super.key,
    required this.data,
    required this.onLogPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Using Theme Primary Color
    final primaryColor = Theme.of(context).colorScheme.primary;
    final bool showDetailedResults = data.enoughData;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- 1. Creative Header ---
            Stack(
              children: [
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    // Gradient using Theme Primary Color
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        primaryColor.withOpacity(1),
                        primaryColor,
                      ],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.restaurant_menu_rounded, color: Colors.white70, size: 28),
                        const SizedBox(height: 8),
                        Text(
                          data.foodName,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        Text(
                          showDetailedResults ? "AI Analysis Complete" : "More Info Needed",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8),
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Close Button
                Positioned(
                  right: 8,
                  top: 8,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),

            // --- 2. Scrollable Body ---
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: showDetailedResults
                    ? Column(
                        children: [
                          // Calories Hero
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.orange.withOpacity(0.2)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.local_fire_department_rounded, 
                                  color: Colors.deepOrange, size: 32),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data.calories,
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.deepOrange,
                                      ),
                                    ),
                                    const Text(
                                      "TOTAL ENERGY",
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Macros Grid
                          Row(
                            children: [
                              _MacroCard(
                                label: "PROTEIN",
                                value: data.protein,
                                color: Colors.blue,
                                icon: Icons.fitness_center,
                              ),
                              const SizedBox(width: 12),
                              _MacroCard(
                                label: "CARBS",
                                value: data.carbs,
                                color: Colors.green,
                                icon: Icons.grain,
                              ),
                              const SizedBox(width: 12),
                              _MacroCard(
                                label: "FAT",
                                value: data.fat,
                                color: Colors.redAccent,
                                icon: Icons.opacity,
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 12),

                          // Micros List
                          _MicroRow(label: "Fiber", value: data.fiber),
                          _MicroRow(label: "Sugar", value: data.sugar),
                          _MicroRow(label: "Sodium", value: data.sodium),
                          _MicroRow(label: "Cholesterol", value: data.cholesterol),
                        ],
                      )
                    : _buildInsufficientDataMessage(),
              ),
            ),

            // --- 3. Footer Action ---
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: ElevatedButton(
                onPressed: showDetailedResults ? onLogPressed : () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  // Use Theme Primary Color
                  backgroundColor: showDetailedResults ? primaryColor : Colors.grey[400],
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  shadowColor: primaryColor.withOpacity(0.3),
                ),
                child: Text(
                  showDetailedResults ? "LOG MEAL" : "TRY AGAIN",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsufficientDataMessage() {
    return Column(
      children: [
        Icon(Icons.search_off_rounded, size: 60, color: Colors.grey[300]),
        const SizedBox(height: 16),
        const Text(
          "We couldn't analyze that.",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Text(
          "Please try adding specific quantities like '1 cup' or '100g' to help our AI chef.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _MacroCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _MacroCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: color.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MicroRow extends StatelessWidget {
  final String label;
  final String value;

  const _MicroRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    if (value == "N/A" || value == "0" || value == "0g") return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }
}

class MealTypeSelectionDialog extends StatefulWidget {
  final NutritionData data;
  final Function(String) onLog;

  const MealTypeSelectionDialog({
    super.key,
    required this.data,
    required this.onLog,
  });

  @override
  State<MealTypeSelectionDialog> createState() => _MealTypeSelectionDialogState();
}

class _MealTypeSelectionDialogState extends State<MealTypeSelectionDialog>
    with SingleTickerProviderStateMixin {
  String? _selectedMealType;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  final List<Map<String, dynamic>> _mealOptions = [
    {'label': 'Breakfast', 'icon': Icons.breakfast_dining_rounded},
    {'label': 'Lunch', 'icon': Icons.lunch_dining_rounded},
    {'label': 'Dinner', 'icon': Icons.dinner_dining_rounded},
    {'label': 'Snack', 'icon': Icons.cookie_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _controller.forward();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).unfocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use Theme Primary Color
    final primaryColor = Theme.of(context).colorScheme.primary;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 10,
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Log Meal As...',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Select a category for \"${widget.data.foodName}\"",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 24),
                
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.3,
                  ),
                  itemCount: _mealOptions.length,
                  itemBuilder: (context, index) {
                    final option = _mealOptions[index];
                    final isSelected = _selectedMealType == option['label'];
                    return _buildOptionCard(
                      option['label'],
                      option['icon'],
                      primaryColor,
                      isSelected,
                    );
                  },
                ),
                
                const SizedBox(height: 24),
                
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text("Cancel", style: TextStyle(color: Colors.grey[600])),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _selectedMealType == null
                            ? null
                            : () => widget.onLog(_selectedMealType!),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: _selectedMealType == null ? 0 : 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("Log It"),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard(String label, IconData icon, Color primaryColor, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _selectedMealType = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          // Use Primary Color for selected state
          color: isSelected ? primaryColor : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey[200]!,
            width: 2,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: primaryColor.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.white : primaryColor, size: 30),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }
}