import 'package:flutter/material.dart';
import 'package:fyp/data/daily_meals.dart';
import 'package:fyp/screens/meal_details_screen.dart';


class ReplaceMealScreen extends StatelessWidget {
  final int originalDay;
  final String? originalMealId;
  final String? mealType;
  final bool isAddingNew;

  const ReplaceMealScreen({
    super.key,
    required this.originalDay,
    this.originalMealId,
    this.mealType,
    this.isAddingNew = false,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isAddingNew ? 'Add Meal to Day $originalDay' : 'Replace Meal',
              style: const TextStyle(
                  fontWeight: FontWeight.bold)),
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: Colors.green,
            labelColor: Colors.green,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'Recipes'),
              Tab(text: 'Saved'),
            ],
            labelStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600
            ),
          ),
        ),
        body: TabBarView(
          children: [
            RecipesTab(
              allMeals: _getAllMeals(),
              originalDay: originalDay,
              isAddingNew: isAddingNew,
              mealType: mealType,
            ),
            Container(), // Saved tab
          ],
        ),
      ),
    );
  }

  List<Meal> _getAllMeals() {
    List<Meal> allMeals = [];
    for (int day = 1; day <= 7; day++) {
      allMeals.addAll(getDayMeals(day).where((meal) {
        if (isAddingNew) {
          // For adding new meals, include all meals of any type
          return true;
        } else {
          // For replacements, filter by meal type and exclude current meal
          return meal.type.equalsIgnoreCase(mealType!) &&
                 meal.id != originalMealId;
        }
      }));
    }
    return allMeals;
  }
}

class RecipesTab extends StatelessWidget {
  final List<Meal> allMeals;
  final int originalDay;
  final bool isAddingNew;
  final String? mealType;

  const RecipesTab({
    super.key,
    required this.allMeals,
    required this.originalDay,
    required this.isAddingNew,
    this.mealType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemCount: allMeals.length,
        itemBuilder: (context, index) => RecipeCard(
          meal: allMeals[index],
          originalDay: originalDay,
          isAddingNew: isAddingNew,
          originalMealType: mealType,
        ),
      ),
    );
  }
}

class RecipeCard extends StatelessWidget {
  final Meal meal;
  final int originalDay;
  final bool isAddingNew;
  final String? originalMealType;

  const RecipeCard({
    super.key,
    required this.meal,
    required this.originalDay,
    required this.isAddingNew,
    this.originalMealType,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _navigateToMealDetails(context),
      borderRadius: BorderRadius.circular(12),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12)),
                child: Image.asset(
                  meal.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, error, stackTrace) => const Center(
                    child: Icon(Icons.fastfood, color: Colors.grey),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Row(
                          children: [
                            const Icon(Icons.access_time,
                                size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                meal.cookingTime,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        child: Row(
                          children: [
                            const Icon(Icons.local_fire_department,
                                size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${meal.calories} kcal',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToMealDetails(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MealDetailScreen(
          meal: meal,
          isLogged: false,
          source: ViewSource.replaceMeal,
          originalDay: originalDay,
          originalMealId: isAddingNew ? null : originalMealType,
          isAddingNew: isAddingNew,
        ),
      ),
    );

    if (result != null && context.mounted) {
      Navigator.pop(context, result);
    }
  }
}

extension StringExtensions on String {
  bool equalsIgnoreCase(String other) =>
      toLowerCase() == other.toLowerCase();
}