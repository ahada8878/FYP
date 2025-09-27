import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'package:fyp/LocalDB.dart';
import 'ExperiencePage.dart';

class HealthConcernsPage extends StatefulWidget {
  const HealthConcernsPage({super.key});

  @override
  State<HealthConcernsPage> createState() => _CreativeHealthConcernsPageState();
}

class _CreativeHealthConcernsPageState extends State<HealthConcernsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Color?> _bgColorAnimation;

  final Map<String, bool> healthConcerns = {
    'I don\'t have any': false,
    'Hypertension': false,
    'High Cholesterol': false,
    'Obesity': false,
    'Diabetes': false,
    'Heart Disease': false,
    'Arthritis': false,
    'Asthma': false,
  };

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

              // Floating health emojis
              const Positioned(
                top: 100,
                left: 30,
                child: AnimatedOpacity(
                  duration: Duration(seconds: 2),
                  opacity: 0.6,
                  child: Text('❤️', style: TextStyle(fontSize: 40)),
                ),
              ),
              const Positioned(
                top: 80,
                right: 40,
                child: AnimatedOpacity(
                  duration: Duration(seconds: 3),
                  opacity: 0.6,
                  child: Text('🩺', style: TextStyle(fontSize: 50)),
                ),
              ),
              const Positioned(
                bottom: 200,
                left: 50,
                child: AnimatedOpacity(
                  duration: Duration(seconds: 2),
                  opacity: 0.6,
                  child: Text('🍬', style: TextStyle(fontSize: 45)),
                ),
              ),
              const Positioned(
                bottom: 180,
                right: 60,
                child: AnimatedOpacity(
                  duration: Duration(seconds: 3),
                  opacity: 0.6,
                  child: Text('⚖️', style: TextStyle(fontSize: 48)),
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
                              'Any health concerns?',
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
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 8),
                          AnimatedOpacity(
                            opacity: _opacityAnimation.value,
                            duration: const Duration(milliseconds: 500),
                            child: Text(
                              'Let us know about any health conditions to personalize your recommendations',
                              style: textTheme.titleMedium?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Health Concern Cards
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            childAspectRatio: 1.5,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            children: healthConcerns.keys.map((concern) {
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (concern == 'I don\'t have any') {
                                      healthConcerns.updateAll((key, value) => false);
                                      healthConcerns[concern] = true;
                                    } else {
                                      healthConcerns['I don\'t have any'] = false;
                                      healthConcerns[concern] = !healthConcerns[concern]!;
                                    }
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  decoration: BoxDecoration(
                                    color: healthConcerns[concern]!
                                        ? _getConditionColor(concern, colorScheme)
                                        : colorScheme.surfaceContainerHighest, // Changed from surface to surfaceVariant
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: colorScheme.primary.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: healthConcerns[concern]!
                                          ? colorScheme.primary
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: Stack(
                                    children: [
                                      Positioned(
                                        top: 16,
                                        right: 16,
                                        child: _getConditionIcon(concern, colorScheme),
                                      ),
                                      Positioned(
                                        bottom: 20,
                                        left: 20,
                                        child: Text(
                                          concern,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: healthConcerns[concern]!
                                                ? colorScheme.onPrimaryContainer
                                                : colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                      if (healthConcerns[concern]!)
                                        Positioned(
                                          top: 12,
                                          left: 12,
                                          child: Icon(
                                            Icons.check_circle_rounded,
                                            color: colorScheme.primary,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),

                          // Health Indicators
                          if (healthConcerns.values.any((checked) => checked))
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              height: 80,
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
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
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildHealthIndicator('❤️', healthConcerns['Heart Disease']!, colorScheme),
                                  _buildHealthIndicator('🍬', healthConcerns['Diabetes']!, colorScheme),
                                  _buildHealthIndicator('⚖️', healthConcerns['Obesity']!, colorScheme),
                                  _buildHealthIndicator('🩺', healthConcerns['Hypertension']!, colorScheme),
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
                                  await LocalDB.setHealthConcerns(healthConcerns);

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const WeightLossFamiliarityPage()),
                                  );
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
                                      'CONTINUE',
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

  Color _getConditionColor(String condition, ColorScheme colorScheme) {
    switch (condition) {
      case 'Hypertension':
        return colorScheme.errorContainer;
      case 'High Cholesterol':
        return colorScheme.errorContainer.withOpacity(0.7);
      case 'Obesity':
        return colorScheme.tertiaryContainer ?? colorScheme.secondaryContainer;
      case 'Diabetes':
        return colorScheme.secondaryContainer;
      case 'Heart Disease':
        return colorScheme.errorContainer.withOpacity(0.5);
      case 'Arthritis':
        return colorScheme.primaryContainer;
      case 'Asthma':
        return colorScheme.primaryContainer.withOpacity(0.7);
      case 'I don\'t have any':
        return colorScheme.primary.withOpacity(0.2);
      default:
        return colorScheme.surfaceContainerHighest; // Changed from surface to surfaceVariant
    }
  }

  Widget _getConditionIcon(String condition, ColorScheme colorScheme) {
    switch (condition) {
      case 'Hypertension':
        return Icon(Icons.monitor_heart, size: 32, color: colorScheme.error);
      case 'High Cholesterol':
        return Icon(Icons.water_drop, size: 32, color: colorScheme.error);
      case 'Obesity':
        return Icon(Icons.monitor_weight, size: 32, color: colorScheme.tertiary ?? colorScheme.secondary);
      case 'Diabetes':
        return Icon(Icons.bloodtype, size: 32, color: colorScheme.secondary);
      case 'Heart Disease':
        return Icon(Icons.favorite, size: 32, color: colorScheme.error);
      case 'Arthritis':
        return Icon(Icons.accessibility, size: 32, color: colorScheme.primary);
      case 'Asthma':
        return Icon(Icons.air, size: 32, color: colorScheme.primary);
      case 'I don\'t have any':
        return Icon(Icons.health_and_safety, size: 32, color: colorScheme.primary);
      default:
        return Icon(Icons.medical_services, size: 32, color: colorScheme.primary);
    }
  }

  Widget _buildHealthIndicator(String label, bool isActive, ColorScheme colorScheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? colorScheme.primary.withOpacity(0.2) : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? colorScheme.primary : colorScheme.primary.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 20,
                  color: isActive
                      ? colorScheme.primary
                      : colorScheme.primary.withOpacity(0.6),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}