import 'dart:math';
import 'package:flutter/material.dart';
import 'BMIPage.dart';

class AITrackerPage extends StatefulWidget {
  const AITrackerPage({super.key});

  @override
  State<AITrackerPage> createState() => _AITrackerPageState();
}

class _AITrackerPageState extends State<AITrackerPage>
    with TickerProviderStateMixin {
  late final List<_FloatingIconController> _floatingControllers;

  @override
  void initState() {
    super.initState();
    _floatingControllers = [
      _FloatingIconController(Icons.local_pizza, -60, -40, 0.5, this),
      _FloatingIconController(Icons.fastfood, 70, -30, 0.7, this),
      _FloatingIconController(Icons.local_dining, -50, 60, 0.6, this),
      _FloatingIconController(Icons.cake, 60, 50, 0.8, this),
    ];
    for (var controller in _floatingControllers) {
      controller.start();
    }
  }

  @override
  void dispose() {
    for (var controller in _floatingControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  List<Widget> _buildFloatingFoodIcons(ColorScheme colorScheme) {
    return _floatingControllers.map((c) => c.build(colorScheme)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          // Gradient Background
          AnimatedContainer(
            duration: const Duration(seconds: 2),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colorScheme.surfaceVariant.withOpacity(0.8),
                  colorScheme.surface,
                ],
              ),
            ),
          ),

          // Main Content
          Column(
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: colorScheme.onBackground),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                child: Column(
                  children: [
                    Text(
                      "Let's prepare your meals",
                      style: TextStyle(
                        color: colorScheme.onBackground,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "effortlessly!",
                      style: TextStyle(
                        color: colorScheme.onBackground,
                        fontSize: 24,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),

              // Visualization
              Expanded(
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Simulated Pulse (non-looping Tween)
                      TweenAnimationBuilder<double>(
                        duration: const Duration(seconds: 2),
                        tween: Tween<double>(begin: 0, end: 1),
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: 1 + 0.2 * value,
                            child: Opacity(
                              opacity: 1 - value,
                              child: Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: colorScheme.primary.withOpacity(0.1),
                                ),
                              ),
                            ),
                          );
                        },
                        onEnd: () {}, // Optional
                      ),

                      Icon(
                        Icons.auto_awesome,
                        size: 100,
                        color: colorScheme.primary,
                      ),

                      ..._buildFloatingFoodIcons(colorScheme),
                    ],
                  ),
                ),
              ),

              // Description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    Text(
                      "Our revolutionary AI tracker makes",
                      style: TextStyle(
                        color: colorScheme.onBackground,
                        fontSize: 18,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      "the weight loss process much easier",
                      style: TextStyle(
                        color: colorScheme.onBackground,
                        fontSize: 18,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildFeatureChip(
                            "Meal Planning", Icons.restaurant, colorScheme),
                        _buildFeatureChip("Nutrition Tracking",
                            Icons.monitor_heart, colorScheme),
                        _buildFeatureChip(
                            "Smart Grocery", Icons.shopping_cart, colorScheme),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // CTA Button
              Padding(
                padding: const EdgeInsets.all(24),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 48, vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 4,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => PersonalSummaryPage()),
                    );
                  },
                  child: Text(
                    "LET'S GO!",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimary,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(
      String text, IconData icon, ColorScheme colorScheme) {
    return Chip(
      backgroundColor: colorScheme.surfaceVariant,
      avatar: Icon(
        icon,
        color: colorScheme.primary,
        size: 20,
      ),
      label: Text(
        text,
        style: TextStyle(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _FloatingIconController {
  final IconData icon;
  final double x, y, delay;
  final TickerProvider vsync;

  late final AnimationController controller;
  late final Animation<double> animation;

  _FloatingIconController(this.icon, this.x, this.y, this.delay, this.vsync) {
    controller = AnimationController(
      vsync: vsync,
      duration: const Duration(seconds: 4),
    );
    animation = CurvedAnimation(parent: controller, curve: Curves.linear);
  }

  void start() async {
    await Future.delayed(Duration(milliseconds: (delay * 1000).round()));
    controller.repeat();
  }

  Widget build(ColorScheme colorScheme) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final angle = animation.value * 2 * pi;
        return Transform.translate(
          offset: Offset(x * cos(angle), y * sin(angle)),
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: colorScheme.primary,
          size: 24,
        ),
      ),
    );
  }

  void dispose() {
    controller.dispose();
  }
}
