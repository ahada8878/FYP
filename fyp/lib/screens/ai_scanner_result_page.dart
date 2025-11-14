import 'package:flutter/material.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:lottie/lottie.dart';
import '../services/config_service.dart';

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
  bool _hasError = false;

  // Controllers for editable fields
  late TextEditingController _foodNameController;
  late TextEditingController _caloriesController;
  late TextEditingController _proteinController;
  late TextEditingController _fatController;
  late TextEditingController _carbsController;

  @override
  void initState() {
    super.initState();
    // Initialize controllers
    _foodNameController = TextEditingController();
    _caloriesController = TextEditingController();
    _proteinController = TextEditingController();
    _fatController = TextEditingController();
    _carbsController = TextEditingController();

    _sendImageForPrediction(widget.imageFile);
  }

  @override
  void dispose() {
    // Dispose controllers
    _foodNameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    _carbsController.dispose();
    super.dispose();
  }

  /// Parses the prediction string from the API
  void _parsePrediction(String prediction) {
    // Regex to match: "Food Name: calories: 200, protiein: 400, fat: 40, carbohydrates: 15"
    // Note: kept 'protiein' typo support
    final regExp = RegExp(
      r"([^:]+):\s*calories:\s*([^,]+),\s*protein:\s*([^,]+),\s*fat:\s*([^,]+),\s*carbohydrates:\s*(.+)",
      caseSensitive: false,
    );

    final match = regExp.firstMatch(prediction.trim());

    if (match != null && match.groupCount == 5) {
      // If parsing is successful, update text controllers
      setState(() {
        _foodNameController.text = match.group(1)!.trim();
        _caloriesController.text = match.group(2)!.trim();
        _proteinController.text = match.group(3)!.trim();
        _fatController.text = match.group(4)!.trim();
        _carbsController.text = match.group(5)!.trim();
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
    // Retrieve editable values from controllers
    final finalData = {
      'name': _foodNameController.text,
      'calories': _caloriesController.text,
      'protein': _proteinController.text,
      'fat': _fatController.text,
      'carbs': _carbsController.text,
      'portion': 1, // This is still hardcoded, as per original spec
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

      // TODO: Implement your future logging logic here
      // e.g., await logFoodToDatabase(foodData);

      // After logging, pop the scanner page and pass data back
      if (mounted) {
        Navigator.pop(context, foodData);
      }
    }
  }

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
        // Body conditionally shows loading, error, or success
        body: _isProcessing
            ? _buildLoadingWidget()
            : (_hasError ? _buildErrorWidget() : _buildSuccessWidget()),
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
          _buildPortionCard(),
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

  Widget _buildPortionCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart_outline, color: Colors.grey[700]),
              const SizedBox(width: 12),
              Text(
                "Portion Size",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: const Text(
              "1 Serving", // Hardcoded as requested
              style: TextStyle(fontWeight: FontWeight.bold),
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