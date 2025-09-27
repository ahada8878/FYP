import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'package:fyp/LocalDB.dart';
import 'GoalPage.dart';

class GoalWeightPage extends StatefulWidget {
  final bool isEditing;
  final double currentWeight;
  const GoalWeightPage({super.key, this.isEditing= false, required this.currentWeight});

  @override
  State<GoalWeightPage> createState() => _CreativeGoalWeightPageState();
}

class _CreativeGoalWeightPageState extends State<GoalWeightPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Color?> _bgColorAnimation;

  int selectedKg = 58;
  int selectedG = 0;
  double currentWeight = 85.0; // Would come from previous screen
  double targetPercentage = 3.0;
  double get _targetWeight => selectedKg + (selectedG / 1000);

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
    final weightDifference = widget.currentWeight - _targetWeight;
    final targetWeight = widget.currentWeight * (1 - targetPercentage / 100);

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
              const Positioned(
                top: 100,
                left: 30,
                child: AnimatedOpacity(
                  duration: Duration(seconds: 2),
                  opacity: 0.6,
                  child: Text('🥦', style: TextStyle(fontSize: 40)),
                ),
              ),
              const Positioned(
                top: 80,
                right: 40,
                child: AnimatedOpacity(
                  duration: Duration(seconds: 3),
                  opacity: 0.6,
                  child: Text('🍗', style: TextStyle(fontSize: 50)),
                ),
              ),
              const Positioned(
                bottom: 200,
                left: 50,
                child: AnimatedOpacity(
                  duration: Duration(seconds: 2),
                  opacity: 0.6,
                  child: Text('🥗', style: TextStyle(fontSize: 45)),
                ),
              ),
              const Positioned(
                bottom: 180,
                right: 60,
                child: AnimatedOpacity(
                  duration: Duration(seconds: 3),
                  opacity: 0.6,
                  child: Text('🍎', style: TextStyle(fontSize: 48)),
                ),
              ),

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
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: Text(
                              'Your Ideal Weight',
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
                              'Set a healthy target weight to work towards',
                              style: textTheme.titleMedium?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Weight Picker Container
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
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                    '$selectedKg kg ${selectedG > 0 ? '$selectedG g' : ''}'.trim(),
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ),
                                Divider(height: 1, color: colorScheme.onSurfaceVariant.withOpacity(0.1)),
                                SizedBox(
                                  height: 200,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Kilograms Picker
                                      SizedBox(
                                        width: 120,
                                        child: ListWheelScrollView.useDelegate(
                                          itemExtent: 50,
                                          perspective: 0.01,
                                          diameterRatio: 1.5,
                                          physics: const FixedExtentScrollPhysics(),
                                          onSelectedItemChanged: (index) => setState(() => selectedKg = 50 + index),
                                          childDelegate: ListWheelChildBuilderDelegate(
                                            childCount: 30,
                                            builder: (context, index) {
                                              int kg = 50 + index;
                                              return Center(
                                                child: Text(
                                                  '$kg',
                                                  style: TextStyle(
                                                    fontSize: 28,
                                                    color: kg == selectedKg
                                                        ? colorScheme.primary
                                                        : colorScheme.onSurfaceVariant.withOpacity(0.3),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      // Grams Picker
                                      SizedBox(
                                        width: 120,
                                        child: ListWheelScrollView.useDelegate(
                                          itemExtent: 50,
                                          perspective: 0.01,
                                          diameterRatio: 1.5,
                                          physics: const FixedExtentScrollPhysics(),
                                          onSelectedItemChanged: (index) => setState(() => selectedG = index * 100),
                                          childDelegate: ListWheelChildBuilderDelegate(
                                            childCount: 10,
                                            builder: (context, index) {
                                              String g = '${index * 100}';
                                              return Center(
                                                child: Text(
                                                  g,
                                                  style: TextStyle(
                                                    fontSize: 28,
                                                    color: g == '$selectedG'
                                                        ? colorScheme.primary
                                                        : colorScheme.onSurfaceVariant.withOpacity(0.3),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Progress Container
                          Container(
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
                                Text(
                                  'Realistic Target',
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Stack(
                                  children: [
                                    Container(
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    LayoutBuilder(
                                      builder: (context, constraints) {
                                        final progress = (weightDifference / (widget.currentWeight - targetWeight)).clamp(0.0, 1.0);
                                        return Container(
                                          height: 8,
                                          width: constraints.maxWidth * progress,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [colorScheme.primary, colorScheme.secondary],
                                            ),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                                      fontSize: 14,
                                    ),
                                    children: [
                                      const TextSpan(text: 'You will lose '),
                                      TextSpan(
                                        text: '${weightDifference.toStringAsFixed(1)} kg ',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      TextSpan(
                                        text: '(${targetPercentage.toStringAsFixed(0)}% of your weight)',
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'There is scientific evidence that overweight people are more likely to have good metabolic health with some weight loss.',
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
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
                                onTap: () async{
                                 
                                 await LocalDB.setTargetWeight('$selectedKg.$selectedG kg');
                                
                               
                                  if (widget.isEditing) {
                                    //on tap
                            Navigator.pop(context, _targetWeight);
                                  }
                            else {
                              //ontap here
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const GoalPage()),
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
}