import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'package:fyp/LocalDB.dart';
import 'ActivityPage.dart';
import 'HealthConcernPage.dart';

class WorkSchedulePage extends StatefulWidget {
  const WorkSchedulePage({super.key});

  @override
  State<WorkSchedulePage> createState() => _CreativeWorkSchedulePageState();
}

class _CreativeWorkSchedulePageState extends State<WorkSchedulePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Color?> _bgColorAnimation;

  String? selectedSchedule;

  final Map<String, String> scheduleIcons = {
    'Flexible': '🕒',
    'Nine to five': '🏢',
    'Shift work': '🔄',
    'Strict working hours': '⏱️',
    'Between jobs or unemployed': '🏖️',
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

              // Floating schedule emojis
              const Positioned(
                top: 100,
                left: 30,
                child: AnimatedOpacity(
                  duration: Duration(seconds: 2),
                  opacity: 0.6,
                  child: Text('🕒', style: TextStyle(fontSize: 40)),
                ),
              ),
              const Positioned(
                top: 80,
                right: 40,
                child: AnimatedOpacity(
                  duration: Duration(seconds: 3),
                  opacity: 0.6,
                  child: Text('🏢', style: TextStyle(fontSize: 50)),
                ),
              ),
              const Positioned(
                bottom: 200,
                left: 50,
                child: AnimatedOpacity(
                  duration: Duration(seconds: 2),
                  opacity: 0.6,
                  child: Text('🔄', style: TextStyle(fontSize: 45)),
                ),
              ),
              const Positioned(
                bottom: 180,
                right: 60,
                child: AnimatedOpacity(
                  duration: Duration(seconds: 3),
                  opacity: 0.6,
                  child: Text('⏱️', style: TextStyle(fontSize: 48)),
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
                              'What\'s your work schedule?',
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
                              'Select your typical work pattern to help us customize your plan',
                              style: textTheme.titleMedium?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Schedule Options
                          ...scheduleIcons.keys.map((schedule) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.only(bottom: 16),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedSchedule = schedule;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: selectedSchedule == schedule
                                        ? _getScheduleColor(schedule, colorScheme)
                                        : colorScheme.surface,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: colorScheme.primary.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: selectedSchedule == schedule
                                          ? colorScheme.primary
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      AnimatedScale(
                                        duration: const Duration(milliseconds: 200),
                                        scale: selectedSchedule == schedule ? 1.2 : 1.0,
                                        child: Text(
                                          scheduleIcons[schedule]!,
                                          style: const TextStyle(fontSize: 36),
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      Expanded(
                                        child: Text(
                                          schedule,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                      if (selectedSchedule == schedule)
                                        Icon(
                                          Icons.check_circle_rounded,
                                          color: colorScheme.primary,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),

                          const SizedBox(height: 24),

                          // Schedule Visualization
                          if (selectedSchedule != null)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              height: 80,
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: _buildScheduleVisualization(selectedSchedule!, colorScheme),
                              ),
                            ),

                          // Continue Button
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: Material(
                              borderRadius: BorderRadius.circular(30),
                              elevation: 5,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(30),
                                onTap: selectedSchedule == null
                                    ? null
                                    : ()async {
                                       await LocalDB.setScheduleIcons(selectedSchedule!);

                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => const HealthConcernsPage()),
                                        );
                                      },
                                child: Container(
                                  width: double.infinity,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30),
                                    gradient: selectedSchedule != null
                                        ? LinearGradient(
                                            colors: [
                                              colorScheme.primary,
                                              colorScheme.secondary,
                                            ],
                                          )
                                        : LinearGradient(
                                            colors: [
                                              Colors.grey[300]!,
                                              Colors.grey[400]!,
                                            ],
                                          ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'CONTINUE',
                                      style: textTheme.titleLarge?.copyWith(
                                        color: selectedSchedule != null
                                            ? Colors.white
                                            : Colors.grey[600],
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

  Color _getScheduleColor(String schedule, ColorScheme colorScheme) {
    switch (schedule) {
      case 'Flexible':
        return colorScheme.secondaryContainer;
      case 'Nine to five':
        return colorScheme.tertiaryContainer ?? colorScheme.secondaryContainer;
      case 'Shift work':
        return colorScheme.primaryContainer;
      case 'Strict working hours':
        return colorScheme.primary.withOpacity(0.2);
      case 'Between jobs or unemployed':
        return colorScheme.errorContainer;
      default:
        return colorScheme.surface;
    }
  }

  Widget _buildScheduleVisualization(String schedule, ColorScheme colorScheme) {
    switch (schedule) {
      case 'Flexible':
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTimeBlock('9AM', false, colorScheme),
            _buildTimeBlock('12PM', true, colorScheme),
            _buildTimeBlock('3PM', false, colorScheme),
            _buildTimeBlock('6PM', false, colorScheme),
          ],
        );
      case 'Nine to five':
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTimeBlock('9AM', true, colorScheme),
            _buildTimeBlock('12PM', true, colorScheme),
            _buildTimeBlock('3PM', true, colorScheme),
            _buildTimeBlock('5PM', true, colorScheme),
          ],
        );
      case 'Shift work':
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTimeBlock('6AM', true, colorScheme),
            _buildTimeBlock('OFF', false, colorScheme),
            _buildTimeBlock('2PM', true, colorScheme),
            _buildTimeBlock('OFF', false, colorScheme),
          ],
        );
      case 'Strict working hours':
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTimeBlock('8AM', true, colorScheme),
            _buildTimeBlock('12PM', true, colorScheme),
            _buildTimeBlock('1PM', true, colorScheme),
            _buildTimeBlock('5PM', true, colorScheme),
          ],
        );
      case 'Between jobs or unemployed':
        return Text(
          'Enjoy your free time!',
          style: TextStyle(
            fontSize: 18,
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildTimeBlock(String time, bool isWorking, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isWorking ? colorScheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colorScheme.primary,
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                time,
                style: TextStyle(
                  color: isWorking ? colorScheme.onPrimary : colorScheme.primary,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isWorking ? 'Work' : 'Free',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}