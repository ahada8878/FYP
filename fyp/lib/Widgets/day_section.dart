import 'package:flutter/material.dart';
import 'package:fyp/Widgets/meal_card.dart';
import 'package:fyp/data/daily_meals.dart';
import 'package:fyp/screens/replace_meal_screen.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';


class DaySection extends StatelessWidget {
  final int dayNumber;
  final Set<String> loggedMealIds;
  final Map<String, Meal> replacements;
  final Function(int, String)? onMealLogged;
  final Function(int, String)? onMealUnlogged;
  final Function(int, String, Meal)? onMealReplaced;

  const DaySection({
    super.key,
    required this.dayNumber,
    required this.loggedMealIds,
    required this.replacements,
    this.onMealLogged,
    this.onMealUnlogged,
    this.onMealReplaced,
  });

  @override
  Widget build(BuildContext context) {
    final originalMeals = getDayMeals(dayNumber);
    
    final mealPairs = originalMeals.map((original) => {
      'original': original,
      'displayed': replacements[original.id] ?? original,
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Day $dayNumber • ${getDayStatus(dayNumber)}',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF212121))),
              TextButton(
                onPressed: () => _handleAddMeal(context),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.green,
                  padding: EdgeInsets.zero,
                ),
                child: const Text('+ Add',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    )),
              ),
            ],
          ),
        ),
        Column(
          children: mealPairs.map((pair) => MealCard(
            meal: pair['displayed'] as Meal,
            isLogged: loggedMealIds.contains((pair['displayed'] as Meal).id),
            dayNumber: dayNumber,
            originalMeal: pair['original'] as Meal,
            onMealLogged: onMealLogged,
            onMealUnlogged: onMealUnlogged,
            onMealReplaced: onMealReplaced,
          )).toList(),
        ),
      ],
    );
  }

  void _handleAddMeal(BuildContext context) async {
    final result = 
    await PersistentNavBarNavigator.pushNewScreen(
        context,
        screen: ReplaceMealScreen(
          originalDay: dayNumber,
          isAddingNew: true,
        ),
        withNavBar: false, 
        pageTransitionAnimation: PageTransitionAnimation.cupertino,
    );

    if (result != null && onMealReplaced != null) {
      final newMeal = result as Meal;
      final originalMeal = getDayMeals(dayNumber)
          .firstWhere((m) => m.type == newMeal.type);
      onMealReplaced!(dayNumber, originalMeal.id, newMeal);
    }
  }

  String getDayStatus(int day) {
    final today = DateTime.now();
    final difference = day - 1;
    final targetDate = today.add(Duration(days: difference));
    
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    return '${targetDate.day}/${targetDate.month}';
  }
}