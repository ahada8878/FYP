import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
// You need to ensure this path is correct and contains the baseURL constant
import 'package:fyp/services/config_service.dart'; 


// --- DATA MODEL (MATCHES BACKEND SCHEMA) ---
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
    // Uses null-aware operators (??) for null safety and new backend keys
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
      throw Exception('Failed to load nutrition data. Status: ${response.statusCode}');
    }
  }

  // --- ANALYZE MEAL HANDLER (FIXED NAVIGATION LOGIC) ---
  void _analyzeMeal() async {
    // 1. Set analyzing state
    setState(() {
      _isAnalyzing = true;
      _updateAnalyzeState();
    });

    // 2. Show creative loading dialogue (non-blocking overlay)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext loadingContext) => const AnalyzingMealDialog(),
    );

    try {
      // 3. Perform API Call
      final results = await fetchNutritionData(
        _foodNameController.text,
        _ingredientsController.text,
      );

      // 4. FIX: Dismiss Loading Dialog before showing results.
      if (mounted) {
        // Use rootNavigator: true for robust dismissal of top-level dialog
        Navigator.of(context, rootNavigator: true).pop();
      }
      
      // Add a small delay to prevent navigation conflict
      await Future.delayed(const Duration(milliseconds: 100));

      // 5. Show Results Dialog (user remains on the main page)
      if (mounted) {
        _showResultsDialog(results);
      }

    } catch (e) {
      if (mounted) {
        // Ensure loading dialog is dismissed on error
        Navigator.of(context, rootNavigator: true).pop(); 
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Uh oh! Analysis failed. Please check the server connection and try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // 6. Reset analyzing state
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _updateAnalyzeState();
        });
      }
    }
  }

  // --- SHOW RESULTS DIALOG (Uses custom styled card) ---
  void _showResultsDialog(NutritionData data) {
    showDialog(
      context: context,
      builder: (context) {
        return NutritionResultsDialog(data: data); 
      },
    );
  }


  @override
  Widget build(BuildContext context) {
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
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: 'e.g Chicken Caesar Salad',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        hintText: 'e.g., 200g chicken breast, 1 cup romaine lettuce, 1 tbsp olive oil...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Analyze Button (uses gradient)
            SizedBox(
              width: double.infinity,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: _isAnalyzeEnabled
                      ? const LinearGradient(
                          colors: [Color(0xFF7F5A83), Color(0xFF0D324D)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  boxShadow: _isAnalyzeEnabled
                      ? [
                          BoxShadow(
                            color: Colors.purple[100]!,
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
                      color: _isAnalyzeEnabled || _isAnalyzing ? Colors.white : Colors.grey[400],
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
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7F5A83)),
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

// --- Custom Widget for Results Dialogue (Solid Color Header) ---
class NutritionResultsDialog extends StatelessWidget {
  final NutritionData data;
  
  const NutritionResultsDialog({super.key, required this.data});

  // Custom Macro Row Widget for visualization (Chip style)
  Widget _buildMacroBar(String label, String value, Color color) {
    final numericValue = double.tryParse(value.split(' ')[0]) ?? 0.0;
    const maxReference = 80.0; 
    final widthFactor = (numericValue / maxReference).clamp(0.1, 1.0); 

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Label
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              // Value Chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: color.withOpacity(0.4), width: 0.5),
                ),
                child: Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Visually Enhanced Progress Bar
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              widthFactor: widthFactor, 
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- REFINED WIDGET FOR INSUFFICIENT DATA MESSAGE (APP MESSAGE STYLE) ---
  Widget _buildInsufficientDataMessage(BuildContext context) {
    const Color primaryColor = Color(0xFF7F5A83); 

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 25.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon is now a helpful prompt style, not an error style
          const Icon(
            Icons.lightbulb_outline,
            color: primaryColor, 
            size: 55,
          ),
          const SizedBox(height: 15),
          const Text(
            'Need More Specifics',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'The AI needs more detail to calculate accurate nutrition data.\n\nCould you please revise your meal description and include *specific* quantities (e.g., "1 cup of rice", "100g chicken")?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Solid primary color used across the dialog for consistency
    const Color primarySolidColor = Color(0xFF7F5A83); 
    const Color secondarySolidColor = Color.fromARGB(255, 23, 62, 92);
    
    // Determine if we show the detailed results or the warning message
    final bool showDetailedResults = data.enoughData;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with SOLID Color
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: secondarySolidColor, 
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    data.foodName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900, 
                      fontSize: 24, 
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    showDetailedResults ? 'Your Meal\'s Nutritional Blueprint' : 'Requires Detailed Input',
                    style: const TextStyle(
                      fontSize: 13, 
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            
            // Body Content (Conditional Rendering)
            showDetailedResults
                ? Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Calories - Big Number Highlight
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEECEF), 
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              Text(
                                data.calories,
                                style: const TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFFC70039), 
                                ),
                              ),
                              const Text(
                                'Total Estimated Energy',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFC70039),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Macro Breakdown (Chip-Style Bars)
                        _buildMacroBar('Carbohydrates', data.carbs, Colors.blue),
                        _buildMacroBar('Protein', data.protein, Colors.green),
                        _buildMacroBar('Fat', data.fat, Colors.orange),
                      ],
                    ),
                  )
                : _buildInsufficientDataMessage(context), // Show refined app message
            
            // Action Button (LOG or REVISE)
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  // Action: Log if results are good, Pop (to allow revision) if results are bad
                  onPressed: showDetailedResults ? () {
                    Navigator.pop(context); // Close dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Awesome! "${data.foodName}" is now logged in your diet diary! 🎉'), 
                        backgroundColor: primarySolidColor, // Consistent button color
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  } : () {
                     // If data is insufficient, close the dialog so the user can edit
                    Navigator.pop(context); 
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    // Use the secondary color for logging, softer primary color for revision prompt
                    backgroundColor: showDetailedResults ? secondarySolidColor : primarySolidColor.withOpacity(0.8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    showDetailedResults ? 'LOG THIS MEAL' : 'REVISE INPUT',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}