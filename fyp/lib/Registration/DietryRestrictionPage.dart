import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:fyp/LocalDB.dart';
import 'dart:math' as math;
import 'EatingStylePage.dart';

class DietaryRestrictionsPage extends StatefulWidget {
  const DietaryRestrictionsPage({super.key});

  @override
  State<DietaryRestrictionsPage> createState() =>
      _DietaryRestrictionsPageState();
}

class _DietaryRestrictionsPageState extends State<DietaryRestrictionsPage>
    with SingleTickerProviderStateMixin {
  final Map<String, bool> _restrictions = {
    'Lactose Free': false,
    'Sugar Free': false,
    'Gluten Free': false,
    'Nut Free': false,
    'None': false,
  };

  late AnimationController _controller;
  late ConfettiController _confettiController;
  final List<String> _foodCharacters = ['🥛', '🍭', '🍞', '🥜', '🎉'];
  String _currentCharacter = '';
  double _characterBounce = 0;
  List<Offset> _randomPositions = [];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..addListener(() {
        setState(() {
          _characterBounce = math.sin(_controller.value * math.pi * 2) * 10;
        });
      });

    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateRandomPositions();
    });
  }

  void _generateRandomPositions() {
    final screenSize = MediaQuery.of(context).size;
    final rand = math.Random();

    setState(() {
      _randomPositions = List.generate(15, (index) {
        double left = rand.nextDouble() * screenSize.width;
        double top = rand.nextDouble() * screenSize.height;
        return Offset(left, top);
      });
    });
  }

  void _toggleRestriction(String restriction) {
    setState(() {
      if (restriction == 'None') {
        _restrictions.forEach((key, value) {
          _restrictions[key] = key == 'None';
        });
        _currentCharacter = '🎉';
      } else {
        _restrictions[restriction] = !_restrictions[restriction]!;
        _restrictions['None'] = false;
        _currentCharacter =
            _foodCharacters[_restrictions.keys.toList().indexOf(restriction)];
      }

      _controller.reset();
      _controller.forward();

      if (restriction == 'None' || !_restrictions.values.any((v) => v)) {
        _confettiController.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _restrictions['None']!
                      ? Colors.green[100]!
                      : colorScheme.primary.withOpacity(0.1),
                  colorScheme.surface,
                ],
              ),
            ),
          ),

          // Floating food emojis
          ..._randomPositions.map((position) {
            int index = _randomPositions.indexOf(position);
            return Positioned(
              left: position.dx,
              top: position.dy,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 500),
                opacity: _restrictions.values.any((v) => v) ? 0.3 : 0.1,
                child: Text(
                  ['🍎', '🥑', '🍗', '🥦', '🍕'][index % 5],
                  style: TextStyle(fontSize: 16 + (index * 2).toDouble()),
                ),
              ),
            );
          }).toList(),

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
                            parent: _controller,
                            curve: Curves.elasticOut,
                          ),
                        ),
                        child: Text(
                          'Dietary Restrictions',
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
                        'Tell us about your food preferences',
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.onBackground.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 40),

                      Transform.translate(
                        offset: Offset(0, _characterBounce),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            _currentCharacter.isEmpty
                                ? '🍽️'
                                : _currentCharacter,
                            key: ValueKey<String>(_currentCharacter),
                            style: const TextStyle(fontSize: 80),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Dietary options
                      ..._restrictions.keys.map(
                        (restriction) => _DietaryOptionCard(
                          label: restriction,
                          isSelected: _restrictions[restriction]!,
                          color: _getColor(restriction),
                          onTap: () => _toggleRestriction(restriction),
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
                          gradient: _restrictions.values.any((v) => v)
                              ? LinearGradient(
                                  colors: [
                                    colorScheme.primary,
                                    colorScheme.secondary,
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
                              color: _restrictions.values.any((v) => v)
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
                            onTap: _restrictions.values.any((v) => v)
                                ? ()async {
                                    _confettiController.play();
                                   await LocalDB.setRestrictions(_restrictions);

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              EatingStylePage()),
                                    );
                                  }
                                : null,
                            child: Center(
                              child: Text(
                                'CONTINUE',
                                style: TextStyle(
                                  color: _restrictions.values.any((v) => v)
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

  Color _getColor(String restriction) {
    switch (restriction) {
      case 'Lactose Free':
        return Colors.blue;
      case 'Sugar Free':
        return Colors.red;
      case 'Gluten Free':
        return Colors.orange;
      case 'Nut Free':
        return Colors.brown;
      case 'None':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

class _DietaryOptionCard extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _DietaryOptionCard({
    required this.label,
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
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: isSelected ? color : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
