import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'HeightPage.dart';
import 'GoalWeightPage.dart';

class WeightPage extends StatefulWidget {
  final bool isEditing;
  const WeightPage({super.key, this.isEditing=false});

  @override
  State<WeightPage> createState() => _CreativeWeightPageState();
}

class _CreativeWeightPageState extends State<WeightPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Color?> _bgColorAnimation;

  int selectedKg = 70;
  int selectedG = 0;
  bool isMetric = true;
  double bmi = 24.2;
  String bmiCategory = "Normal";

  double _getCurrentWeightInKg() {
    if (isMetric) {
      return selectedKg + (selectedG / 1000);
    } else {
      // Convert pounds to kg
      return selectedKg * 0.45359237;
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _bgColorAnimation = ColorTween(
      begin: Colors.pink[50],
      end: Colors.blue[50],
    ).animate(_animationController);

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Stack(
            children: [
              // Background gradient animation
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _bgColorAnimation.value!,
                      Colors.white,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),

              // Floating food emojis
              Positioned(
                top: 100,
                left: 30,
                child: AnimatedOpacity(
                  duration: const Duration(seconds: 2),
                  opacity: 0.6,
                  child: const Text('🍎', style: TextStyle(fontSize: 40)),
                ),
              ),
              Positioned(
                top: 80,
                right: 40,
                child: AnimatedOpacity(
                  duration: const Duration(seconds: 3),
                  opacity: 0.6,
                  child: const Text('🥑', style: TextStyle(fontSize: 50)),
                ),
              ),
              Positioned(
                bottom: 200,
                left: 50,
                child: AnimatedOpacity(
                  duration: const Duration(seconds: 2),
                  opacity: 0.6,
                  child: const Text('🍓', style: TextStyle(fontSize: 45)),
                ),
              ),
              Positioned(
                bottom: 180,
                right: 60,
                child: AnimatedOpacity(
                  duration: const Duration(seconds: 3),
                  opacity: 0.6,
                  child: const Text('🍊', style: TextStyle(fontSize: 48)),
                ),
              ),

              SingleChildScrollView(
                child: Column(
                  children: [
                    AppBar(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      leading: IconButton(
                        icon: Icon(Icons.arrow_back,
                            color: colorScheme.onBackground),
                        onPressed: () {
                          Navigator.pop(context, _getCurrentWeightInKg());
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: Text(
                              'Your Current Weight',
                              style: textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                                shadows: [
                                  Shadow(
                                    blurRadius: 8,
                                    color: colorScheme.primary.withOpacity(0.2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          AnimatedOpacity(
                            opacity: _opacityAnimation.value,
                            duration: const Duration(milliseconds: 500),
                            child: Text(
                              'Let us know your weight to calculate your BMI and personalize your plan',
                              style: textTheme.titleMedium?.copyWith(
                                color:
                                    colorScheme.onBackground.withOpacity(0.7),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Measurement Toggle
                          Container(
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.primary.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildMeasurementButton(
                                    'kg', isMetric, colorScheme),
                                _buildMeasurementButton(
                                    'lbs', !isMetric, colorScheme),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Weight Picker
                          SizedBox(
                            height: 200,
                            child: isMetric
                                ? _buildKilogramPicker(colorScheme)
                                : _buildPoundsPicker(colorScheme),
                          ),
                          const SizedBox(height: 24),

                          // BMI Information
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.primary.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Your BMI: ${bmi.toStringAsFixed(1)}',
                                      style: TextStyle(
                                        color: colorScheme.onSurfaceVariant,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getBmiCategoryColor(),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        bmiCategory,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _getBmiAdvice(),
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant
                                        .withOpacity(0.8),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Continue Button
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: Material(
                              borderRadius: BorderRadius.circular(30),
                              elevation: 5,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(30),
                                onTap: () {
                                  if (widget.isEditing) {
                                    Navigator.pop(
                                        context, _getCurrentWeightInKg());
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              GoalWeightPage(currentWeight: _getCurrentWeightInKg())),
                                    );
                                  }
                                },
                                child: Container(
                                  width: double.infinity,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30),
                                    gradient: LinearGradient(
                                      colors: [
                                        colorScheme.primary,
                                        colorScheme.secondary,
                                      ],
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      widget.isEditing ? 'SAVE' : 'CONTINUE',
                                      style: textTheme.titleLarge?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
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
          );
        },
      ),
    );
  }

  Widget _buildMeasurementButton(
      String text, bool isActive, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isMetric = text == 'kg';
          _calculateBmi();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: TextStyle(
            color:
                isActive ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildKilogramPicker(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Kilograms Picker
        Column(
          children: [
            Text('kg',
                style: TextStyle(
                    color: colorScheme.onSurfaceVariant, fontSize: 16)),
            const SizedBox(height: 8),
            SizedBox(
              height: 150,
              width: 100,
              child: ListWheelScrollView(
                itemExtent: 50,
                perspective: 0.01,
                diameterRatio: 1.5,
                physics: const FixedExtentScrollPhysics(),
                onSelectedItemChanged: (index) {
                  setState(() {
                    selectedKg = 30 + index;
                    _calculateBmi();
                  });
                },
                children: List.generate(120, (index) => 30 + index)
                    .map((kg) => Center(
                          child: Text(
                            '$kg',
                            style: TextStyle(
                              fontSize: 32,
                              color: kg == selectedKg
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant
                                      .withOpacity(0.3),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
        const SizedBox(width: 24),

        // Grams Picker
        Column(
          children: [
            Text('g',
                style: TextStyle(
                    color: colorScheme.onSurfaceVariant, fontSize: 16)),
            const SizedBox(height: 8),
            SizedBox(
              height: 150,
              width: 100,
              child: ListWheelScrollView(
                itemExtent: 50,
                perspective: 0.01,
                diameterRatio: 1.5,
                physics: const FixedExtentScrollPhysics(),
                onSelectedItemChanged: (index) {
                  setState(() {
                    selectedG = index * 100;
                    _calculateBmi();
                  });
                },
                children: [
                  '0',
                  '100',
                  '200',
                  '300',
                  '400',
                  '500',
                  '600',
                  '700',
                  '800',
                  '900'
                ]
                    .map((g) => Center(
                          child: Text(
                            g,
                            style: TextStyle(
                              fontSize: 32,
                              color: int.parse(g) == selectedG
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant
                                      .withOpacity(0.3),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPoundsPicker(ColorScheme colorScheme) {
    return SizedBox(
      height: 150,
      child: ListWheelScrollView(
        itemExtent: 50,
        perspective: 0.01,
        diameterRatio: 1.5,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: (index) {
          setState(() {
            selectedKg = 66 + index;
            _calculateBmi();
          });
        },
        children: List.generate(300, (index) => 66 + index)
            .map((lbs) => Center(
                  child: Text(
                    '$lbs lbs',
                    style: TextStyle(
                      fontSize: 32,
                      color: lbs == selectedKg
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant.withOpacity(0.3),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  void _calculateBmi() {
    double weight =
        isMetric ? selectedKg + (selectedG / 1000) : selectedKg / 2.205;

    double height = 1.75; // meters (demo)
    if (height == 0) return;

    setState(() {
      bmi = weight / (height * height);

      if (bmi < 18.5) {
        bmiCategory = "Underweight";
      } else if (bmi < 25) {
        bmiCategory = "Normal";
      } else if (bmi < 30) {
        bmiCategory = "Overweight";
      } else {
        bmiCategory = "Obesity";
      }
    });
  }

  Color _getBmiCategoryColor() {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }

  String _getBmiAdvice() {
    if (bmi < 18.5)
      return "Consider consulting a nutritionist for healthy weight gain strategies.";
    if (bmi < 25)
      return "Great job maintaining a healthy weight! Keep up the good habits.";
    if (bmi < 30)
      return "Small lifestyle changes can help you reach a healthier weight.";
    return "It's important to seek guidance for a healthier lifestyle!";
  }
}
