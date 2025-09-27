import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'package:confetti/confetti.dart'; // Add this to pubspec.yaml
import '../WrongThingPage.dart';


class PersonalSummaryPage extends StatefulWidget {
  const PersonalSummaryPage({super.key});

  @override
  State<PersonalSummaryPage> createState() => _PersonalSummaryPageState();
}

class _PersonalSummaryPageState extends State<PersonalSummaryPage> 
    with SingleTickerProviderStateMixin {
  // Dummy values - these would be replaced with real data
  double bmiValue = 19.2;
  String bmiCategory = "Normal";
  String bmiComment = "A balanced BMI supports overall health";
  
  double targetWeight = 70.0;
  String experienceLevel = "Beginner";
  String activityLevel = "I'm not that active";
  String illnessAttention = "None";
  
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;
  late ConfettiController _confettiController;
  
  bool _showDetails = false;
  bool _celebrating = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize ConfettiController
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));

    // Initialize AnimationController
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );
    
    _colorAnimation = ColorTween(
      begin: Colors.grey[300],
      end: Colors.blue[100],
    ).animate(_animationController);
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _toggleCelebration() {
    setState(() {
      _celebrating = !_celebrating;
      if (_celebrating) {
        _confettiController.play();
      } else {
        _confettiController.stop();
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
          // Animated background gradient
          AnimatedContainer(
            duration: const Duration(milliseconds: 1000),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topRight,
                radius: 1.5,
                colors: [
                  colorScheme.primary.withOpacity(0.1),
                  colorScheme.surface.withOpacity(0.9),
                ],
                stops: const [0.1, 0.9],
              ),
            ),
          ),
          
          // Confetti celebration
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
              ],
            ),
          ),
          
          SingleChildScrollView(
            child: Column(
              children: [
                AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
                    onPressed: () => Navigator.pop(context),
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(
                        _celebrating ? Icons.celebration : Icons.celebration_outlined,
                        color: _celebrating ? Colors.amber : colorScheme.onSurface,
                      ),
                      onPressed: _toggleCelebration,
                    ),
                  ],
                ),
                
                // Main content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Animated title
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Text(
                          'Your Wellness Profile',
                          style: textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                            shadows: [
                              Shadow(
                                blurRadius: 10,
                                color: colorScheme.primary.withOpacity(0.2),
                                offset: const Offset(0, 2),
                          )],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      Text(
                        'A snapshot of your health journey',
                        style: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // BMI Card with animated border
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              _getBmiColor(bmiValue).withOpacity(0.1),
                              _getBmiColor(bmiValue).withOpacity(0.3),
                            ],
                          ),
                          border: Border.all(
                            color: _getBmiColor(bmiValue).withOpacity(0.5),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _getBmiColor(bmiValue).withOpacity(0.2),
                              blurRadius: 20,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Body Mass Index',
                                    style: textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  // Animated category chip
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 500),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _getBmiColor(bmiValue),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _getBmiColor(bmiValue)
                                              .withOpacity(0.5),
                                          blurRadius: 10,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      bmiCategory.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              // BMI value with animated counter
                              _AnimatedCounter(
                                value: bmiValue,
                                duration: const Duration(milliseconds: 1500),
                                style: textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: _getBmiColor(bmiValue),
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Progress indicator
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: _calculateBmiProgress(bmiValue),
                                  minHeight: 10,
                                  backgroundColor: colorScheme.surfaceContainerHighest,
                                  color: _getBmiColor(bmiValue),
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Comment with animated reveal
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 500),
                                child: Text(
                                  bmiComment,
                                  key: ValueKey<String>(bmiComment),
                                  style: textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.onSurface.withOpacity(0.8),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Expandable details section
                      GestureDetector(
                        onTap: () => setState(() => _showDetails = !_showDetails),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.shadow.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'YOUR DETAILS',
                                    style: textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  RotationTransition(
                                    turns: _showDetails
                                        ? const AlwaysStoppedAnimation(0.5)
                                        : const AlwaysStoppedAnimation(0.0),
                                    child: Icon(
                                      Icons.expand_more,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              
                              AnimatedCrossFade(
                                duration: const Duration(milliseconds: 300),
                                crossFadeState: _showDetails
                                    ? CrossFadeState.showSecond
                                    : CrossFadeState.showFirst,
                                firstChild: Container(),
                                secondChild: Column(
                                  children: [
                                    const SizedBox(height: 16),
                                    _buildDetailItem(
                                      context,
                                      icon: Icons.flag,
                                      title: "Target weight",
                                      value: "$targetWeight kg",
                                    ),
                                    _buildDetailItem(
                                      context,
                                      icon: Icons.star,
                                      title: "Experience level",
                                      value: experienceLevel,
                                    ),
                                    _buildDetailItem(
                                      context,
                                      icon: Icons.directions_run,
                                      title: "Activity level",
                                      value: activityLevel,
                                    ),
                                    _buildDetailItem(
                                      context,
                                      icon: Icons.health_and_safety,
                                      title: "Health considerations",
                                      value: illnessAttention,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Animated continue button
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        width: double.infinity,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.primary,
                              colorScheme.tertiary ?? colorScheme.secondary,
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
                              _toggleCelebration();
                              // Nothing to save here 
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const PostMealRegretPage()),
                              );
                              
                            },
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'CONTINUE JOURNEY',
                                    style: textTheme.titleLarge?.copyWith(
                                      color: colorScheme.onPrimary,
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
  
  Widget _buildDetailItem(BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.primary.withOpacity(0.2),
            ),
            child: Icon(icon, color: colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Text(value),
        ],
      ),
    );
  }
  
  Color _getBmiColor(double bmi) {
    if (bmi < 18.5) return Colors.blue; // Underweight
    if (bmi < 24.9) return Colors.green; // Normal
    if (bmi < 29.9) return Colors.orange; // Overweight
    return Colors.red; // Obese
  }
  
  double _calculateBmiProgress(double bmi) {
    if (bmi < 18.5) return 0.2;
    if (bmi < 24.9) return 0.6;
    if (bmi < 29.9) return 0.8;
    return 1.0;
  }
}

// Animated Counter widget
class _AnimatedCounter extends StatelessWidget {
  final double value;
  final Duration duration;
  final TextStyle? style;
  
  const _AnimatedCounter({
    super.key,
    required this.value,
    required this.duration,
    this.style,
  });
  
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: value),
      duration: duration,
      builder: (context, value, child) {
        return Text(
          value.toStringAsFixed(1),
          style: style,
        );
      },
    );
  }
}
