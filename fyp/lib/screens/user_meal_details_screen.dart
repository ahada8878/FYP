import 'package:flutter/material.dart';
import 'package:fyp/services/meal_service.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class MealDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> meal;
  final DateTime date;

  const MealDetailsScreen({super.key, required this.meal, required this.date});

  @override
  State<MealDetailsScreen> createState() => _MealDetailsScreenState();
}

class _MealDetailsScreenState extends State<MealDetailsScreen> {
  late bool isLogged;
  bool isLogging = false;

  @override
  void initState() {
    super.initState();
    // Check if the meal has a non-null 'loggedAt' field
    isLogged = widget.meal['loggedAt'] != null;
  }

  // --- ✅ NEW METHOD TO HANDLE LOGGING ---
  Future<void> _logMeal() async {
    if (isLogging || isLogged) return; // Prevent multiple clicks

    setState(() {
      isLogging = true;
    });

    try {
      final mealId = widget.meal['id'];
      await MealService.logMeal(mealId);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Meal logged successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        isLogged = true;
      });

      // Pop the screen and return true to signal a successful log
      Navigator.pop(context, true);
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLogging = false;
      });
    }
  }
  bool isSameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

  @override
  Widget build(BuildContext context) {
    // ... (rest of your build method is the same)
    final imageUrl = widget.meal['image'] ??
        "https://spoonacular.com/recipeImages/${widget.meal['id']}-636x393.jpg";

    final nutrients = (widget.meal['nutrients'] is Map)
        ? Map<String, dynamic>.from(widget.meal['nutrients'])
        : <String, dynamic>{};

    final rawIngredients = widget.meal['ingredients'] as List<dynamic>? ?? [];

    dynamic rawInstructions = widget.meal['instructions'];
    String instructionsText = '';
    if (rawInstructions is List) {
      instructionsText = rawInstructions.map((e) => e.toString()).where((s) => s.trim().isNotEmpty).join('. ');
    } else if (rawInstructions is String) {
      instructionsText = rawInstructions.trim();
    }
    final List<String> instructionsList = instructionsText.split(RegExp(r'\.\s+')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    final List<String> ingredientsList = rawIngredients.map<String>((ing) => "${ing['name'] ?? ''} ${ing['amount'] ?? ''} ${ing['unit'] ?? ''}".trim()).where((s) => s.trim().isNotEmpty).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          widget.meal['title'] ?? 'Meal Details',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
      ),
       // --- ✅ ADDED FLOATING ACTION BUTTON ---
      floatingActionButton:isSameDate(widget.date, DateTime.now())? FloatingActionButton.extended(
        onPressed: _logMeal,
        backgroundColor: isLogged ? Colors.grey : Colors.green,
        icon: isLogging
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Icon(isLogged ? Icons.check_circle : Icons.post_add),
        label: Text(isLogged ? 'Meal Logged' : 'Log This Meal'),
      ):null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 80), // Add padding to avoid overlap
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 280,
                  width: double.infinity,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                Container(
                  height: 280,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black.withOpacity(0.3), Colors.transparent],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildVerifiedBadge(),
                  const SizedBox(height: 24),
                  _buildQuickStats(nutrients),
                  const SizedBox(height: 28),
                  _buildMacronutrientsSection(nutrients),
                  const SizedBox(height: 28),
                  _buildIngredientsSection(
                    ingredientsList,
                    widget.meal['servings']?.toString() ?? 'N/A',
                  ),
                  const SizedBox(height: 24),
                  _buildInstructionsSection(instructionsList),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifiedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[100]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, color: Colors.green[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: 'Verified by ',
                    style: TextStyle(color: Colors.black87, fontSize: 14),
                  ),
                  TextSpan(
                    text: 'NutriWise Nutrition Team',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.green[700],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(Map<String, dynamic> nutrients) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.local_fire_department_outlined,
            title: "Calories",
            value: '${nutrients['calories'] ?? '-'}',
            unit: 'kcal',
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            icon: Icons.access_time_outlined,
            title: "Ready In",
            value: '${widget.meal['readyInMinutes'] ?? '-'}',
            unit: 'min',
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontSize: 20,
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacronutrientsSection(Map<String, dynamic> nutrients) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Macronutrients',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Per serving',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(color: Colors.grey[100]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMacroIndicator(
                label: 'Carbs',
                value: '${nutrients['carbs'] ?? '-'}g',
                color: Colors.orange,
                icon: Icons.breakfast_dining_outlined,
              ),
              _buildMacroIndicator(
                label: 'Protein',
                value: '${nutrients['protein'] ?? '-'}g',
                color: Colors.red,
                icon: Icons.fitness_center_outlined,
              ),
              _buildMacroIndicator(
                label: 'Fat',
                value: '${nutrients['fat'] ?? '-'}g',
                color: Colors.blue,
                icon: Icons.water_drop_outlined,
              ),
              _buildMacroIndicator(
                label: 'Fiber',
                value: '${nutrients['fiber'] ?? '-'}g',
                color: Colors.green,
                icon: Icons.forest_outlined,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMacroIndicator({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        CircularPercentIndicator(
          radius: 32,
          lineWidth: 5,
          percent: 0.7,
          center: Icon(icon, color: color, size: 20),
          progressColor: color,
          backgroundColor: color.withOpacity(0.1),
          circularStrokeCap: CircularStrokeCap.round,
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildIngredientsSection(List<String> ingredients, String servings) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Ingredients',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Servings: $servings',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...ingredients.asMap().entries.map((entry) {
            final index = entry.key;
            final ingredient = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.only(right: 12, top: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      ingredient,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.4,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildInstructionsSection(List<String> instructions) {
    final displayInstructions =
        instructions.isNotEmpty ? instructions : ['No instructions available.'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Instructions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          ...displayInstructions.asMap().entries.map((entry) {
            final index = entry.key;
            final instruction = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    margin: const EdgeInsets.only(right: 16, top: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.orange[700],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      instruction,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
