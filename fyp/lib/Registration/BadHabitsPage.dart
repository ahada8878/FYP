import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:fyp/LocalDB.dart';
import 'MealPerDayPage.dart';

class BadHabitsPage extends StatefulWidget {
  const BadHabitsPage({super.key});

  @override
  State<BadHabitsPage> createState() => _BadHabitsPageState();
}

class _BadHabitsPageState extends State<BadHabitsPage>
    with SingleTickerProviderStateMixin {
  final Set<int> _selectedHabits = {};
  late AnimationController _animationController;
  late Animation<double> _titleScale;
  late Animation<double> _emojiBounce;
  late ConfettiController _confettiController;

  final List<Map<String, dynamic>> habits = [
    {
      'text': 'I love chocolate and candy',
      'emoji': '🍫',
      'color': const Color(0xFF7B3F00),
      'icon': Icons.cake,
    },
    {
      'text': 'Soda is my best friend',
      'emoji': '🥤',
      'color': const Color(0xFF00B4D8),
      'icon': Icons.local_drink,
    },
    {
      'text': 'I consume salty food',
      'emoji': '🍟',
      'color': const Color(0xFFF4A261),
      'icon': Icons.fastfood,
    },
    {
      'text': "I'm a midnight snacker",
      'emoji': '🌙',
      'color': const Color(0xFF560BAD),
      'icon': Icons.nightlight,
    },
    {
      'text': 'Junk food is my pleasure',
      'emoji': '🍔',
      'color': const Color(0xFFE63946),
      'icon': Icons.emoji_food_beverage,
    },
  ];

  @override
  void initState() {
    super.initState();

    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _titleScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.1), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 50),
    ]).animate(_animationController);

    _emojiBounce = Tween<double>(begin: 0.0, end: -20.0)
        .chain(
          CurveTween(curve: Curves.elasticOut),
        )
        .animate(_animationController);

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _toggleHabit(int index) {
    setState(() {
      if (_selectedHabits.contains(index)) {
        _selectedHabits.remove(index);
      } else {
        _selectedHabits.add(index);
        if (_animationController.status == AnimationStatus.completed ||
            _animationController.status == AnimationStatus.dismissed) {
          _animationController.forward(from: 0.0);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary.withOpacity(0.1),
                  colorScheme.surfaceContainerHighest.withOpacity(0.8),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.red,
                Colors.blue,
                Colors.green,
                Colors.yellow,
                Colors.purple,
              ],
            ),
          ),
          ...List.generate(10, (index) {
            return Positioned(
              left: math.Random().nextDouble() *
                  MediaQuery.of(context).size.width,
              top: math.Random().nextDouble() *
                  MediaQuery.of(context).size.height,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 500),
                opacity: _selectedHabits.isNotEmpty ? 0.3 : 0.1,
                child: Text(
                  ['🍕', '🍔', '🍟', '🍫', '🥤'][index % 5],
                  style: TextStyle(
                    fontSize: 24 + (index * 2).toDouble(),
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
                 
                  actions: [
                    if (_selectedHabits.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.celebration),
                        onPressed: () => _confettiController.play(),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ScaleTransition(
                        scale: _titleScale,
                        child: Text(
                          'We all have some',
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
                        'bad eating habits',
                        style: textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                          height: 0.9,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'What are yours?',
                        style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.8),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 40),
                      Center(
                        child: AnimatedBuilder(
                          animation: _emojiBounce,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, _emojiBounce.value),
                              child: Text(
                                _selectedHabits.isEmpty ? '😊' : '😬',
                                style: const TextStyle(fontSize: 60),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 40),
                      ...List.generate(habits.length, (index) {
                        final habit = habits[index];
                        final isSelected = _selectedHabits.contains(index);
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: isSelected
                                ? habit['color'].withOpacity(0.2)
                                : colorScheme.surfaceContainerHighest,
                            border: Border.all(
                              color: isSelected
                                  ? habit['color']
                                  : Colors.transparent,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected
                                    ? habit['color'].withOpacity(0.3)
                                    : Colors.transparent,
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => _toggleHabit(index),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? habit['color'].withOpacity(0.3)
                                            : colorScheme.onSurface
                                                .withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          habit['emoji'],
                                          style: const TextStyle(fontSize: 28),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        habit['text'],
                                        style: textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      child: isSelected
                                          ? Icon(
                                              Icons.check_circle,
                                              color: habit['color'],
                                              size: 30,
                                            )
                                          : const SizedBox(width: 30),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 40),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        width: double.infinity,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          gradient: _selectedHabits.isNotEmpty
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
                              color: _selectedHabits.isNotEmpty
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
                            onTap: _selectedHabits.isNotEmpty
                                ? ()async {

                                    _confettiController.play();
                            await LocalDB.setSelectedHabits(_selectedHabits);

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const MealsPerDayPage()),
                                    );
                                  }
                                : null,
                            child: Center(
                              child: Text(
                                'CONTINUE',
                                style: textTheme.titleLarge?.copyWith(
                                  color: _selectedHabits.isNotEmpty
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
