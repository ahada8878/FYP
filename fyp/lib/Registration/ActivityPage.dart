import 'package:flutter/material.dart';
import 'package:fyp/LocalDB.dart';
import 'package:fyp/Registration/WorkSchedulePage.dart';

class ActivityPage extends StatefulWidget {
  const 
  
  ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _CreativeActivityPageState();
}

class _CreativeActivityPageState extends State<ActivityPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Color?> _bgColorAnimation;

  int? selectedLevel;

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

    final List<Map<String, dynamic>> activityLevels = [
      {
        'title': 'Not Very Active',
        'description': 'I spend most of my day sitting',
        'icon': '🪑',
        'color': colorScheme.secondaryContainer,
      },
      {
        'title': 'Somewhat Active',
        'description': 'I exercise occasionally but not regularly',
        'icon': '🚶‍♂️',
        'color': colorScheme.tertiaryContainer ?? colorScheme.secondaryContainer,
      },
      {
        'title': 'Active',
        'description': 'I work on my feet and move around throughout the day',
        'icon': '🏃‍♀️',
        'color': colorScheme.primaryContainer,
      },
      {
        'title': 'Very Active',
        'description': 'I spend most of my day doing physical activities',
        'icon': '🏋️',
        'color': colorScheme.primary.withOpacity(0.2),
      },
    ];

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

              // Floating activity emojis
              const Positioned(
                top: 100,
                left: 30,
                child: AnimatedOpacity(
                  duration: Duration(seconds: 2),
                  opacity: 0.6,
                  child: Text('🪑', style: TextStyle(fontSize: 40)),
                ),
              ),
              const Positioned(
                top: 80,
                right: 40,
                child: AnimatedOpacity(
                  duration: Duration(seconds: 3),
                  opacity: 0.6,
                  child: Text('🏃‍♀️', style: TextStyle(fontSize: 50)),
                ),
              ),
              const Positioned(
                bottom: 200,
                left: 50,
                child: AnimatedOpacity(
                  duration: Duration(seconds: 2),
                  opacity: 0.6,
                  child: Text('🏋️', style: TextStyle(fontSize: 45)),
                ),
              ),
              const Positioned(
                bottom: 180,
                right: 60,
                child: AnimatedOpacity(
                  duration: Duration(seconds: 3),
                  opacity: 0.6,
                  child: Text('🚶‍♂️', style: TextStyle(fontSize: 48)),
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
                              'What\'s your current activity level?',
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
                              'Select the option that best describes your daily movement',
                              style: textTheme.titleMedium?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Activity Level Cards
                          ...activityLevels.map((level) {
                            final index = activityLevels.indexOf(level);
                            final isSelected = selectedLevel == index;
                            
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.only(bottom: 16),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedLevel = index;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: isSelected 
                                        ? level['color']
                                        : colorScheme.surface,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? colorScheme.primary
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: colorScheme.primary.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        level['icon'],
                                        style: const TextStyle(fontSize: 36),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              level['title'],
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              level['description'],
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isSelected)
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

                          // Continue Button
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: Material(
                              borderRadius: BorderRadius.circular(30),
                              elevation: 5,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(30),
                                onTap: selectedLevel == null
                                    ? null
                                    : ()async {
                                       await LocalDB.setActivityLevels(activityLevels[selectedLevel!]['title']);

                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => const WorkSchedulePage()),
                                        );
                                      },
                                child: Container(
                                  width: double.infinity,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30),
                                    gradient: selectedLevel != null
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
                                        color: selectedLevel != null
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
}