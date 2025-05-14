import 'package:flutter/material.dart';
import 'BadHabitsPage.dart';

class AITrackerPage2 extends StatefulWidget {
  const AITrackerPage2({super.key});

  @override
  State<AITrackerPage2> createState() => _AITrackerPageState();
}

class _AITrackerPageState extends State<AITrackerPage2>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Color?> _colorAnimation;

  final List<Map<String, dynamic>> features = [
    {
      'title': 'Image Recognition',
      'icon': Icons.image_search,
      'description': 'Automatically identifies food items from photos',
      'color': Colors.blue,
    },
    {
      'title': 'Machine Learning',
      'icon': Icons.model_training,
      'description': 'Learns your patterns for personalized recommendations',
      'color': Colors.purple,
    },
    {
      'title': 'AI Analytics',
      'icon': Icons.analytics,
      'description': 'Advanced insights into your eating habits',
      'color': Colors.green,
    },
    {
      'title': 'Neural Networks',
      'icon': Icons.memory,
      'description': 'Deep learning for accurate calorie estimation',
      'color': Colors.orange,
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    )..addListener(() {
        setState(() {});
      });

    _colorAnimation = ColorTween(
      begin: Colors.grey[200],
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
      body: Stack(
        children: [
          // Animated background color using _colorAnimation
          AnimatedBuilder(
            animation: _colorAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _colorAnimation.value ?? Colors.grey[200]!,
                      colorScheme.surface.withOpacity(0.9),
                    ],
                  ),
                ),
              );
            },
          ),

          // Floating AI elements
          Positioned(
            top: 100,
            left: 30,
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: Icon(
                Icons.auto_awesome,
                size: 40,
                color: colorScheme.primary.withOpacity(0.5),
              ),
            ),
          ),
          Positioned(
            top: 80,
            right: 40,
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: Icon(
                Icons.psychology,
                size: 50,
                color: colorScheme.secondary.withOpacity(0.5),
              ),
            ),
          ),
          Positioned(
            bottom: 200,
            left: 50,
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: Icon(
                Icons.insights,
                size: 45,
                color: colorScheme.tertiary.withOpacity(0.5),
              ),
            ),
          ),

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
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Text(
                          'Our high-tech AI tracker',
                          style: textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onBackground,
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
                      Opacity(
                        opacity: _fadeAnimation.value,
                        child: Text(
                          'makes the weight loss process painless',
                          style: textTheme.titleMedium?.copyWith(
                            color:
                                colorScheme.onBackground.withOpacity(0.8),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeInOut,
                        height: 180,
                        decoration: BoxDecoration(
                          image: const DecorationImage(
                            image: AssetImage('assets/ai_brain.png'),
                            fit: BoxFit.contain,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Opacity(
                            opacity: _fadeAnimation.value,
                            child: Text(
                              'AI POWERED',
                              style: textTheme.titleLarge?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 3,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      ...List.generate(features.length, (index) {
                        final feature = features[index];
                        return AnimatedContainer(
                          duration: Duration(milliseconds: 300 + (index * 100)),
                          curve: Curves.easeInOut,
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: feature['color'].withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                            border: Border.all(
                              color: feature['color'].withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: feature['color'].withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  feature['icon'],
                                  color: feature['color'],
                                  size: 30,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      feature['title'],
                                      style: textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onBackground,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      feature['description'],
                                      style: textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onBackground
                                            .withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.primary,
                              colorScheme.secondary,
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withOpacity(0.4),
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
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => BadHabitsPage()),
                              );
                            },
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'CONTINUE',
                                    style: textTheme.titleLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Icon(Icons.arrow_forward,
                                      color: Colors.white),
                                ],
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
