import 'package:flutter/material.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:lottie/lottie.dart';
import 'dart:convert';
import '../services/config_service.dart';
import 'dart:async';
import 'package:fyp/services/food_log_service.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ✅ Add this

class AiScannerResultPage extends StatefulWidget {
  final File imageFile;
  final bool fromCamera;

  const AiScannerResultPage({
    super.key,
    required this.imageFile,
    required this.fromCamera,
  });

  @override
  State<AiScannerResultPage> createState() => _AiScannerResultPageState();
}

class _AiScannerResultPageState extends State<AiScannerResultPage> {
  String _message = "Analyzing...";
  bool _isProcessing = true;
  bool _isEstimatingWeight = false;
  bool _isLoading = false;
  bool _hasError = false;
  String? _smartPortionRecommendation;

  // --- INGREDIENT VARIABLES ---
  List<String> _baseIngredientsRaw = [];
  
  // NEW: Track removed base ingredients so they don't reappear
  final Set<String> _removedBaseIngredients = {}; 
  
  List<Map<String, dynamic>> _displayIngredientsList = []; // Changed to List<Map> for easier tap handling
  List<Map<String, dynamic>> _manualIngredients = [];
  bool _showIngredients = false;

  // --- MANUAL INPUTS ---
  final TextEditingController _manualWeightController = TextEditingController();
  String _selectedManualIngredient = "";
  TextEditingController? _autocompleteController;

  // --- LOCAL NUTRITION DATABASE (Per 50g) ---
  final Map<String, Map<String, double>> _ingredientDatabase = {
    // FLOURS & GRAINS
    "All-Purpose Flour": {"cal": 182, "pro": 5.0, "fat": 0.5, "carb": 38.0},
    "Almond Flour": {"cal": 290, "pro": 10.5, "fat": 25.0, "carb": 10.0},
    "Whole Wheat Flour": {"cal": 170, "pro": 6.5, "fat": 1.0, "carb": 36.0},
    "Oat Flour": {"cal": 202, "pro": 7.0, "fat": 4.5, "carb": 33.0},
    "Rice (White, Cooked)": {"cal": 65, "pro": 1.3, "fat": 0.1, "carb": 14.0},
    "Rice (Brown, Cooked)": {"cal": 55, "pro": 1.1, "fat": 0.4, "carb": 11.5},
    "Quinoa (Cooked)": {"cal": 60, "pro": 2.2, "fat": 1.0, "carb": 10.5},
    "Pasta (White, Cooked)": {"cal": 79, "pro": 2.9, "fat": 0.5, "carb": 15.5},
    "Noodles (Rice, Cooked)": {"cal": 54, "pro": 0.9, "fat": 0.1, "carb": 12.0},
    "Bread (White)": {"cal": 133, "pro": 4.5, "fat": 1.5, "carb": 24.5},
    "Bread (Whole Wheat)": {"cal": 123, "pro": 6.0, "fat": 2.0, "carb": 21.5},
    "Tortilla (Flour)": {"cal": 150, "pro": 4.0, "fat": 3.5, "carb": 25.0},
    "Tortilla (Corn)": {"cal": 109, "pro": 2.9, "fat": 1.4, "carb": 23.0},
    "Pie Crust": {"cal": 225, "pro": 3.0, "fat": 14.0, "carb": 22.5},
    "Phyllo Dough": {"cal": 145, "pro": 3.5, "fat": 3.0, "carb": 26.5},
    "Puff Pastry": {"cal": 279, "pro": 3.5, "fat": 19.0, "carb": 23.0},
    // SUGARS & SWEETENERS
    "Sugar (White)": {"cal": 194, "pro": 0.0, "fat": 0.0, "carb": 50.0},
    "Brown Sugar": {"cal": 190, "pro": 0.0, "fat": 0.0, "carb": 49.0},
    "Powdered Sugar": {"cal": 195, "pro": 0.0, "fat": 0.0, "carb": 49.8},
    "Honey": {"cal": 152, "pro": 0.1, "fat": 0.0, "carb": 41.0},
    "Maple Syrup": {"cal": 130, "pro": 0.0, "fat": 0.0, "carb": 33.5},
    "Chocolate (Dark)": {"cal": 273, "pro": 2.5, "fat": 15.5, "carb": 30.5},
    "Cocoa Powder": {"cal": 114, "pro": 9.8, "fat": 6.9, "carb": 29.0},
    // FATS & OILS
    "Butter": {"cal": 358, "pro": 0.4, "fat": 40.5, "carb": 0.0},
    "Olive Oil": {"cal": 442, "pro": 0.0, "fat": 50.0, "carb": 0.0},
    "Vegetable Oil": {"cal": 440, "pro": 0.0, "fat": 50.0, "carb": 0.0},
    "Mayonnaise": {"cal": 340, "pro": 0.5, "fat": 37.5, "carb": 0.5},
    "Heavy Cream": {"cal": 170, "pro": 1.5, "fat": 18.0, "carb": 1.5},
    "Cream Cheese": {"cal": 171, "pro": 3.0, "fat": 17.0, "carb": 2.0},
    "Sour Cream": {"cal": 96, "pro": 1.5, "fat": 9.5, "carb": 2.3},
    // MEATS & PROTEINS
    "Chicken Breast (Cooked)": {"cal": 82, "pro": 15.5, "fat": 1.8, "carb": 0.0},
    "Ground Beef (80/20 Cooked)": {"cal": 125, "pro": 13.0, "fat": 8.0, "carb": 0.0},
    "Beef Steak (Cooked)": {"cal": 125, "pro": 12.5, "fat": 7.5, "carb": 0.0},
    "Pork Ribs": {"cal": 140, "pro": 10.0, "fat": 11.0, "carb": 0.0},
    "Bacon": {"cal": 270, "pro": 18.5, "fat": 21.0, "carb": 0.7},
    "Salmon (Cooked)": {"cal": 104, "pro": 11.0, "fat": 6.5, "carb": 0.0},
    "White Fish (Cod/Tilapia)": {"cal": 52, "pro": 11.5, "fat": 0.5, "carb": 0.0},
    "Shrimp (Cooked)": {"cal": 49, "pro": 12.0, "fat": 0.1, "carb": 0.0},
    "Tuna (Raw)": {"cal": 54, "pro": 12.0, "fat": 0.2, "carb": 0.0},
    "Eggs (Whole)": {"cal": 77, "pro": 6.5, "fat": 5.5, "carb": 0.5},
    "Tofu": {"cal": 38, "pro": 4.0, "fat": 2.0, "carb": 1.0},
    "Chickpeas (Cooked)": {"cal": 82, "pro": 4.5, "fat": 1.5, "carb": 13.5},
    "Lentils (Cooked)": {"cal": 58, "pro": 4.5, "fat": 0.2, "carb": 10.0},
    // CHEESE & DAIRY
    "Cheddar Cheese": {"cal": 200, "pro": 12.5, "fat": 16.5, "carb": 0.5},
    "Mozzarella": {"cal": 140, "pro": 14.0, "fat": 8.5, "carb": 1.5},
    "Parmesan": {"cal": 215, "pro": 19.0, "fat": 14.5, "carb": 2.0},
    "Feta Cheese": {"cal": 132, "pro": 7.0, "fat": 10.5, "carb": 2.0},
    "Milk (Whole)": {"cal": 30, "pro": 1.6, "fat": 1.6, "carb": 2.5},
    "Greek Yogurt": {"cal": 29, "pro": 5.0, "fat": 0.2, "carb": 1.8},
    // PRODUCE
    "Apple": {"cal": 26, "pro": 0.1, "fat": 0.1, "carb": 7.0},
    "Banana": {"cal": 44, "pro": 0.5, "fat": 0.2, "carb": 11.5},
    "Strawberries": {"cal": 16, "pro": 0.3, "fat": 0.1, "carb": 3.8},
    "Avocado": {"cal": 80, "pro": 1.0, "fat": 7.5, "carb": 4.5},
    "Potatoes": {"cal": 38, "pro": 1.0, "fat": 0.0, "carb": 8.5},
    "Carrots": {"cal": 20, "pro": 0.5, "fat": 0.1, "carb": 4.8},
    "Onions": {"cal": 20, "pro": 0.5, "fat": 0.0, "carb": 4.5},
    "Tomatoes": {"cal": 9, "pro": 0.4, "fat": 0.1, "carb": 2.0},
    "Spinach": {"cal": 11, "pro": 1.4, "fat": 0.2, "carb": 1.8},
    "Lettuce": {"cal": 8, "pro": 0.6, "fat": 0.1, "carb": 1.5},
    "Mushrooms": {"cal": 11, "pro": 1.5, "fat": 0.2, "carb": 1.6},
    "Garlic": {"cal": 74, "pro": 3.0, "fat": 0.2, "carb": 16.5},
    // NUTS & MISC
    "Walnuts": {"cal": 327, "pro": 7.5, "fat": 32.5, "carb": 7.0},
    "Peanuts": {"cal": 283, "pro": 13.0, "fat": 24.5, "carb": 8.0},
    "Almonds": {"cal": 289, "pro": 10.5, "fat": 25.0, "carb": 10.0},
    "BBQ Sauce": {"cal": 85, "pro": 0.0, "fat": 0.0, "carb": 20.0},
    "Soy Sauce": {"cal": 26, "pro": 4.0, "fat": 0.0, "carb": 2.5},
    "Tomato Sauce": {"cal": 15, "pro": 0.8, "fat": 0.1, "carb": 3.5},
  };

  List<String> get _knownIngredients => _ingredientDatabase.keys.toList();

  double _baseCalories = 0.0;
  double _baseProtein = 0.0;
  double _baseFat = 0.0;
  double _baseCarbs = 0.0;

  late TextEditingController _foodNameController;
  late TextEditingController _caloriesController;
  late TextEditingController _proteinController;
  late TextEditingController _fatController;
  late TextEditingController _carbsController;
  late TextEditingController _portionController;

  final FocusNode _portionFocusNode = FocusNode();
  String _previousPortionValue = "500";

  final FoodLogService _foodLogService = FoodLogService();

  @override
  void initState() {
    super.initState();
    _foodNameController = TextEditingController();
    _caloriesController = TextEditingController();
    _proteinController = TextEditingController();
    _fatController = TextEditingController();
    _carbsController = TextEditingController();
    _portionController = TextEditingController(text: _previousPortionValue);

    _portionFocusNode.addListener(_onPortionFocusChange);
    _sendImageForPrediction(widget.imageFile);
  }

  @override
  void dispose() {
    _foodNameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    _carbsController.dispose();
    _portionController.dispose();
    _portionFocusNode.removeListener(_onPortionFocusChange);
    _portionFocusNode.dispose();
    _manualWeightController.dispose();
    super.dispose();
  }

  void _parseInitialNutrients(String prediction) {
    final regExp = RegExp(
      r"calories:\s*([\d.]+)[^,]*,\s*(?:protein|protiein):\s*([\d.]+)[^,]*,\s*fat:\s*([\d.]+)[^,]*,\s*carbohydrates:\s*([\d.]+)",
      caseSensitive: false,
    );
    final match = regExp.firstMatch(prediction);
    if (match != null) {
      _baseCalories = double.tryParse(match.group(1)!) ?? 0.0;
      _baseProtein = double.tryParse(match.group(2)!) ?? 0.0;
      _baseFat = double.tryParse(match.group(3)!) ?? 0.0;
      _baseCarbs = double.tryParse(match.group(4)!) ?? 0.0;
      _updateDisplayedValues(500.0);
    }
  }

  Future<void> _sendImageForPrediction(File imageFile) async {
    setState(() {
      _isProcessing = true;
      _hasError = false;
      _message = "Detecting food...";
      _isEstimatingWeight = false;
      _foodNameController.text = "";
      _portionController.text = "---";
      _baseIngredientsRaw = [];
      _displayIngredientsList = [];
      _manualIngredients = [];
      _removedBaseIngredients.clear();
      _showIngredients = false;
    });

    try {
      // --- 1. GET THE TOKEN ---
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token'); // Ensure this key matches your Login logic

      if (token == null) {
        setState(() {
          _hasError = true;
          _message = "Authentication failed. Please log in.";
          _isProcessing = false;
        });
        return;
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseURL/api/predict'),
      );

      // --- 2. ADD THE HEADER ---
      request.headers['Authorization'] = 'Bearer $token';

      request.files.add(await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        contentType: MediaType('image', 'jpeg'),
      ));

      final streamedResponse = await request.send();

      if (streamedResponse.statusCode == 200) {
        streamedResponse.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen((String line) {
          if (line.trim().isNotEmpty) {
            _handleStreamChunk(line);
          }
        }, onDone: () {
          setState(() {
            _isProcessing = false;
          });
        }, onError: (e) {
          print("Stream error: $e");
          setState(() {
            _hasError = true;
            _message = "Connection interrupted";
          });
        });
      } else {
        // Handle 401 specifically if needed
        if (streamedResponse.statusCode == 401) {
           throw Exception('Unauthorized. Please log in again.');
        }
        throw Exception(
            'Prediction failed with status ${streamedResponse.statusCode}');
      }
    } catch (e) {
      print("Error during prediction: $e");
      setState(() {
        // Make the error message user-friendly
        _message = e.toString().contains("Unauthorized") 
            ? "Session expired. Please login." 
            : "Couldn't Detect Food, Let's Scan again";
        _hasError = true;
        _isProcessing = false;
      });
    }
  }

  void _handleStreamChunk(String line) {
    try {
      final Map<String, dynamic> data = jsonDecode(line);

      if (data['type'] == 'classification') {
        if (data['success'] == true) {
          setState(() {
            _foodNameController.text = data['name'] ?? "Unknown";

            if (data.containsKey('ingredients')) {
              _baseIngredientsRaw = List<String>.from(data['ingredients']);
            }

            if (data.containsKey('full_label')) {
              _parseInitialNutrients(data['full_label']);
            }

            _isProcessing = false;
            _isEstimatingWeight = true;
          });
        } else {
          setState(() {
            _hasError = true;
            _message = data['message'] ?? "Recognition failed";
          });
        }
      } else if (data['type'] == 'weight') {
        setState(() {
          String weightStr = data['weight']?.toString() ?? "500";
          _portionController.text = weightStr;
          _previousPortionValue = weightStr;

          // ✅ CAPTURE SMART PORTION
          if (data.containsKey('smart_portion')) {
            _smartPortionRecommendation = data['smart_portion'];
          }

          double finalWeight = double.tryParse(weightStr) ?? 500.0;
          _updateDisplayedValues(finalWeight);

          _showIngredients = true;
          _isEstimatingWeight = false;
        });
      }
    } catch (e) {
      print("Error parsing chunk: $e");
    }
  }

  void _updateDisplayedValues(double totalPortionSize) {
    double manualTotalWeight = 0.0;
    
    double manualCals = 0.0;
    double manualPro = 0.0;
    double manualFat = 0.0;
    double manualCarb = 0.0;

    for (var item in _manualIngredients) {
      double weight = item['weight'] as double;
      manualTotalWeight += weight;

      Map<String, double>? stats = _ingredientDatabase[item['name']];
      if (stats != null) {
        double ratio50g = weight / 50.0;
        manualCals += (stats['cal']! * ratio50g);
        manualPro += (stats['pro']! * ratio50g);
        manualFat += (stats['fat']! * ratio50g);
        manualCarb += (stats['carb']! * ratio50g);
      }
    }

    double remainingForBase = totalPortionSize - manualTotalWeight;
    if (remainingForBase < 0) remainingForBase = 0;

    final double baseRatio = remainingForBase / 500.0;

    double baseCals = _baseCalories * baseRatio;
    double basePro = _baseProtein * baseRatio;
    double baseFat = _baseFat * baseRatio;
    double baseCarb = _baseCarbs * baseRatio;

    setState(() {
      _caloriesController.text = (baseCals + manualCals).toStringAsFixed(0);
      _proteinController.text = (basePro + manualPro).toStringAsFixed(1);
      _fatController.text = (baseFat + manualFat).toStringAsFixed(1);
      _carbsController.text = (baseCarb + manualCarb).toStringAsFixed(1);

      // Rebuild Display List
      _displayIngredientsList = [];

      // A. Add AI Ingredients (Filtered & Scaled)
      if (_baseIngredientsRaw.isNotEmpty && remainingForBase > 0) {
        for (var rawString in _baseIngredientsRaw) {
          final regex = RegExp(r"^(.*?):\s*([\d.]+)\s*g");
          final match = regex.firstMatch(rawString);

          if (match != null) {
            String name = match.group(1) ?? "";
            
            // SKIP if user removed it
            if (_removedBaseIngredients.contains(name)) continue;

            double baseAmount = double.tryParse(match.group(2) ?? "0") ?? 0;
            double newAmount = baseAmount * baseRatio;
            
            _displayIngredientsList.add({
              "name": name,
              "weight": newAmount,
              "isManual": false,
              "originalString": rawString // Keep for reference
            });
          }
        }
      }

      // B. Add Manual Ingredients
      for (var item in _manualIngredients) {
        _displayIngredientsList.add({
          "name": item['name'],
          "weight": item['weight'],
          "isManual": true
        });
      }
    });
  }

  void _addManualIngredient() {
    if (_selectedManualIngredient.isEmpty) return;
    String weightText = _manualWeightController.text.trim();
    if (weightText.isEmpty) return;
    double addedWeight = double.tryParse(weightText) ?? 0.0;
    if (addedWeight <= 0) return;

    double currentPortion = double.tryParse(_portionController.text) ?? 500.0;

    setState(() {
      _manualIngredients.add({
        "name": _selectedManualIngredient,
        "weight": addedWeight
      });
      
      _manualWeightController.clear();
      _selectedManualIngredient = "";
      _autocompleteController?.clear();
      _updateDisplayedValues(currentPortion);
    });
  }

  // --- NEW: EDIT/REMOVE LOGIC ---
  void _showEditIngredientDialog(Map<String, dynamic> ingredient) {
    final TextEditingController editWeightController = 
        TextEditingController(text: ingredient['weight'].toStringAsFixed(0));
    final String name = ingredient['name'];
    final bool isManual = ingredient['isManual'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit $name"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             TextField(
              controller: editWeightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: "Weight (g)",
                suffixText: "g",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          // REMOVE BUTTON
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _removeIngredient(name, isManual);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Remove"),
          ),
          // SAVE BUTTON
          ElevatedButton(
            onPressed: () {
               double newWeight = double.tryParse(editWeightController.text) ?? 0;
               if (newWeight > 0) {
                 Navigator.pop(context);
                 _updateIngredientWeight(name, newWeight, isManual);
               }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _removeIngredient(String name, bool isManual) {
    double currentPortion = double.tryParse(_portionController.text) ?? 500.0;
    setState(() {
      if (isManual) {
        _manualIngredients.removeWhere((item) => item['name'] == name);
      } else {
        // If it's a base ingredient, add to removed set so it's filtered out
        _removedBaseIngredients.add(name);
      }
      _updateDisplayedValues(currentPortion);
    });
  }

  void _updateIngredientWeight(String name, double newWeight, bool isManual) {
    double currentPortion = double.tryParse(_portionController.text) ?? 500.0;
    setState(() {
      if (isManual) {
        // Just update the manual list
        final index = _manualIngredients.indexWhere((item) => item['name'] == name);
        if (index != -1) {
          _manualIngredients[index]['weight'] = newWeight;
        }
      } else {
        // It was a base ingredient. 
        // 1. "Remove" it from base (so it doesn't auto-scale anymore)
        _removedBaseIngredients.add(name);
        // 2. Add it as a Manual ingredient with the new FIXED weight
        _manualIngredients.add({
          "name": name,
          "weight": newWeight
        });
      }
      _updateDisplayedValues(currentPortion);
    });
  }

  void _onPortionFocusChange() async {
    if (!_portionFocusNode.hasFocus) {
      final String newValue = _portionController.text;
      if (newValue != _previousPortionValue) {
        final bool? didConfirm = await _showPortionUpdateDialog();

        if (didConfirm == true) {
          final double newPortion = double.tryParse(newValue) ?? 500.0;
          _updateDisplayedValues(newPortion);
          _previousPortionValue = newValue;
        } else {
          setState(() {
            _portionController.text = _previousPortionValue;
          });
        }
      }
    } else {
      _previousPortionValue = _portionController.text;
    }
  }

  Future<bool?> _showPortionUpdateDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Update Portion Size?"),
        content: const Text(
            "This will recalculate nutritional values AND ingredient quantities. Continue?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes, Update"),
          ),
        ],
      ),
    );
  }

  void _onUseImagePressed() {
    // Convert map back to simple string list for logging
    List<String> finalIngredients = _displayIngredientsList.map((item) {
       return "${item['name']}: ${item['weight'].toStringAsFixed(0)}g";
    }).toList();

    final finalData = {
      'name': _foodNameController.text,
      'calories': _caloriesController.text,
      'protein': _proteinController.text,
      'fat': _fatController.text,
      'carbs': _carbsController.text,
      'portion': double.tryParse(_portionController.text) ?? 500.0,
      'ingredients': finalIngredients,
    };
    _showMealTypeDialog(finalData);
  }

  Future<void> _showMealTypeDialog(Map<String, dynamic> foodData) async {
    String? selectedMeal;

    final bool? shouldLog = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final List<String> mealTypes = [
              "Breakfast",
              "Lunch",
              "Dinner",
              "Snack"
            ];
            return AlertDialog(
              title: const Text("Log as..."),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Are you having this for:"),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: mealTypes.map((meal) {
                      final bool isSelected = selectedMeal == meal;
                      return ElevatedButton(
                        onPressed: () {
                          setDialogState(() {
                            selectedMeal = meal;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.grey[200],
                          foregroundColor:
                              isSelected ? Colors.white : Colors.black87,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: isSelected ? 4 : 0,
                        ),
                        child: Text(meal),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: selectedMeal == null
                      ? null
                      : () => Navigator.pop(dialogContext, true),
                  child: const Text("Log"),
                ),
              ],
            );
          },
        );
      },
    );

    if (shouldLog == true && selectedMeal != null) {
      foodData['mealType'] = selectedMeal;
      await _logFood(foodData);
    }
  }

  Future<void> _logFood(Map<String, dynamic> foodData) async {
    setState(() {
      _isLoading = true;
    });

    final String mealType = foodData['mealType'];
    final String productName = foodData['name'];

    final Map<String, dynamic> nutrients = {
      'calories': double.tryParse(foodData['calories']) ?? 0.0,
      'protein': double.tryParse(foodData['protein']) ?? 0.0,
      'fat': double.tryParse(foodData['fat']) ?? 0.0,
      'carbohydrates': double.tryParse(foodData['carbs']) ?? 0.0,
    };

    final bool success = await _foodLogService.logFood(
      mealType: mealType,
      productName: productName,
      nutrients: nutrients,
      date: DateTime.now(),
      imageUrl: null,
    );

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$productName logged as $mealType!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to log food. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: FileImage(widget.imageFile),
          fit: BoxFit.cover,
          opacity: 0.1,
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.05),
            Colors.white,
          ],
          stops: const [0.0, 0.3],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'Analysis Result',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.85),
          elevation: 0,
        ),
        body: Stack(
          children: [
            _isProcessing
                ? _buildLoadingWidget()
                : (_hasError ? _buildErrorWidget() : _buildSuccessWidget()),

            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 20),
                      Text(
                        'Logging your meal...',
                        style: TextStyle(color: Colors.white, fontSize: 16),
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

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/animation/FoodLoading.json',
            width: 250,
            height: 250,
          ),
          const SizedBox(height: 24),
          Text(
            _message,
            style: TextStyle(
              fontSize: 20,
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.sentiment_dissatisfied_rounded,
                color: Colors.red[400],
                size: 80,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey[800],
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: 200,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context), // "Try Again"
                icon: const Icon(Icons.refresh),
                label: const Text("Try Again"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessWidget() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildHeaderCard(),
          const SizedBox(height: 24),
          _buildIngredientsCard(),
          if (_showIngredients) ...[
            const SizedBox(height: 24),
            _buildAddIngredientCard(),
          ],
          const SizedBox(height: 24),
          _buildNutritionCard(),
          const SizedBox(height: 24),
          _buildPortionCard(),
          // ✅ ADDED HERE
          const SizedBox(height: 24),
          _buildSmartPortionCard(),
          const SizedBox(height: 40),
          _buildActionButtons(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.file(widget.imageFile, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Detected Food",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: _foodNameController,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: "Enter food name",
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsCard() {
    if (_isEstimatingWeight) {
      return Column(
        children: [
          _buildSectionTitle(Icons.restaurant_menu, "Ingredients"),
          _buildEstimatingPlaceholder("Calculating ingredient amounts..."),
        ],
      );
    }

    if (!_showIngredients || _displayIngredientsList.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        _buildSectionTitle(Icons.restaurant_menu, "Ingredients (Tap to Edit)"),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: _displayIngredientsList.map((item) {
              String displayText = "${item['name']}: ${item['weight'].toStringAsFixed(0)}g";
              if (item['isManual'] == true) displayText += " (User)";

              return InkWell(
                onTap: () => _showEditIngredientDialog(item), // OPEN EDIT DIALOG
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    // Manual items get a slightly different color
                    color: item['isManual'] 
                        ? Theme.of(context).primaryColor.withOpacity(0.2) 
                        : Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    displayText,
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAddIngredientCard() {
    return Column(
      children: [
        _buildSectionTitle(Icons.add_circle_outline, "Add Missing Ingredient"),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text == '') {
                    return const Iterable<String>.empty();
                  }
                  return _knownIngredients.where((String option) {
                    return option
                        .toLowerCase()
                        .contains(textEditingValue.text.toLowerCase());
                  });
                },
                onSelected: (String selection) {
                  setState(() {
                    _selectedManualIngredient = selection;
                  });
                },
                fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                   _autocompleteController = controller;
                   return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    onEditingComplete: onEditingComplete,
                    decoration: InputDecoration(
                      labelText: "Search Ingredient",
                      prefixIcon: Icon(Icons.search, color: Theme.of(context).primaryColor),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _manualWeightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: "Weight (g)",
                        suffixText: "g",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _addManualIngredient,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      backgroundColor: Theme.of(context).primaryColor,
                    ),
                    child: const Text("Add", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  )
                ],
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _buildSmartPortionCard() {
    if (_isEstimatingWeight) return const SizedBox.shrink(); // Don't show while loading
    if (_smartPortionRecommendation == null || _smartPortionRecommendation!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        _buildSectionTitle(Icons.lightbulb_outline, "Smart Recommendation"),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.green.shade50,
                Colors.green.shade100.withOpacity(0.5)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.health_and_safety, color: Colors.green[700], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "AI Nutritionist",
                    style: TextStyle(
                      color: Colors.green[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _smartPortionRecommendation!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionCard() {
    if (_isEstimatingWeight) {
      return Column(
        children: [
          _buildSectionTitle(Icons.edit_note, "Nutritional Details"),
          _buildEstimatingPlaceholder("Calculating macros..."),
        ],
      );
    }

    return Column(
      children: [
        _buildSectionTitle(Icons.edit_note, "Nutritional Details (Editable)"),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildEditableRow(
                  "Calories", _caloriesController, "kcal", Colors.orange),
              _buildDivider(),
              _buildEditableRow(
                  "Protein", _proteinController, "g", Colors.redAccent),
              _buildDivider(),
              _buildEditableRow(
                  "Fat", _fatController, "g", Colors.yellow[800]!),
              _buildDivider(),
              _buildEditableRow("Carbs", _carbsController, "g", Colors.blue),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstimatingPlaceholder(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5)),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortionCard() {
    if (_isEstimatingWeight) {
      return Column(
        children: [
          _buildSectionTitle(Icons.pie_chart, "Portion Size"),
          _buildEstimatingPlaceholder("Estimating weight with AI..."),
        ],
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Row(
            children: [
              Icon(Icons.pie_chart, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              const Text(
                "Portion Size (Editable)",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: _buildPortionRow(
              "Portion", _portionController, "g", Colors.grey[700]!),
        ),
      ],
    );
  }

  Widget _buildPortionRow(
      String label, TextEditingController controller, String unit, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.circle, size: 12, color: color),
          ),
          const SizedBox(width: 16),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 100,
            child: TextFormField(
              controller: controller,
              focusNode: _portionFocusNode,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              decoration: InputDecoration(
                isDense: true,
                suffixText: " $unit",
                suffixStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: Colors.grey[600],
                ),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.transparent),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableRow(
      String label, TextEditingController controller, String unit, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.circle, size: 12, color: color),
          ),
          const SizedBox(width: 16),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 100,
            child: TextFormField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              decoration: InputDecoration(
                isDense: true,
                suffixText: " $unit",
                suffixStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: Colors.grey[600],
                ),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.transparent),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, thickness: 1, color: Colors.grey[100]);
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text("Retake"),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              side: BorderSide(color: Colors.grey[400]!),
              foregroundColor: Colors.grey[800],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: _onUseImagePressed,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text("Use This Food"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: Theme.of(context).primaryColor.withOpacity(0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}