import 'package:flutter/material.dart';
import 'package:fyp/LocalDB.dart';
import 'dart:math' as math; // Add this import to fix the Random class error
import 'WaterIntakePage.dart';

class MealsPerDayPage extends StatefulWidget {
  const MealsPerDayPage({super.key});

  @override
  State<MealsPerDayPage> createState() => _MealsPerDayPageState();
}

class _MealsPerDayPageState extends State<MealsPerDayPage>
    with SingleTickerProviderStateMixin {
  int? _selectedOption;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _foodSizeAnimation;
  late Animation<Color?> _colorAnimation;

  final List<Map<String, dynamic>> mealOptions = [
    {
      'count': '5 meals',
      'description': 'Breakfast, Lunch, Dinner and 2 Snacks',
      'icon': Icons.restaurant,
      'color': Colors.blue,
      'foods': ['🍳', '🥪', '🍲', '🍎', '🥜'],
    },
    {
      'count': '4 meals',
      'description': 'Breakfast, Lunch, Dinner and 1 Snack',
      'icon': Icons.breakfast_dining,
      'color': Colors.green,
      'foods': ['🥞', '🍝', '🍛', '🍌'],
    },
    {
      'count': '3 meals',
      'description': 'Breakfast, Lunch, Dinner',
      'icon': Icons.dinner_dining,
      'color': Colors.orange,
      'foods': ['🥐', '🥗', '🍱'],
    },
    {
      'count': '2 meals',
      'description': 'Breakfast or Dinner with Lunch',
      'icon': Icons.lunch_dining,
      'color': Colors.purple,
      'foods': ['🍓', '🍜'],
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.05), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 50),
    ]).animate(_animationController);

    _foodSizeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 70),
    ]).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    _colorAnimation = ColorTween(
      begin: Colors.grey[200],
      end: Colors.blue[100],
    ).animate(_animationController);

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _selectOption(int index) {
    setState(() {
      _selectedOption = index;
      _animationController.reset();
      _animationController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        children: [
          // Animated background
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _selectedOption != null
                      ? mealOptions[_selectedOption!]['color'].withOpacity(0.1)
                      : colorScheme.surfaceContainerHighest,
                  colorScheme.surface,
                ],
              ),
            ),
          ),

          // Floating food particles
          ...List.generate(20, (index) {
            return Positioned(
              left: math.Random().nextDouble() *
                  MediaQuery.of(context).size.width,
              top: math.Random().nextDouble() *
                  MediaQuery.of(context).size.height,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 500),
                opacity: _selectedOption != null ? 0.3 : 0.1,
                child: Text(
                  ['🍎', '🥑', '🥦', '🍗', '🥕', '🍇'][index % 6],
                  style: TextStyle(
                    fontSize: 16 + (index * 2).toDouble(),
                  ),
                ),
              ),
            );
          }),

          SingleChildScrollView(
            child: Column(
              children: [
                AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                 
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Animated title
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Text(
                          'How many meals',
                          style: textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                            shadows: [
                              Shadow(
                                blurRadius: 10,
                                color: colorScheme.primary.withOpacity(0.2),
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),
                      Text(
                        'do you have per day?',
                        style: textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                          height: 0.9,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Meal option cards
                      ...List.generate(mealOptions.length, (index) {
                        final option = mealOptions[index];
                        final isSelected = _selectedOption == index;

                        return GestureDetector(
                          onTap: () => _selectOption(index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(bottom: 20),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? option['color'].withOpacity(0.1)
                                  : colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? option['color']
                                    : Colors.transparent,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected
                                      ? option['color'].withOpacity(0.2)
                                      : Colors.transparent,
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      option['count'],
                                      style: textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? option['color']
                                            : colorScheme.onSurface,
                                      ),
                                    ),
                                    AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isSelected
                                            ? option['color'].withOpacity(0.3)
                                            : colorScheme.onSurface
                                                .withOpacity(0.1),
                                      ),
                                      child: Icon(
                                        option['icon'],
                                        color: isSelected
                                            ? option['color']
                                            : colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  option['description'],
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurface
                                        .withOpacity(0.8),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Food icons
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: List.generate(
                                    option['foods'].length,
                                    (foodIndex) => AnimatedScale(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      scale: isSelected
                                          ? _foodSizeAnimation.value
                                          : 1.0,
                                      child: Text(
                                        option['foods'][foodIndex],
                                        style: const TextStyle(fontSize: 28),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),

                      const SizedBox(height: 40),

                      // Continue button
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        width: double.infinity,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          gradient: _selectedOption != null
                              ? LinearGradient(
                                  colors: [
                                    mealOptions[_selectedOption!]['color'],
                                    mealOptions[_selectedOption!]['color']
                                        .withOpacity(0.7),
                                  ],
                                )
                              : LinearGradient(
                                  colors: [
                                    colorScheme.onSurface.withOpacity(0.1),
                                    colorScheme.onSurface.withOpacity(0.1),
                                  ],
                                ),
                          boxShadow: [
                            BoxShadow(
                              color: _selectedOption != null
                                  ? mealOptions[_selectedOption!]['color']
                                      .withOpacity(0.4)
                                  : Colors.transparent,
                              blurRadius: 15,
                              spreadRadius: 1,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(30),
                            onTap: _selectedOption != null
                                ? () async{
                                   await LocalDB.setMealOptions(mealOptions[_selectedOption!]['count']);

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const WaterIntakePage()),
                                    );
                                  }
                                : null,
                            child: Center(
                              child: Text(
                                'CONTINUE',
                                style: textTheme.titleLarge?.copyWith(
                                  color: _selectedOption != null
                                      ? Colors.white
                                      : colorScheme.onSurface.withOpacity(0.5),
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
