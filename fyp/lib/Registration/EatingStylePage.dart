import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:fyp/LocalDB.dart';
import 'dart:math' as math;
import 'DietryRestrictionPage.dart';
import 'EatingTime.dart';

class EatingStylePage extends StatefulWidget {
  const EatingStylePage({super.key});

  @override
  State<EatingStylePage> createState() => _EatingStylePageState();
}

class _EatingStylePageState extends State<EatingStylePage>
    with SingleTickerProviderStateMixin {
  final Map<String, bool> _eatingStyles = {
    'I eat everything': false,
    'Vegan': false,
    'Vegetarian': false,
    'Keto': false,
    'Paleo': false,
  };

  late AnimationController _controller;
  late ConfettiController _confettiController;
  final Map<String, String> _styleIcons = {
    'I eat everything': '🍽️',
    'Vegan': '🌱',
    'Vegetarian': '🥗',
    'Keto': '🥩',
    'Paleo': '🍖',
  };
  String _currentIcon = '🍽️';
  double _iconBounce = 0;

  final List<Offset> _particlePositions = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..addListener(() {
        setState(() {
          _iconBounce = math.sin(_controller.value * math.pi * 2) * 15;
        });
      });

    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));

    // Generate food particle positions once
    final screenWidth = 400.0;
    final screenHeight = 800.0;
    final random = math.Random();
    for (int i = 0; i < 15; i++) {
      _particlePositions.add(
        Offset(
          random.nextDouble() * screenWidth,
          random.nextDouble() * screenHeight,
        ),
      );
    }
  }

  void _toggleStyle(String style) {
    setState(() {
      _eatingStyles.updateAll((key, value) => key == style);
      _currentIcon = _styleIcons[style]!;
      _controller.reset();
      _controller.forward();
      if (style == 'I eat everything') {
        _confettiController.play();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _eatingStyles['I eat everything']!
                      ? Colors.amber[100]!
                      : colorScheme.primary.withOpacity(0.1),
                  colorScheme.surface,
                ],
              ),
            ),
          ),

          // Floating food particles
          ..._particlePositions.asMap().entries.map((entry) {
            final index = entry.key;
            final pos = entry.value;
            return Positioned(
              left: pos.dx,
              top: pos.dy,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 500),
                opacity: _eatingStyles.values.any((v) => v) ? 0.3 : 0.1,
                child: Text(
                  ['🍎', '🥑', '🍗', '🥦', '🍕'][index % 5],
                  style: TextStyle(fontSize: 16 + (index * 2).toDouble()),
                ),
              ),
            );
          }),

          // Main content
          Column(
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
               
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // Title
                      ScaleTransition(
                        scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                          CurvedAnimation(
                              parent: _controller, curve: Curves.elasticOut),
                        ),
                        child: Text(
                          'Your Eating Style',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onBackground,
                            shadows: [
                              Shadow(
                                color: colorScheme.primary.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'How do you prefer to eat?',
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.onBackground.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Food icon
                      Transform.translate(
                        offset: Offset(0, _iconBounce),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            _currentIcon,
                            key: ValueKey<String>(_currentIcon),
                            style: const TextStyle(fontSize: 80),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Options
                      ..._eatingStyles.keys.map(
                        (style) => _EatingStyleCard(
                          label: style,
                          icon: _styleIcons[style]!,
                          isSelected: _eatingStyles[style]!,
                          color: _getColor(style),
                          onTap: () => _toggleStyle(style),
                        ),
                      ),

                      const SizedBox(height: 40),
                      // Continue button
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        width: double.infinity,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          gradient: _eatingStyles.values.any((v) => v)
                              ? LinearGradient(colors: [
                                  colorScheme.primary,
                                  colorScheme.secondary
                                ])
                              : LinearGradient(colors: [
                                  colorScheme.onSurface.withOpacity(0.1),
                                  colorScheme.onSurface.withOpacity(0.1),
                                ]),
                          boxShadow: [
                            BoxShadow(
                              color: _eatingStyles.values.any((v) => v)
                                  ? colorScheme.primary.withOpacity(0.4)
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
                            onTap: () async{
                              // _eatingStyles map
                                await LocalDB.setEatingStyles(_eatingStyles);
                                

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              MealTimingPage()),
                                    );
                                  },
                            child: Center(
                              child: Text(
                                'CONTINUE',
                                style: TextStyle(
                                  color: _eatingStyles.values.any((v) => v)
                                      ? Colors.white
                                      : colorScheme.onSurface.withOpacity(0.5),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              colors: const [Colors.green, Colors.blue, Colors.orange],
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor(String style) {
    switch (style) {
      case 'I eat everything':
        return Colors.amber;
      case 'Vegan':
        return Colors.green;
      case 'Vegetarian':
        return Colors.lightGreen;
      case 'Keto':
        return Colors.deepOrange;
      case 'Paleo':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }
}

class _EatingStyleCard extends StatelessWidget {
  final String label;
  final String icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _EatingStyleCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? color.withOpacity(0.2)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? color : Colors.black,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? color : Colors.transparent,
                border: Border.all(
                  color: isSelected ? color : Colors.grey,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
