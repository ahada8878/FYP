import 'package:fyp/HomePage.dart';
import 'package:fyp/LoadingPage.dart';
import 'package:fyp/LocalDB.dart';
import 'package:fyp/models/user_details.dart';

import 'EatingStylePage.dart';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'dart:math' as math;
import '../HomePage.dart';

class MealTimingPage extends StatefulWidget {
  const MealTimingPage({super.key});

  @override
  State<MealTimingPage> createState() => _MealTimingPageState();
}

class _MealTimingPageState extends State<MealTimingPage>
    with SingleTickerProviderStateMixin {
  String? _startTime;
  String? _endTime;
  late AnimationController _controller;
  late ConfettiController _confettiController;
  double _clockScale = 1.0;
  bool _isDayTime = true;

  final List<Map<String, dynamic>> _startTimes = [
    {'time': '08:00', 'period': 'AM', 'isDay': true},
    {'time': '09:30', 'period': 'AM', 'isDay': true},
    {'time': '10:00', 'period': 'AM', 'isDay': true},
    {'time': '12:00', 'period': 'PM', 'isDay': true},
    {'time': '01:30', 'period': 'PM', 'isDay': true},
  ];

  final List<Map<String, dynamic>> _endTimes = [
    {'time': '08:00', 'period': 'PM', 'isDay': false},
    {'time': '09:30', 'period': 'PM', 'isDay': false},
    {'time': '10:00', 'period': 'PM', 'isDay': false},
    {'time': '11:30', 'period': 'PM', 'isDay': false},
    {'time': '12:00', 'period': 'AM', 'isDay': false},
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _controller.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _selectTime(String time, bool isStartTime) {
    setState(() {
      if (isStartTime) {
        _startTime = time;
        _isDayTime = _startTimes.firstWhere(
            (t) => t['time'] + t['period'] == time)['isDay'] as bool;
      } else {
        _endTime = time;
      }

      if (_startTime != null && _endTime != null) {
        _confettiController.play();
      }

      _controller.reset();
      _controller.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;

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
                  _isDayTime ? Colors.blue[100]! : Colors.indigo[900]!,
                  colorScheme.surface,
                ],
              ),
            ),
          ),

          // Stars for night time
          if (!_isDayTime) ...[
            for (int i = 0; i < 30; i++)
              Positioned(
                left: math.Random().nextDouble() * screenWidth,
                top: math.Random().nextDouble() * 200,
                child: Icon(
                  Icons.star,
                  size: math.Random().nextDouble() * 3 + 1,
                  color: Colors.white
                      .withOpacity(math.Random().nextDouble() * 0.5 + 0.5),
                ),
              ),
          ],

          // Sun/Moon
          Positioned(
            right: 30,
            top: 100,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: _isDayTime
                  ? Icon(Icons.wb_sunny,
                      key: const ValueKey('sun'), size: 60, color: Colors.amber)
                  : Icon(Icons.nightlight_round,
                      key: const ValueKey('moon'),
                      size: 60,
                      color: Colors.white),
            ),
          ),

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
                          'Your Meal Times',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onBackground,
                            shadows: [
                              Shadow(
                                color: colorScheme.primary.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'When do you usually eat?',
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.onBackground.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Clock animation
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _clockScale = _clockScale == 1.0 ? 1.1 : 1.0;
                          });
                        },
                        child: AnimatedScale(
                          scale: _clockScale,
                          duration: const Duration(milliseconds: 300),
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isDayTime
                                  ? Colors.amber[100]
                                  : Colors.indigo[800],
                              border: Border.all(
                                color:
                                    _isDayTime ? Colors.amber : Colors.indigo,
                                width: 4,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.access_time,
                                size: 60,
                                color: _isDayTime
                                    ? Colors.amber[800]
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Start time selection
                      _TimeSelectionSection(
                        title: 'I usually start eating at...',
                        times: _startTimes,
                        selectedTime: _startTime,
                        onTimeSelected: (time) => _selectTime(time, true),
                        isDay: _isDayTime,
                      ),
                      const SizedBox(height: 30),

                      // End time selection
                      _TimeSelectionSection(
                        title: 'And finish my last meal by...',
                        times: _endTimes,
                        selectedTime: _endTime,
                        onTimeSelected: (time) => _selectTime(time, false),
                        isDay: _isDayTime,
                      ),

                      const SizedBox(height: 40),
                      // Continue button
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        width: double.infinity,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          gradient: _startTime != null && _endTime != null
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
                              color: _startTime != null && _endTime != null
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
                            onTap: _startTime != null && _endTime != null
                                ? () async{
                                    _confettiController.play();
                                    //_startTimes,_endTimes both are maps 
                                    await LocalDB.setStartTimes(_startTimes);
                                    await LocalDB.setEndTimes(_endTimes);

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const FoodieAnalysisPage(),
                                      ),
                                    );
                                  }
                                : null,
                            child: Center(
                              child: Text(
                                'CONTINUE',
                                style: TextStyle(
                                  color: _startTime != null && _endTime != null
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
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.orange,
                Colors.yellow
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeSelectionSection extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> times;
  final String? selectedTime;
  final Function(String) onTimeSelected;
  final bool isDay;

  const _TimeSelectionSection({
    required this.title,
    required this.times,
    required this.selectedTime,
    required this.onTimeSelected,
    required this.isDay,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: times.map((timeData) {
            final timeStr = timeData['time'] + timeData['period'];
            final isSelected = selectedTime == timeStr;

            return GestureDetector(
              onTap: () => onTimeSelected(timeStr),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDay
                          ? Colors.amber.withOpacity(0.2)
                          : Colors.indigo.withOpacity(0.2))
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? (isDay ? Colors.amber : Colors.indigo)
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.2),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? (isDay
                              ? Colors.amber.withOpacity(0.3)
                              : Colors.indigo.withOpacity(0.3))
                          : Colors.transparent,
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isDay ? Icons.sunny : Icons.nightlight,
                      size: 16,
                      color: isSelected
                          ? (isDay ? Colors.amber[800] : Colors.indigo[100])
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.5),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeData['time'],
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? (isDay ? Colors.amber[800] : Colors.indigo[100])
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      timeData['period'],
                      style: TextStyle(
                        fontSize: 14,
                        color: isSelected
                            ? (isDay ? Colors.amber[800] : Colors.indigo[100])
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
