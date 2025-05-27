import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'package:fyp/LocalDB.dart';
import 'GoalWeightPage.dart';
import 'ActivityPage.dart';

class GoalPage extends StatefulWidget {
  const GoalPage({super.key});

  @override
  State<GoalPage> createState() => _CreativeGoalPageState();
}

class _CreativeGoalPageState extends State<GoalPage>
    with TickerProviderStateMixin { // <-- FIXED HERE
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Color?> _bgColorAnimation;

  final Map<String, List<String>> goals = {
    'Lose Weight': ['Get healthier', 'Look better', 'Reduce stress', 'Sleep better'],
    'Build Muscle': ['Increase strength', 'Improve posture', 'Boost confidence', 'Enhance metabolism'],
    'Improve Fitness': ['More energy', 'Better endurance', 'Healthier heart', 'Daily activity'],
    'Mental Wellness': ['Reduce anxiety', 'Improve focus', 'Better mood', 'Mindfulness']
  };

  String? selectedMainGoal;
  final Set<String> selectedSubGoals = {};

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

              // Floating food emojis
              Positioned(
                top: 100,
                left: 30,
                child: AnimatedOpacity(
                  duration: const Duration(seconds: 2),
                  opacity: 0.6,
                  child: const Text('🥑', style: TextStyle(fontSize: 40)),
                ),
              ),
              Positioned(
                top: 80,
                right: 40,
                child: AnimatedOpacity(
                  duration: const Duration(seconds: 3),
                  opacity: 0.6,
                  child: const Text('🍎', style: TextStyle(fontSize: 50)),
                ),
              ),
              Positioned(
                bottom: 200,
                left: 50,
                child: AnimatedOpacity(
                  duration: const Duration(seconds: 2),
                  opacity: 0.6,
                  child: const Text('🥗', style: TextStyle(fontSize: 45)),
                ),
              ),
              Positioned(
                bottom: 180,
                right: 60,
                child: AnimatedOpacity(
                  duration: const Duration(seconds: 3),
                  opacity: 0.6,
                  child: const Text('🍗', style: TextStyle(fontSize: 48)),
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
                              'What are your current goals?',
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
                              'Select your primary focus and the benefits you want to achieve',
                              style: textTheme.titleMedium?.copyWith(
                                color: colorScheme.onBackground.withOpacity(0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Main Goals Carousel
                          SizedBox(
                            height: 120,
                            child: PageView.builder(
                              itemCount: goals.length,
                              onPageChanged: (index) {
                                setState(() {
                                  selectedMainGoal = goals.keys.elementAt(index);
                                  selectedSubGoals.clear();
                                });
                              },
                              itemBuilder: (context, index) {
                                final goal = goals.keys.elementAt(index);
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedMainGoal = goal;
                                      selectedSubGoals.clear();
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    margin: const EdgeInsets.symmetric(horizontal: 8),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: selectedMainGoal == goal
                                          ? colorScheme.primary
                                          : colorScheme.surface,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: colorScheme.primary.withOpacity(0.1),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        goal,
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: selectedMainGoal == goal
                                              ? colorScheme.onPrimary
                                              : colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Sub-goals Grid
                          SizedBox(
                            height: 250,
                            child: selectedMainGoal == null
                                ? Center(
                                    child: Text(
                                      'Select a main goal first',
                                      style: TextStyle(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  )
                                : GridView.count(
                                    crossAxisCount: 2,
                                    childAspectRatio: 2.5,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    children: goals[selectedMainGoal]!.map((subGoal) {
                                      final isSelected = selectedSubGoals.contains(subGoal);
                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            if (isSelected) {
                                              selectedSubGoals.remove(subGoal);
                                            } else {
                                              selectedSubGoals.add(subGoal);
                                            }
                                          });
                                        },
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? colorScheme.primary.withOpacity(0.1)
                                                : colorScheme.surface,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: isSelected
                                                  ? colorScheme.primary
                                                  : Colors.transparent,
                                              width: 2,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: colorScheme.primary.withOpacity(0.05),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          padding: const EdgeInsets.all(12),
                                          child: Row(
                                            children: [
                                              Icon(
                                                isSelected
                                                    ? Icons.check_circle_rounded
                                                    : Icons.circle_outlined,
                                                color: colorScheme.primary,
                                              ),
                                              const SizedBox(width: 8),
                                              Flexible(
                                                child: Text(
                                                  subGoal,
                                                  style: TextStyle(
                                                    color: colorScheme.onSurfaceVariant,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                          ),
                          const SizedBox(height: 24),

                          // Continue Button
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: Material(
                              borderRadius: BorderRadius.circular(30),
                              elevation: 5,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(30),
                                onTap: selectedMainGoal == null
                                    ? null
                                    : () async{
                                     await LocalDB.setSelectedSubGoals(selectedSubGoals);

                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => ActivityPage()),
                                        );
                                      },
                                child: Container(
                                  width: double.infinity,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30),
                                    gradient: selectedMainGoal != null
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
                                        color: selectedMainGoal != null
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
