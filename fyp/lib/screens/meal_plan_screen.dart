import 'package:flutter/material.dart';
import 'package:fyp/Widgets/day_section.dart';
import 'package:fyp/Widgets/week_progress_widget.dart';
import 'package:fyp/data/daily_meals.dart';


class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({super.key});

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  final Map<int, Set<String>> _loggedMeals = {};

  final Map<int, Map<String, Meal>> _mealReplacements = {};

  void _handleMealLogged(int day, String mealId) {
    setState(() {
      _loggedMeals[day] ??= {};
      _loggedMeals[day]!.add(mealId);
    });
  }

  void _handleMealUnlogged(int day, String mealId) {
    setState(() {
      _loggedMeals[day]?.remove(mealId);
    });
  }

  void _handleMealReplacement(int day, String originalMealId, Meal newMeal) {
    setState(() {
      _mealReplacements[day] ??= {};
      _mealReplacements[day]![originalMealId] = newMeal;
    });
  }

  int _calculateCompletedDays() {
    int completed = 1;
    for (int day = 1; day <= 7; day++) {
      final meals = getDayMeals(day);
      final loggedCount = _loggedMeals[day]?.length ?? 0;

      if (loggedCount >= meals.length) {
        completed++;
      } else {
        break;
      }
    }
    return completed;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFDFB),
      appBar: AppBar(
        title: const Text('Meal Plan',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF212121))),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            WeekProgressWidget(completedDays: _calculateCompletedDays()),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                  itemCount: 7,
                  itemBuilder: (context, index) {
                    final dayNumber = index + 1;
                    return DaySection(
                      dayNumber: dayNumber,
                      loggedMealIds: _loggedMeals[dayNumber] ?? {},
                      replacements: _mealReplacements[dayNumber] ?? {},
                      onMealLogged: (day, mealId) =>
                          _handleMealLogged(day, mealId),
                      onMealUnlogged: (day, mealId) =>
                          _handleMealUnlogged(day, mealId),
                      onMealReplaced: _handleMealReplacement,
                    );
                  }),
            ),
          ],
        ),
      ),
    );
  }
}
