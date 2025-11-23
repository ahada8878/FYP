import 'package:flutter/material.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:lottie/lottie.dart';
import '../services/config_service.dart';
// NEW: Import the services needed for logging
import 'package:fyp/services/food_log_service.dart';

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
  bool _isLoading = false; // NEW: For the final logging step
  bool _hasError = false;

  // NEW: Base values (per 500g) from API
  double _baseCalories = 0.0;
  double _baseProtein = 0.0;
  double _baseFat = 0.0;
  double _baseCarbs = 0.0;

  // Controllers for editable fields
  late TextEditingController _foodNameController;
  late TextEditingController _caloriesController;
  late TextEditingController _proteinController;
  late TextEditingController _fatController;
  late TextEditingController _carbsController;
  late TextEditingController _portionController; // NEW

  // NEW: For portion editing
  final FocusNode _portionFocusNode = FocusNode();
  String _previousPortionValue = "500"; // Default portion

  // NEW: Initialize the service
  final FoodLogService _foodLogService = FoodLogService();

  @override
  void initState() {
    super.initState();
    // Initialize controllers
    _foodNameController = TextEditingController();
    _caloriesController = TextEditingController();
    _proteinController = TextEditingController();
    _fatController = TextEditingController();
    _carbsController = TextEditingController();
    _portionController =
        TextEditingController(text: _previousPortionValue); // NEW

    // NEW: Add listener for portion editing
    _portionFocusNode.addListener(_onPortionFocusChange);

    _sendImageForPrediction(widget.imageFile);
  }

  @override
  void dispose() {
    // Dispose controllers
    _foodNameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    _carbsController.dispose(); // NEW
    _portionController.dispose(); // NEW
    _portionFocusNode.removeListener(_onPortionFocusChange); // NEW
    _portionFocusNode.dispose(); // NEW
    super.dispose();
  }

  /// Parses the prediction string from the API
  void _parsePrediction(String prediction) {
    // MODIFIED: More robust Regex to capture *only* numbers and handle both
    // 'protein' and 'protiein' spellings, ignoring units like 'g' or 'kcal'.
    final regExp = RegExp(
      r"([^:]+):\s*calories:\s*([\d.]+)[^,]*,\s*(?:protein|protiein):\s*([\d.]+)[^,]*,\s*fat:\s*([\d.]+)[^,]*,\s*carbohydrates:\s*([\d.]+)",
      caseSensitive: false,
    );

    final match = regExp.firstMatch(prediction.trim());

    if (match != null && match.groupCount == 5) {
      setState(() {
        _foodNameController.text = match.group(1)!.trim();

        // MODIFIED: Store base values
        _baseCalories = double.tryParse(match.group(2)!) ?? 0.0;
        _baseProtein = double.tryParse(match.group(3)!) ?? 0.0;
        _baseFat = double.tryParse(match.group(4)!) ?? 0.0;
        _baseCarbs = double.tryParse(match.group(5)!) ?? 0.0;

        // MODIFIED: Set initial portion size (default is 500)
        // In the future, this value will come from the prediction model
        final initialPortion =
            double.tryParse(_portionController.text) ?? 500.0;
        _previousPortionValue = _portionController.text;

        // MODIFIED: Calculate and set displayed values based on portion
        _updateDisplayedValues(initialPortion);

        _hasError = false;
      });
    } else {
      // If parsing fails, show an error
      print("Failed to parse prediction string: $prediction");
      setState(() {
        _hasError = true;
        _message = "Couldn't Detect Food, Let's Scan again";
      });
    }
  }

  /// Sends the image to the API for prediction
  Future<void> _sendImageForPrediction(File imageFile) async {
    setState(() {
      _isProcessing = true;
      _hasError = false;
      _message = "Analyzing your food...";
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseURL/api/predict'),
      );

      request.files.add(await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        contentType: MediaType('image', 'jpeg'),
      ));

      var response = await request.send();

      if (response.statusCode == 200) {
        final predictionString = await response.stream.bytesToString();
        _parsePrediction(predictionString);
      } else {
        throw Exception('Prediction failed with status ${response.statusCode}');
      }
    } catch (e) {
      print("Error during prediction: $e");
      setState(() {
        _message = "Couldn't Detect Food, Let's Scan again";
        _hasError = true;
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  /// Gathers data and shows the meal type dialog
  void _onUseImagePressed() {
    // MODIFIED: Retrieve editable values from controllers
    final finalData = {
      'name': _foodNameController.text,
      'calories': _caloriesController.text,
      'protein': _proteinController.text,
      'fat': _fatController.text,
      'carbs': _carbsController.text,
      'portion':
          double.tryParse(_portionController.text) ?? 500.0, // MODIFIED
    };

    // Show the meal type selection dialog, passing the data
    _showMealTypeDialog(finalData);
  }

  /// Displays the meal type selection dialog
  Future<void> _showMealTypeDialog(Map<String, dynamic> foodData) async {
    String? selectedMeal; // Variable to hold the selected meal

    // Use showDialog which returns a value when popped
    final bool? shouldLog = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        // Use StatefulBuilder to manage the state *within* the dialog
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
                  // Use Wrap for the buttons so they flow on small screens
                  Wrap(
                    spacing: 8.0, // Horizontal space
                    runSpacing: 8.0, // Vertical space
                    children: mealTypes.map((meal) {
                      final bool isSelected = selectedMeal == meal;
                      return ElevatedButton(
                        onPressed: () {
                          // Update the dialog's state
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
                  onPressed: () {
                    // Pop with 'false' indicating do not log
                    Navigator.pop(dialogContext, false);
                  },
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: selectedMeal == null
                      ? null // Disable button if no meal is selected
                      : () {
                          // Pop with 'true' indicating log
                          Navigator.pop(dialogContext, true);
                        },
                  child: const Text("Log"),
                ),
              ],
            );
          },
        );
      },
    );

    // This code runs *after* the dialog is closed
    if (shouldLog == true && selectedMeal != null) {
      // Add the selected meal to the data
      foodData['mealType'] = selectedMeal;

      print("Final Data to Log: $foodData");

      // MODIFIED: Call the new log function
      await _logFood(foodData);

      // The _logFood function now handles navigation, so the old
      // Navigator.pop(context, foodData) is no longer needed.
    }
  }

  // --- NEW METHODS FOR PORTION CALCULATION ---

  /// NEW: Recalculates and updates the nutrition controllers
  void _updateDisplayedValues(double portionSize) {
    // The base values are for 500g
    final double ratio = portionSize / 500.0;

    setState(() {
      // Set text with fixed precision
      _caloriesController.text = (_baseCalories * ratio).toStringAsFixed(0);
      _proteinController.text = (_baseProtein * ratio).toStringAsFixed(1);
      _fatController.text = (_baseFat * ratio).toStringAsFixed(1);
      _carbsController.text = (_baseCarbs * ratio).toStringAsFixed(1);
    });
  }

  /// NEW: Handles focus change on the portion text field
  void _onPortionFocusChange() async {
    if (!_portionFocusNode.hasFocus) {
      // Just lost focus
      final String newValue = _portionController.text;
      if (newValue != _previousPortionValue) {
        // Value changed, show dialog
        final bool? didConfirm = await _showPortionUpdateDialog();

        if (didConfirm == true) {
          // Yes, update
          final double newPortion = double.tryParse(newValue) ?? 500.0;
          _updateDisplayedValues(newPortion);
          _previousPortionValue = newValue; // Lock in the new value
        } else {
          // No, revert
          setState(() {
            _portionController.text = _previousPortionValue;
          });
        }
      }
    } else {
      // Just gained focus
      _previousPortionValue = _portionController.text;
    }
  }

  /// NEW: Shows the warning dialog before updating portion
  Future<bool?> _showPortionUpdateDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Update Portion Size?"),
        content: const Text(
            "This will recalculate all nutritional details based on the new portion size. Do you want to continue?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // Cancel/No
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true), // Yes
            child: const Text("Yes, Update"),
          ),
        ],
      ),
    );
  }

  // NEW: The final step: log the food to the backend
  Future<void> _logFood(Map<String, dynamic> foodData) async {
    setState(() {
      _isLoading = true; // Show loading indicator
    });

    // Extract and parse data from the map
    final String mealType = foodData['mealType'];
    final String productName = foodData['name'];

    // The controllers store values as strings, parse them to double.
    final Map<String, dynamic> nutrients = {
      'calories': double.tryParse(foodData['calories']) ?? 0.0,
      'protein': double.tryParse(foodData['protein']) ?? 0.0,
      'fat': double.tryParse(foodData['fat']) ?? 0.0,
      'carbohydrates': double.tryParse(foodData['carbs']) ?? 0.0,
    };

    // Use the service to log the food
    final bool success = await _foodLogService.logFood(
      mealType: mealType,
      productName: productName,
      nutrients: nutrients,
      date: DateTime.now(), // Use the current date and time
      imageUrl: null, // Optional: You can add image uploading logic here
    );

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      // Check if the widget is still in the tree
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$productName logged as $mealType!'),
            backgroundColor: Colors.green,
          ),
        );
        // Navigate back to the main screen (pop all the way)
        Navigator.pop(context);
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

  // --- END NEW METHODS ---

  /// Main build method
  @override
  Widget build(BuildContext context) {
    // Main background with image and gradient
    return Container(
      decoration: BoxDecoration(
        // Faded background image
        image: DecorationImage(
          image: FileImage(widget.imageFile),
          fit: BoxFit.cover,
          opacity: 0.1, // "very light" effect
        ),
        // Gradient on top
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
        backgroundColor: Colors.transparent, // Let container's decoration show
        appBar: AppBar(
          title: const Text(
            'Analysis Result',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          // Semi-transparent app bar
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.85),
          elevation: 0,
        ),
        // MODIFIED: Wrap body in a Stack to show loading overlay
        body: Stack(
          children: [
            // Original body content
            _isProcessing
                ? _buildLoadingWidget()
                : (_hasError ? _buildErrorWidget() : _buildSuccessWidget()),

            // NEW: Loading overlay for the final logging step
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

  /// 1. LOADING WIDGET
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

  /// 2. ERROR WIDGET
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

  /// 3. SUCCESS WIDGET (Main UI)
  Widget _buildSuccessWidget() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildHeaderCard(),
          const SizedBox(height: 24),
          _buildNutritionCard(),
          const SizedBox(height: 24),
          _buildPortionCard(), // MODIFIED
          const SizedBox(height: 40),
          _buildActionButtons(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // --- SUCCESS WIDGET HELPERS ---

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
          // Image Preview
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
          // Food Name (Editable)
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

  Widget _buildNutritionCard() {
    return Column(
      children: [
        // Title: "Nutritional Details (Editable)"
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Row(
            children: [
              Icon(Icons.edit_note, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              const Text(
                "Nutritional Details (Editable)",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        // Card with editable rows
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

  /// MODIFIED: This card is now editable
  Widget _buildPortionCard() {
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

  /// NEW: A dedicated row for the portion text field
  Widget _buildPortionRow(
      String label, TextEditingController controller, String unit, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // Colored icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.circle, size: 12, color: color),
          ),
          const SizedBox(width: 16),
          // Label
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          // Editable Text Form Field
          SizedBox(
            width: 100,
            child: TextFormField(
              controller: controller,
              focusNode: _portionFocusNode, // Assign the focus node
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
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

  /// A single editable row for the nutrition card
  Widget _buildEditableRow(
      String label, TextEditingController controller, String unit, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // Colored icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.circle, size: 12, color: color),
          ),
          const SizedBox(width: 16),
          // Label
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          // Editable Text Form Field
          SizedBox(
            width: 100,
            child: TextFormField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
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

  /// A simple visual divider
  Widget _buildDivider() {
    return Divider(height: 1, thickness: 1, color: Colors.grey[100]);
  }

  /// "Retake" and "Use This Food" buttons
  Widget _buildActionButtons() {
    return Row(
      children: [
        // "Retake" Button
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pop(context), // Go back
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
        // "Use This Food" Button
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: _onUseImagePressed, // Triggers the dialog
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