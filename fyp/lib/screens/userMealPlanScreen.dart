import 'package:flutter/material.dart';
import 'package:fyp/services/meal_service.dart';
import 'package:fyp/screens/user_meal_details_screen.dart';

class UserMealPlanScreen extends StatefulWidget {
  const UserMealPlanScreen({super.key});  

  @override
  State<UserMealPlanScreen> createState() => _UserMealPlanScreenState();
}

class _UserMealPlanScreenState extends State<UserMealPlanScreen> {
  Map<String, dynamic>? mealPlan;
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadMealPlan();
  }

  Future<void> _loadMealPlan() async {
    // Avoid showing loader on refresh unless it's the initial load
    if (mealPlan == null) {
       setState(() {
        isLoading = true;
        errorMessage = '';
      });
    }

    try {
      final response = await MealService.fetchUserMealPlan();
      if (mounted) {
        setState(() {
          mealPlan = response;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = e.toString().replaceAll("Exception: ", "");
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFDFB),
      appBar: AppBar(
        title: const Text(
          "Your Spoonacular Meal Plan",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF212121),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    errorMessage,
                    textAlign: TextAlign.center,
                  ),
                ))
              : mealPlan == null
                  ? const Center(child: Text("No meal plan available"))
                  : _buildMealPlanView(),
    );
  }

  Widget _buildMealPlanView() {
    final weekMeals = mealPlan!['meals'] as Map<String, dynamic>? ?? {};
    final nutrients = mealPlan!['nutrients'] ?? {};
    final detailedRecipes = mealPlan!['detailedRecipes'] as List<dynamic>? ?? [];

    final Map<int, dynamic> recipeDetailsMap = {
      for (var recipe in detailedRecipes) recipe['id']: recipe
    };

    return RefreshIndicator(
      onRefresh: _loadMealPlan, // Allow pull-to-refresh
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ... (rest of your ListView children are mostly the same)
          ...weekMeals.entries.map((entry) {
            final dayName = entry.key;
            final dayData = entry.value as Map<String, dynamic>? ?? {};
            final meals = dayData['meals'] as List<dynamic>? ?? [];
            final mealDate=DateTime.parse( dayData['date'] as String);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  child: Text(
                    dayName[0].toUpperCase() + dayName.substring(1),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF212121),
                    ),
                  ),
                ),
                Column(
                  children: meals.map((meal) {
                    final detailedMeal = recipeDetailsMap[meal['id']];
                    return _buildMealCard(meal, detailedMeal,mealDate);
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],
            );
          }),
        ],
      ),
    );
  }

  // --- ✅ MODIFIED WIDGET ---
  Widget _buildMealCard(Map<String, dynamic> meal, dynamic detailedMeal,DateTime date) {
    final imageUrl = detailedMeal?['image'] ??
        "https://spoonacular.com/recipeImages/${meal['id']}-480x360.${meal['imageType']}";
    
    // Determine if the meal has been logged
    final bool isLogged = detailedMeal?['loggedAt'] != null;

    return GestureDetector(
      onTap: () async { // Make onTap async
        // Navigate to the details screen and wait for a result
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MealDetailsScreen(
              meal: detailedMeal ?? meal,
              date: date,
            ),
          ),
        );

        // If the result is 'true', it means a meal was successfully logged.
        // Refresh the meal plan to get the latest data.
        if (result == true) {
          _loadMealPlan();
        }
      },
      child: Opacity(
        // Add opacity to give a greyed-out effect
        opacity: isLogged ? 0.65 : 1.0,
        child: Card(
          // Change color slightly when logged
          color: isLogged ? Colors.grey[200] : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.restaurant, size: 60),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal['title'] ?? 'Untitled',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF212121),
                          // Add a line-through decoration if logged
                          decoration: isLogged ? TextDecoration.lineThrough : TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // ... (rest of the card content remains the same)
                    ],
                  ),
                ),
                 // Add a checkmark icon if the meal is logged
                if (isLogged)
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Icon(Icons.check_circle, color: Colors.green, size: 24),
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
