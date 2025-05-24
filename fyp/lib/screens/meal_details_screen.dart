import 'package:flutter/material.dart';
import 'package:fyp/Widgets/cooking_steps_section.dart';
import 'package:fyp/data/daily_meals.dart';
import 'package:fyp/screens/replace_meal_screen.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';


enum ViewSource {
  defaultView,  // For normal meal details
  replaceMeal   // When coming from recipe replacement
}

class MealDetailScreen extends StatefulWidget {
  final int? dayNumber;
  final int? originalDay;
  final String? originalMealId;
  final bool isAddingNew;
  final Meal meal;
  final bool isLogged;
  final Function(int, String)? onMealLogged;
  final Function(int, String)? onMealUnlogged;
  final ViewSource source;

  const MealDetailScreen({
    super.key,
    required this.meal,
    required this.isLogged,
    this.onMealLogged,
    this.onMealUnlogged, 
    this.source = ViewSource.defaultView, 
    this.originalDay, 
    this.originalMealId, 
    this.isAddingNew =false, 
    this.dayNumber,
  });

  @override
  State<MealDetailScreen> createState() => _MealDetailScreenState();
}

class _MealDetailScreenState extends State<MealDetailScreen> {
  late List<bool> _completedSteps;

  @override
  void initState() {
    super.initState();
    _completedSteps = List<bool>.filled(widget.meal.cookingSteps.length, false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color.fromARGB(255, 96, 75, 75), Colors.white],
            ),
          ),
        ),
        title: Text(widget.meal.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.black),
            onPressed: widget.isLogged
                ? () {
                    widget.onMealUnlogged?.call(widget.dayNumber!,widget.meal.id);
                    Navigator.pop(context);
                  }
                : null,
          ),
          if (!widget.isAddingNew)
          IconButton(
            icon: const Icon(Icons.refresh), // Changed to replace icon
            onPressed: () async{
              if (widget.originalDay == null || widget.originalMealId == null) return;
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReplaceMealScreen(
                    originalDay: widget.originalDay!,
                    originalMealId: widget.originalMealId!,
                    mealType: widget.meal.type, 
                  ),
                ),
              );
               if (result != null && context.mounted) {
                Navigator.pop(context, result);
               }
               }
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Meal Image
                  Container(
                    height: 250,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(widget.meal.imageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  // Verified Badge
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 8),
                          Text.rich(
                            TextSpan(
                              children: [
                                const TextSpan(text: 'Verified by '),
                                TextSpan(
                                  text: 'NutriWise Nutrition Team',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Calorie & Cooking Info
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _buildInfoCard(
                          icon: Icons.local_fire_department,
                          heading: "Total Calories",
                          value: '${widget.meal.calories} cal',
                        ),
                        const SizedBox(width: 16),
                        _buildInfoCard(
                          icon: Icons.access_time,
                          heading: "Cooking Time",
                          value: widget.meal.cookingTime,
                        ),
                      ],
                    ),
                  ),

                  // Macronutrients
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Macronutrients',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildMacroChip(
                              label: 'Carbs',
                              value: widget.meal.macronutrients['carbs']!,
                              color: Colors.orange,
                            ),
                            _buildMacroChip(
                              label: 'Protein',
                              value: widget.meal.macronutrients['protein']!,
                              color: Colors.red,
                            ),
                            _buildMacroChip(
                              label: 'Fat',
                              value: widget.meal.macronutrients['fats']!,
                              color: Colors.blue,
                            ),
                            _buildMacroChip(
                              label: 'Fiber',
                              value: widget.meal.macronutrients['fiber']!,
                              color: Colors.green,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Ingredients & Steps
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionCard(
                          title: 'Ingredients',
                          items: widget.meal.ingredients,
                        ),
                        const SizedBox(height: 24),
                        CookingStepsSection(
                          steps: widget.meal.cookingSteps,
                          completedSteps: _completedSteps,
                          onStepToggled: (index, value) {
                            setState(() {
                              _completedSteps[index] = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: _buildActionButton()
          ),
        ],
      ),
    );
  }
  Widget _buildActionButton() {
  if (widget.source == ViewSource.replaceMeal || widget.isAddingNew) {
    return ElevatedButton(
      onPressed: () {
        _handleAddToPlan();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black, // Different color for add to plan
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: const Text(
        'Add to Plan',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  return ElevatedButton(
  onPressed: widget.isLogged
      ? null
      : () {
          // Pass both day number and meal ID
          widget.onMealLogged?.call(widget.dayNumber!, widget.meal.id);
          Navigator.pop(context);
        },
  style: ElevatedButton.styleFrom(
    backgroundColor: widget.isLogged ? Colors.grey : Colors.black,
    minimumSize: const Size(double.infinity, 50),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  child: Text(
    widget.isLogged ? 'Already Logged' : 'Log Meal',
    style: TextStyle(
      color: widget.isLogged ? Colors.grey[400] : Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
  ),
);

}


void _handleAddToPlan() {
   if (widget.source == ViewSource.replaceMeal) {
    Navigator.pop(context, widget.meal);
  }
}

  Widget _buildInfoCard(
      {required IconData icon,
      required String heading,
      required String value}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.green, size: 28),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  heading,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroChip(
      {required String label, required String value, required Color color}) {
    return CircularPercentIndicator(
      radius: 40,
      lineWidth: 4,
      percent: 0.7, // Replace with actual value
      center: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      progressColor: color,
      backgroundColor: color.withOpacity(0.2),
      circularStrokeCap: CircularStrokeCap.round,
      footer: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildSectionCard(
      {required String title, required List<String> items}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: Colors.grey[50],
        margin: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 16,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey[800],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${items.length} items',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '•',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 20,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              items[index],
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.4,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (index != items.length - 1)
                        Divider(
                          height: 24,
                          thickness: 1,
                          color: Colors.grey[200],
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
