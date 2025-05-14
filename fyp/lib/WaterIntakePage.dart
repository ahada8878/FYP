import 'MealPerDayPage.dart';

import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'dart:math' as math;
import 'DietryRestrictionPage.dart';

class WaterIntakePage extends StatefulWidget {
  const WaterIntakePage({super.key});

  @override
  State<WaterIntakePage> createState() => _WaterIntakePageState();
}

class _WaterIntakePageState extends State<WaterIntakePage>
    with SingleTickerProviderStateMixin {
  int? _selectedOption;
  late AnimationController _animationController;
  late Animation<double> _waveAnimation;
  late Animation<double> _scaleAnimation;

  final List<Map<String, dynamic>> waterOptions = [
    {
      'title': '2 Glasses',
      'subtitle': 'Minimal hydration',
      'icon': Icons.water_drop_outlined,
      'color': Colors.blue[200]!,
      'waterLevel': 0.2,
    },
    {
      'title': '2 to 6 Glasses',
      'subtitle': 'Moderate hydration',
      'icon': Icons.water_drop_rounded,
      'color': Colors.blue[400]!,
      'waterLevel': 0.5,
    },
    {
      'title': '6+ Glasses',
      'subtitle': 'Optimal hydration',
      'icon': Icons.water,
      'color': Colors.blue[600]!,
      'waterLevel': 0.8,
    },
    {
      'title': 'Other drinks',
      'subtitle': 'Mostly non-water',
      'icon': Icons.local_cafe,
      'color': Colors.brown[300]!,
      'waterLevel': 0.1,
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _waveAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _selectOption(int index) {
    setState(() {
      _selectedOption = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        children: [
          // **Background Gradient**
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _selectedOption != null
                      ? waterOptions[_selectedOption!]['color'].withOpacity(0.1)
                      : colorScheme.surfaceVariant.withOpacity(0.2),
                  colorScheme.surface,
                ],
              ),
            ),
          ),

          // **Floating Water Droplets**
          ...List.generate(10, (index) {
            return Positioned(
              left: math.Random().nextDouble() *
                  MediaQuery.of(context).size.width,
              top: math.Random().nextDouble() *
                  MediaQuery.of(context).size.height,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 500),
                opacity: _selectedOption != null ? 0.3 : 0.1,
                child: Icon(
                  Icons.water_drop,
                  size: 24,
                  color: Colors.blue[200],
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
                  leading: IconButton(
                    icon:
                        Icon(Icons.arrow_back, color: colorScheme.onBackground),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // **Animated Title**
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Text(
                          'What is your',
                          style: textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onBackground,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'daily water intake?',
                        style: textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Stay hydrated for better health!',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onBackground.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // **Water Option Cards**
                      ...List.generate(waterOptions.length, (index) {
                        final option = waterOptions[index];
                        final isSelected = _selectedOption == index;

                        return GestureDetector(
                          onTap: () => _selectOption(index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? option['color'].withOpacity(0.1)
                                  : colorScheme.surfaceVariant,
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
                            child: Row(
                              children: [
                                // **Animated Water Glass**
                                AnimatedBuilder(
                                  animation: _waveAnimation,
                                  builder: (context, child) {
                                    return CustomPaint(
                                      size: const Size(60, 80),
                                      painter: _WaterGlassPainter(
                                        waterLevel: option['waterLevel'],
                                        waveValue: _waveAnimation.value,
                                        color: option['color'],
                                        isSelected: isSelected,
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        option['title'],
                                        style: textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.onBackground,
                                        ),
                                      ),
                                      Text(
                                        option['subtitle'],
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.onBackground
                                              .withOpacity(0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check_circle,
                                    color: option['color'],
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),

                      const SizedBox(height: 40),

                      // **Continue Button**
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        width: double.infinity,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          gradient: _selectedOption != null
                              ? LinearGradient(
                                  colors: [
                                    waterOptions[_selectedOption!]['color'],
                                    waterOptions[_selectedOption!]['color']
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
                                  ? waterOptions[_selectedOption!]['color']
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
                                ? () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              DietaryRestrictionsPage()),
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

// **Custom Water Glass Painter**
class _WaterGlassPainter extends CustomPainter {
  final double waterLevel;
  final double waveValue;
  final Color color;
  final bool isSelected;

  _WaterGlassPainter({
    required this.waterLevel,
    required this.waveValue,
    required this.color,
    required this.isSelected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final glassPath = Path()
      ..moveTo(size.width * 0.2, 0)
      ..lineTo(size.width * 0.8, 0)
      ..lineTo(size.width * 0.9, size.height)
      ..lineTo(size.width * 0.1, size.height)
      ..close();

    // Draw glass outline
    canvas.drawPath(glassPath, paint);

    // Draw water with wave effect
    final waterPaint = Paint()..color = color.withOpacity(0.6);
    final waterPath = Path();

    final waveHeight = isSelected ? 5.0 : 2.0;
    final baseWaterLevel = size.height * (1 - waterLevel);

    waterPath.moveTo(0, baseWaterLevel);

    for (double x = 0; x <= size.width; x++) {
      final y = baseWaterLevel + math.sin(waveValue + x * 0.1) * waveHeight;
      waterPath.lineTo(x, y);
    }

    waterPath.lineTo(size.width * 0.9, size.height);
    waterPath.lineTo(size.width * 0.1, size.height);
    waterPath.close();

    canvas.drawPath(waterPath, waterPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
