// meal_card.dart
import 'package:flutter/material.dart';
import 'package:fyp/data/daily_meals.dart';
import 'package:fyp/screens/meal_details_screen.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

class MealCard extends StatelessWidget {
  final Meal meal;
  final bool isLogged;
  final int dayNumber; // Add this
  final Meal originalMeal; // Add this
  final Function(int, String)? onMealLogged;
  final Function(int, String)? onMealUnlogged;
  final Function(int, String, Meal)? onMealReplaced;

  const MealCard({
    super.key,
    required this.meal,
    required this.isLogged,
    this.onMealLogged, 
    this.onMealUnlogged, 
    required this.dayNumber, 
    required this.originalMeal, 
    this.onMealReplaced,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final result=
          await PersistentNavBarNavigator.pushNewScreen(
        context,
        screen: MealDetailScreen(
              meal: meal,
              isLogged: isLogged,
              dayNumber: dayNumber,
              onMealLogged: onMealLogged,
              onMealUnlogged: onMealUnlogged,
              originalDay: dayNumber, // Add this
              originalMealId: originalMeal.id
            ),
        withNavBar: false, // OPTIONAL VALUE. True by default.
        pageTransitionAnimation: PageTransitionAnimation.cupertino,
    );
        if (result != null && onMealReplaced != null) {
          onMealReplaced!(dayNumber, originalMeal.id, result as Meal);
        }
      },
      child: Stack(
        children: [
          Opacity(
            opacity: isLogged ? 0.6 : 1.0,
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.type.toUpperCase(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: ColorFiltered(
                            colorFilter: isLogged
                                ? const ColorFilter.mode(
                                    Colors.grey,
                                    BlendMode.saturation,
                                  )
                                : const ColorFilter.mode(
                                    Colors.transparent,
                                    BlendMode.srcOver,
                                  ),
                            child: Image.asset(
                              meal.imageUrl,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                meal.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isLogged
                                      ? Colors.grey[600]
                                      : const Color(0xFF212121),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 16,
                                    color: isLogged
                                        ? Colors.grey[400]
                                        : const Color(0xFF757575),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    meal.time,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isLogged
                                          ? Colors.grey[400]
                                          : const Color(0xFF757575),
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    Icons.local_fire_department,
                                    size: 16,
                                    color: isLogged
                                        ? Colors.grey[400]
                                        : const Color(0xFF757575),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${meal.calories} kcal',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isLogged
                                          ? Colors.grey[400]
                                          : const Color(0xFF757575),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isLogged)
            Positioned(
              top: 8,
              right: 8,
              child: Icon(
                Icons.check_circle,
                color: Colors.green.shade300,
                size: 24,
              ),
            ),
        ],
      ),
    );
  }
}