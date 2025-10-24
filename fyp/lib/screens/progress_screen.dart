// lib/screens/progress_screen.dart

import 'package:flutter/material.dart';
import 'dart:ui'; // Used for ImageFilter.blur
import 'dart:math' as math; // For math functions like clamp
import 'package:confetti/confetti.dart';
import 'package:flutter/services.dart';
import 'package:fyp/screens/settings_screen.dart';

// ✅ --- NEW IMPORTS ---
import 'package:fyp/models/progress_data.dart';
import 'package:fyp/services/progress_service.dart';
// ---------------------

// --- 1. DATA MODELS ---
// (Removed - Now in lib/models/progress_data.dart)

// --- 2. MOCK SERVICE ---
// (Removed - Now replaced by lib/services/progress_service.dart)

// --- 3. MAIN SCREEN WIDGET ---

class MyProgressScreen extends StatefulWidget {
  const MyProgressScreen({super.key});
  @override
  State<MyProgressScreen> createState() => _MyProgressScreenState();
}

class _MyProgressScreenState extends State<MyProgressScreen> with TickerProviderStateMixin {
  late Future<ProgressData> _progressDataFuture;

  // ✅ --- USE THE REAL SERVICE ---
  final RealProgressService _dataService = RealProgressService();

  late AnimationController _headerAnimController;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    // ✅ This now calls your real API
    _progressDataFuture = _dataService.fetchData();
    _headerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
  }

  @override
  void dispose() {
    _headerAnimController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _refreshData() {
    setState(() {
      // ✅ This now re-fetches from your real API
      _progressDataFuture = _dataService.fetchData();
      _headerAnimController.forward(from: 0.0);
    });
  }

  // ✅ --- UPDATED FUNCTION TO LOG WEIGHT ---
  void _showLogWeightSheet(BuildContext context, double currentWeight) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _LogWeightSheet(
        initialWeight: currentWeight,
        onLog: (newWeight) async {
          // Close the sheet first for a snappy UI
          Navigator.of(ctx).pop();

          try {
            // Call the real API service
            await _dataService.logWeight(newWeight);
            
            // On success, celebrate and refresh
            HapticFeedback.mediumImpact();
            _confettiController.play();
            _refreshData(); // Refresh all data from server
          } catch (e) {
            // Show an error message if it fails
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error logging weight: ${e.toString()}'))
              );
            }
          }
        },
      ),
    );
  }
  // ------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<ProgressData>(
        future: _progressDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text("No progress data found."));
          }

          final data = snapshot.data!;
          final double bmi = (data.currentWeight / (data.userHeightInMeters * data.userHeightInMeters))/1000;

          return Stack(
            alignment: Alignment.topCenter,
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFE0F2F7), Color(0xFFCFE8EF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              RefreshIndicator(
                onRefresh: () async => _refreshData(),
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  slivers: [
                    _buildHeaderSliver(data),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildSectionHeader(context, "Your Story So Far"),
                          _buildTimelineSection(data),
                          const SizedBox(height: 24),
                          _HallOfFameSection(achievements: data.achievements),
                          const SizedBox(height: 24),
                          _buildSectionHeader(context, "Health Overview"),
                          _HealthSnapshotSection(
                            bmi: bmi,
                            heightInMeters: data.userHeightInMeters,
                            currentWeight: data.currentWeight,
                            targetWeight: data.targetWeight,
                            animation: _headerAnimController,
                          ),
                          const SizedBox(height: 12),
                          _CommunityCallToAction(
                            animationIndex: 6,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Joining Community... (Action Placeholder)'))
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          _buildSectionHeader(context, "Weekly Snapshots"),
                          _CombinedTrendCard(
                            weightData: data.weeklyWeightData,
                            stepsData: data.weeklyStepsData,
                            stepGoal: data.stepGoal,
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  emissionFrequency: 0.05,
                  numberOfParticles: 20,
                  gravity: 0.1,
                ),
              ),
            ],
          );
        },
      ),
      // ✅ --- ADDED FLOATING ACTION BUTTON BACK ---
      // This button calls the _showLogWeightSheet function
      floatingActionButton: FutureBuilder<ProgressData>(
        future: _progressDataFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink(); // Hide if no data
          
          return FloatingActionButton.extended(
            onPressed: () => _showLogWeightSheet(context, snapshot.data!.currentWeight),
            icon: const Icon(Icons.add_rounded),
            label: const Text("Log Weight"),
            backgroundColor: Colors.orange, // Use your theme's primary color
            foregroundColor: Colors.white,
          );
        }
      ),
      // ---------------------------------------------
    );
  }

  //
  // --- ALL YOUR UI WIDGETS BELOW THIS LINE ---
  // (No changes needed here, they are all correct)
  //
  
  // --- UI Building Methods (Unchanged) ---
  SliverAppBar _buildHeaderSliver(ProgressData data) {
    // ... (This widget is unchanged)
    return SliverAppBar(
      expandedHeight: 300, pinned: true, backgroundColor: Colors.transparent, elevation: 0, centerTitle: true,
      title: const Text('My Progress Hub', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(color: Colors.black26, blurRadius: 4)])),
      actions: [
        IconButton(icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 28),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: _PremiumProgressHeader(
          startWeight: data.startWeight, currentWeight: data.currentWeight, targetWeight: data.targetWeight, animation: _headerAnimController,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    // ... (This widget is unchanged)
    return StaggeredAnimation(index: 0, child: Padding(padding: const EdgeInsets.only(bottom: 16, top: 8), child: Center(
      child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey[800]))),
    ));
  }

  Widget _buildTimelineSection(ProgressData data) {
    // ... (This widget is unchanged)
    final double weightLost = data.startWeight - data.currentWeight;
    return Column(
      children: [
        StaggeredAnimation(index: 1, child: _TimelineEventCard(
          icon: Icons.scale, color: Theme.of(context).colorScheme.primary, title: "Today's Weight",
          subtitle: "You're doing great!", value: "${data.currentWeight.toStringAsFixed(1)} kg", isFirst: true)),
        if (data.steps > 0)
          StaggeredAnimation(index: 2, child: _TimelineEventCard(
            icon: Icons.directions_walk, color: Colors.purple, title: "Today's Steps",
            subtitle: "${(data.steps / data.stepGoal * 100).toStringAsFixed(0)}% of your goal", value: "${data.steps}")),
        if (weightLost > 0)
          StaggeredAnimation(index: 3, child: _TimelineEventCard(
            icon: Icons.trending_down, color: Colors.orange, title: "Total Weight Lost",
            subtitle: "An amazing accomplishment!", value: "${weightLost.toStringAsFixed(1)} kg")),
        StaggeredAnimation(index: 4, child: _TimelineEventCard(
          icon: Icons.rocket_launch, color: Colors.grey.shade600, title: "Journey Started",
          subtitle: "The first step is always the hardest.", value: "${data.startWeight.toStringAsFixed(1)} kg", isLast: true)),
      ],
    );
  }
}

// --- 4. NEW & REDESIGNED WIDGETS ---
// ... (All widgets from _CombinedTrendCard down to _ProgressRingPainter)
// ... (are unchanged and remain here) ...

class _CombinedTrendCard extends StatelessWidget {
  final List<double> weightData;
  final List<int> stepsData;
  final int stepGoal;

  const _CombinedTrendCard({
    required this.weightData,
    required this.stepsData,
    required this.stepGoal,
  });

  @override
  Widget build(BuildContext context) {
    return StaggeredAnimation(
      index: 7,
      child: _InteractiveCard(
        padding: const EdgeInsets.all(0), // Padding inside the visualizations
        child: Column(
          children: [
            // 1. Weight Trend Section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _WeightTrendVisualization(data: weightData),
            ),
            
            // Divider
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Divider(height: 32, thickness: 1, color: Color(0xFFE0E0E0)),
            ),

            // 2. Steps Activity Section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _StepsTrendVisualization(data: stepsData, goal: stepGoal),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeightTrendVisualization extends StatelessWidget {
  final List<double> data;
  const _WeightTrendVisualization({required this.data});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.orange;

    if (data.isEmpty) return const SizedBox(height: 120, child: Center(child: Text("Not enough weight data.")));
    final double change = data.isNotEmpty ? data.last - data.first : 0.0;
    final bool isLoss = change < 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // UPDATED: Icon color to primary
            Icon(Icons.fitness_center_rounded, color: primaryColor, size: 20),
            const SizedBox(width: 8),
            const Text("Weight Trend (7 Days)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Spacer(),
            // Summary Chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isLoss ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "${change.abs().toStringAsFixed(1)} kg ${isLoss ? 'Loss' : 'Gain'}",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isLoss ? Colors.green.shade700 : Colors.red.shade700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // The Chart Area
        SizedBox(
          height: 120,
          child: _WeightPathChart(data: data),
        ),
      ],
    );
  }
}

class _StepsTrendVisualization extends StatelessWidget {
  final List<int> data;
  final int goal;
  const _StepsTrendVisualization({required this.data, required this.goal});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.orange;

    if (data.isEmpty) return const SizedBox(height: 180, child: Center(child: Text("No step data.")));
    final int sum = data.isNotEmpty ? data.reduce((a, b) => a + b) : 0;
    final int average = data.length > 0 ? sum ~/ data.length : 0;
    final double progress = (goal > 0) ? (average / goal).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // UPDATED: Icon color to primary
            Icon(Icons.directions_walk_rounded, color: primaryColor, size: 20),
            const SizedBox(width: 8),
            const Text("Steps Activity (Weekly)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Circular Indicator (Avg Goal Progress)
            SizedBox(
              width: 70,
              height: 70,
              child: _CircularGoalIndicator(
                progress: progress,
                value: average,
                unit: 'Avg Steps',
                // UPDATED: Progress indicator color to primary
                color: primaryColor,
                labelSize: 10,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Daily Average:", style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  Text(
                    average.toString(),
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, 
                    // UPDATED: Steps number color to primary
                    color: primaryColor),
                  ),
                  Text(
                    "Goal: ${goal} steps",
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Bar Chart
        SizedBox(
          height: 100, // Reduced height for a more compact design
          child: _StepsBarChart(data: data, goal: goal),
        ),
      ],
    );
  }
}

// Reusable Circular Progress Indicator (Adjusted for label size)
class _CircularGoalIndicator extends StatelessWidget {
  final double progress;
  final int value;
  final String unit;
  final Color color;
  final double labelSize;

  const _CircularGoalIndicator({
    required this.progress,
    required this.value,
    required this.unit,
    required this.color,
    this.labelSize = 10,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: progress),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutCubic,
      builder: (context, animProgress, child) {
        return CustomPaint(
          painter: _ProgressRingPainter(
            progress: animProgress,
            progressColor: color,
            backgroundColor: color.withOpacity(0.2),
          ),
          child: Center(
            child: Text(
              "${(animProgress * 100).toStringAsFixed(0)}%",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
          ),
        );
      },
    );
  }
}


class _WeightPathChart extends StatelessWidget {
  final List<double> data;
  const _WeightPathChart({required this.data});

  @override
  Widget build(BuildContext context) {
    // FIX: Get color here where context is available
    final primaryColor = Colors.orange;

    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeInOutCubic,
      builder: (context, value, child) {
        return CustomPaint(
          size: Size.infinite,
          // PASS the color to the painter
          painter: _WeightPathPainter(data: data, animationProgress: value, primaryColor: primaryColor),
        );
      },
    );
  }
}

class _WeightPathPainter extends CustomPainter {
  final List<double> data;
  final double animationProgress;
  final Color primaryColor; 

  _WeightPathPainter({required this.data, required this.animationProgress, required this.primaryColor}); 

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final double minVal = data.reduce(math.min);
    final double maxVal = data.reduce(math.max);
    final double range = (maxVal - minVal) == 0 ? 1 : maxVal - minVal;

    final points = List.generate(data.length, (i) {
      final x = size.width * (i / (data.length - 1));
      final y = size.height - ((data[i] - minVal) / range * size.height * 0.8 + size.height * 0.1);
      return Offset(x, y);
    });

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i+1];
      final midPoint = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
      path.quadraticBezierTo(p1.dx, p1.dy, midPoint.dx, midPoint.dy);
    }
    path.lineTo(points.last.dx, points.last.dy);

    final PathMetric pathMetric = path.computeMetrics().first;
    final Path extractPath = pathMetric.extractPath(0.0, pathMetric.length * animationProgress);

    if (animationProgress > 0) {
      final fillPath = Path.from(extractPath);
      final lastPoint = pathMetric.getTangentForOffset(pathMetric.length * animationProgress)!.position;
      fillPath.lineTo(lastPoint.dx, size.height);
      fillPath.lineTo(points.first.dx, size.height);
      fillPath.close();
      final fillPaint = Paint()
        ..shader = LinearGradient(
          // USED primaryColor
          colors: [primaryColor.withOpacity(0.3), primaryColor.withOpacity(0.0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawPath(fillPath, fillPaint);
    }

    final linePaint = Paint()
      // USED primaryColor
      ..shader = LinearGradient(
          colors: [primaryColor, primaryColor.withOpacity(0.6)]
      ).createShader(Rect.fromLTWH(0,0,size.width, size.height))
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(extractPath, linePaint);
    
    final headPosition = pathMetric.getTangentForOffset(pathMetric.length * animationProgress)!.position;
    final pointPaint = Paint()..color = Colors.white;
    final pointOutlinePaint = Paint()
      // USED primaryColor
      ..color = primaryColor..strokeWidth = 2.0..style = PaintingStyle.stroke;
    
    final animatedPointsCount = (points.length * animationProgress).ceil();
    for(int i = 0; i < animatedPointsCount; i++) {
        canvas.drawCircle(points[i], 4, pointPaint);
        canvas.drawCircle(points[i], 4, pointOutlinePaint);
    }

    final glowPaint = Paint()
      // USED primaryColor
      ..color = primaryColor.withOpacity(0.5)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(headPosition, 8, glowPaint);
    canvas.drawCircle(headPosition, 5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _WeightPathPainter oldDelegate) => oldDelegate.animationProgress != animationProgress;
}

class _StepsBarChart extends StatelessWidget {
  final List<int> data;
  final int goal;
  const _StepsBarChart({required this.data, required this.goal});

  @override
  Widget build(BuildContext context) {
    // FIX: Get color here where context is available
    final primaryColor = Colors.orange;

    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return CustomPaint(
          size: Size.infinite,
          // PASS the color to the painter
          painter: _StepsBarPainter(data: data, goal: goal, animationProgress: value, primaryColor: primaryColor),
        );
      },
    );
  }
}

class _StepsBarPainter extends CustomPainter {
  final List<int> data;
  final int goal;
  final double animationProgress;
  final List<String> dayLabels = const ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  final Color primaryColor; 

  _StepsBarPainter({required this.data, required this.goal, required this.animationProgress, required this.primaryColor}); 

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    
    const double labelHeight = 20;
    final double chartHeight = size.height - labelHeight;
    final double maxVal = (data.isNotEmpty ? (data.reduce(math.max) > goal ? data.reduce(math.max) : goal) : goal) * 1.2;
    if (maxVal == 0) return; // Avoid division by zero
    
    final double barWidth = size.width / (data.length * 2 - 1);
    
    for (int i = 0; i < data.length; i++) {
      final barHeight = (data[i] / maxVal * chartHeight) * animationProgress;
      final left = i * barWidth * 2;
      final rect = Rect.fromLTWH(left, chartHeight - barHeight, barWidth, barHeight);
      final didMeetGoal = data[i] >= goal;

      final paint = Paint()
        ..shader = LinearGradient(
          // USED primaryColor
          colors: didMeetGoal ? [primaryColor, primaryColor.withOpacity(0.7)] : [Colors.grey.shade300, Colors.grey.shade400],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ).createShader(rect);
      
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), paint);

      final textSpan = TextSpan(
        text: dayLabels[i % dayLabels.length],
        style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w600),
      );
      final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      textPainter.layout(minWidth: 0, maxWidth: barWidth);
      final offset = Offset(left + (barWidth - textPainter.width) / 2, size.height - labelHeight + 4);
      textPainter.paint(canvas, offset);
    }
  }
  
  @override
  bool shouldRepaint(covariant _StepsBarPainter oldDelegate) => oldDelegate.animationProgress != animationProgress;
}

// --- NEW WIDGET: _CommunityCallToAction ---
class _CommunityCallToAction extends StatelessWidget {
  final VoidCallback onTap;
  final int animationIndex;

  const _CommunityCallToAction({required this.onTap, required this.animationIndex});

  @override
  Widget build(BuildContext context) {
    return StaggeredAnimation(
      index: animationIndex,
      child: _InteractiveCard(
        onTap: onTap,
        padding: const EdgeInsets.all(0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24.0),
            gradient: LinearGradient(
              colors: [Colors.deepOrange.shade400, Colors.pink.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Stack(
                  children: [
                    // Base Icon (Back)
                    Icon(Icons.people_alt_rounded, size: 50, color: Colors.white.withOpacity(0.3)),
                    // Overlaid Icons for a more creative, layered look
                    Positioned(top: 10, left: 10, child: Icon(Icons.person, size: 24, color: Colors.white.withOpacity(0.8))),
                    Positioned(bottom: 0, right: 0, child: Icon(Icons.person, size: 28, color: Colors.white)),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Join the Community!",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(color: Colors.black38, blurRadius: 4)],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Share wins, get support, and connect with others on their journey.",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
// --- END NEW WIDGET ---


// --- 5. ALL OTHER HELPER WIDGETS (Modified _ProgressRingPainter) ---
class _HallOfFameSection extends StatefulWidget {
  final List<Achievement> achievements;
  const _HallOfFameSection({required this.achievements});
  @override
  State<_HallOfFameSection> createState() => _HallOfFameSectionState();
}
class _HallOfFameSectionState extends State<_HallOfFameSection> with TickerProviderStateMixin {
  late PageController _pageController;
  double _currentPage = 0.0;
  late List<ConfettiController> _confettiControllers;
  final Set<int> _celebratedIndices = {};
  @override
  void initState() {
    super.initState();
    final int initialPage = widget.achievements.isNotEmpty ? widget.achievements.lastIndexWhere((a) => a.isAchieved) : 0;
    _currentPage = (initialPage == -1) ? 0 : initialPage.toDouble();
    _pageController = PageController(initialPage: (initialPage == -1) ? 0 : initialPage, viewportFraction: 0.75);
    _confettiControllers = List.generate(widget.achievements.length, (index) => ConfettiController(duration: const Duration(milliseconds: 500)));
    _pageController.addListener(() {
      if(!mounted) return;
      setState(() => _currentPage = _pageController.page!);
      int centeredIndex = _pageController.page!.round();
      if (widget.achievements.isNotEmpty && widget.achievements[centeredIndex].isAchieved && !_celebratedIndices.contains(centeredIndex)) {
        _confettiControllers[centeredIndex].play();
        _celebratedIndices.add(centeredIndex);
      }
    });
  }
  @override
  void dispose() {
    _pageController.dispose();
    for (var controller in _confettiControllers) { controller.dispose(); }
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    if (widget.achievements.isEmpty) {
      return StaggeredAnimation(
        index: 6,
        child: _InteractiveCard(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.lock_outline, size: 40, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text("Achievements Locked", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey[800])),
                const SizedBox(height: 8),
                Text("Start logging meals and weight to unlock!", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          ),
        ),
      );
    }
    
    return StaggeredAnimation(index: 6, child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Hall of Fame", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey[800])),
              TextButton(onPressed: () {}, child: const Text("See All")),
            ],
          ),
        ),
        SizedBox(height: 300, child: PageView.builder(
          controller: _pageController,
          itemCount: widget.achievements.length,
          itemBuilder: (context, index) {
            double difference = (index - _currentPage).abs();
            return Stack(
              alignment: Alignment.topCenter,
              children: [
                Container(
                  padding: EdgeInsets.only(top: 20 + difference * 30, bottom: 20, left: 8, right: 8),
                  child: Transform.scale(scale: 1.0 - (difference * 0.15), child: Opacity(
                    opacity: 1.0 - (difference * 0.4),
                    child: _TrophyCard(achievement: widget.achievements[index]),
                  )),
                ),
                Align(alignment: Alignment.topCenter, child: ConfettiWidget(
                  confettiController: _confettiControllers[index],
                  blastDirectionality: BlastDirectionality.explosive,
                  emissionFrequency: 0.05, numberOfParticles: 15, gravity: 0.3,
                )),
              ],
            );
          },
        )),
      ],
    ));
  }
}
class _TrophyCard extends StatelessWidget {
  final Achievement achievement;
  const _TrophyCard({required this.achievement});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: achievement.isAchieved
            // UPDATED: Gradient color for achieved to primary
            ? LinearGradient(colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight)
            : LinearGradient(colors: [theme.cardColor.withOpacity(0.6), theme.cardColor.withOpacity(0.9)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 10))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(child: Stack(
            alignment: Alignment.center,
            children: [
              Container(decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  // UPDATED: Radial glow color for achieved to primary
                  colors: achievement.isAchieved ? [colorScheme.primary.withOpacity(0.4), Colors.transparent] : [Colors.grey.withOpacity(0.2), Colors.transparent],
                  stops: const [0.0, 0.7],
                ),
              )),
              _ShimmerEffect(enabled: achievement.isAchieved, child: Icon(
                achievement.isAchieved ? achievement.icon : Icons.lock, size: 64,
                color: achievement.isAchieved ? colorScheme.onPrimary : colorScheme.onSurface.withOpacity(0.4),
              )),
            ],
          )),
          const SizedBox(height: 16),
          Text(achievement.isAchieved ? achievement.title : "LOCKED", textAlign: TextAlign.center, style: TextStyle(
            color: achievement.isAchieved ? colorScheme.onPrimary : colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold,
            shadows: achievement.isAchieved ? const [Shadow(color: Colors.black45, blurRadius: 4)] : [],
          )),
          const SizedBox(height: 4),
          Text(achievement.isAchieved ? achievement.description : "Keep making progress to unlock!", textAlign: TextAlign.center, style: TextStyle(
            color: achievement.isAchieved ? colorScheme.onPrimary.withOpacity(0.8) : colorScheme.onSurface.withOpacity(0.6), fontSize: 14,
          )),
        ],
      ),
    );
  }
}
class _ShimmerEffect extends StatefulWidget {
  final Widget child; final bool enabled;
  const _ShimmerEffect({required this.child, this.enabled = true});
  @override
  State<_ShimmerEffect> createState() => _ShimmerEffectState();
}
class _ShimmerEffectState extends State<_ShimmerEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    if (widget.enabled) { _controller.repeat(); }
  }
  @override
  void didUpdateWidget(covariant _ShimmerEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !_controller.isAnimating) { _controller.repeat(); }
    else if (!widget.enabled && _controller.isAnimating) { _controller.stop(); }
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) { return widget.child; }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) => LinearGradient(
          colors: const [Colors.white, Colors.white, Colors.white10, Colors.white, Colors.white],
          stops: const [0.0, 0.4, 0.5, 0.6, 1.0],
          transform: _SlidingGradientTransform(percent: _controller.value),
        ).createShader(bounds),
        child: widget.child,
      ),
    );
  }
}
class _SlidingGradientTransform extends GradientTransform {
  final double percent;
  const _SlidingGradientTransform({required this.percent});
  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) => Matrix4.translationValues(bounds.width * (percent * 2 - 1), 0, 0);
}
class _TimelineEventCard extends StatelessWidget {
  final IconData icon; final Color color; final String title; final String subtitle; final String value; final bool isFirst; final bool isLast;
  const _TimelineEventCard({ required this.icon, required this.color, required this.title, required this.subtitle, required this.value, this.isFirst = false, this.isLast = false});
  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: 50, child: CustomPaint(
          painter: _TimelinePainter(isFirst: isFirst, isLast: isLast),
          child: Center(child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.2)),
            child: Icon(icon, color: color, size: 20),
          )),
        )),
        const SizedBox(width: 8),
        Expanded(child: _InteractiveCard(padding: const EdgeInsets.all(16), child: Row(
          children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              ],
            )),
            const SizedBox(width: 16),
            Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: color))
          ],
        ))),
      ],
    ));
  }
}
class _TimelinePainter extends CustomPainter {
  final bool isFirst; final bool isLast;
  _TimelinePainter({required this.isFirst, required this.isLast});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.grey.shade300..strokeWidth = 2.0;
    final double centerX = size.width / 2; final double centerY = size.height / 2;
    if (!isFirst) { canvas.drawLine(Offset(centerX, 0), Offset(centerX, centerY - 25), paint); }
    if (!isLast) { canvas.drawLine(Offset(centerX, centerY + 25), Offset(centerX, size.height), paint); }
  }
  @override
  bool shouldRepaint(covariant _TimelinePainter oldDelegate) => oldDelegate.isFirst != isFirst || oldDelegate.isLast != isLast;
}
class _HealthSnapshotSection extends StatelessWidget {
  final double bmi; final double heightInMeters; final double currentWeight; final double targetWeight; final Animation<double> animation;
  const _HealthSnapshotSection({ required this.bmi, required this.heightInMeters, required this.currentWeight, required this.targetWeight, required this.animation });
  @override
  Widget build(BuildContext context) {
    return StaggeredAnimation(index: 5, child: Column(
      children: [
        _WeightToGoCard(currentWeight: currentWeight, targetWeight: targetWeight, animation: animation),
        const SizedBox(height: 1),
        Row(children: [
          Expanded(child: _BmiStatusCard(bmi: bmi)),
          const SizedBox(width: 16),
          Expanded(child: _HealthyRangeCard(heightInMeters: heightInMeters)),
        ]),
      ],
    ));
  }
}
class _WeightToGoCard extends StatelessWidget {
  final double currentWeight; final double targetWeight; final Animation<double> animation;
  const _WeightToGoCard({ required this.currentWeight, required this.targetWeight, required this.animation });
  @override
  Widget build(BuildContext context) {
    final double weightToGo = (currentWeight - targetWeight).clamp(0, double.infinity);
    const double startWeight = 90.0;
    final double startDifference = startWeight - targetWeight;
    final double currentDifference = currentWeight - targetWeight;
    final double progress = (startDifference <= 0 || startDifference.isNaN) ? 1.0 : (1 - currentDifference / startDifference).clamp(0.0, 1.0);
    return _InteractiveCard(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24), child: Row(
      children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("WEIGHT TO GO", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
            const SizedBox(height: 1),
            Text.rich(TextSpan(
              text: weightToGo.toStringAsFixed(1),
              style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.black),
              children: const <TextSpan>[TextSpan(text: ' kg', style: TextStyle(fontSize: 20, fontWeight: FontWeight.normal, color: Colors.black))],
            )),
            const SizedBox(height: 4),
            const Text("You're so close, keep going!"),
          ],
        )),
        SizedBox(width: 80, height: 80, child: AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final animValue = CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic).value;
            return CustomPaint(
              painter: _ProgressRingPainter(
                progress: progress * animValue,
                // UPDATED: Progress ring color to primary
                progressColor: Colors.orange, 
                backgroundColor: Colors.grey.withOpacity(0.2),
              ),
              child: Center(child: Text("${(progress * 100 * animValue).toStringAsFixed(0)}%", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange))),
            );
          },
        ))
      ],
    ));
  }
}
class _BmiStatusCard extends StatelessWidget {
  final double bmi;
  const _BmiStatusCard({required this.bmi});
  @override
  Widget build(BuildContext context) {
    String getBmiCategory() { if (bmi.isNaN || bmi < 18.5) return "Underweight"; if (bmi < 25) return "Healthy"; if (bmi < 30) return "Overweight"; return "Obese"; }
    Color getBmiCategoryColor() { final cat = getBmiCategory(); if (cat == "Underweight") return Colors.blue; if (cat == "Healthy") return Colors.green; if (cat == "Overweight") return Colors.orange; return Colors.red; }
    IconData getBmiIcon() { final cat = getBmiCategory(); if (cat == "Healthy") return Icons.check_circle; return Icons.info; }
    return _InteractiveCard(padding: const EdgeInsets.all(16), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Text("BMI", style: TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          Icon(getBmiIcon(), color: getBmiCategoryColor(), size: 20),
        ]),
        const SizedBox(height: 8),
        Text(bmi.isNaN ? "---" : bmi.toStringAsFixed(1), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
        Text(getBmiCategory(), style: TextStyle(color: getBmiCategoryColor(), fontWeight: FontWeight.bold)),
      ],
    ));
  }
}
class _HealthyRangeCard extends StatelessWidget {
  final double heightInMeters;
  const _HealthyRangeCard({required this.heightInMeters});
  @override
  Widget build(BuildContext context) {
    final double lowerWeight = 18.5 * (heightInMeters * heightInMeters);
    final double upperWeight = 24.9 * (heightInMeters * heightInMeters);
    final bool isReady = !lowerWeight.isNaN && !upperWeight.isNaN;
    return _InteractiveCard(padding: const EdgeInsets.all(16), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(children: [
          Text("Healthy Range", style: TextStyle(fontWeight: FontWeight.bold)),
          Spacer(),
          Icon(Icons.shield_outlined, color: Colors.green, size: 20),
        ]),
        const SizedBox(height: 8),
        Text(isReady ? "${lowerWeight.toStringAsFixed(1)}-${upperWeight.toStringAsFixed(1)}" : "---", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const Text("Target (kg)", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
      ],
    ));
  }
}
class _PremiumProgressHeader extends StatelessWidget {
  final double startWeight; final double currentWeight; final double targetWeight; final Animation<double> animation;
  const _PremiumProgressHeader({ required this.startWeight, required this.currentWeight, required this.targetWeight, required this.animation });
  @override
  Widget build(BuildContext context) {
    final double totalLossGoal = (startWeight - targetWeight);
    final double lossSoFar = (startWeight - currentWeight);
    final double progress = (totalLossGoal <= 0 || totalLossGoal.isNaN) ? 1.0 : (lossSoFar / totalLossGoal).clamp(0.0, 1.0);
    final double remainingWeight = (currentWeight - targetWeight).clamp(0.0, double.infinity);
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const _BlurredImageBackground(imageUrl: 'https://images.unsplash.com/photo-1551632811-561732d1e306?q=80&w=2940&auto=format&fit=crop&ixlib-rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D'),
          BackdropFilter(filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0), child: Container(color: Colors.black.withOpacity(0.2))),
          SafeArea(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedBuilder(animation: animation, builder: (context, child) => Opacity(
                  opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn).value,
                  child: Text("Your Journey Progress", style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white, fontWeight: FontWeight.bold, shadows: const [Shadow(color: Colors.black26, blurRadius: 4)])),
                )),
                const SizedBox(height: 8),
                Text("Keep striving for your goals!", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16)),
                const SizedBox(height: 32),
                AnimatedBuilder(animation: animation, builder: (context, child) {
                  final animValue = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic).value;
                  return _SleekProgressBar(
                    progress: progress * animValue, startValue: startWeight, currentValue: currentWeight, targetValue: targetWeight);
                }),
                const SizedBox(height: 24),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  _buildStatColumn("Start", "${startWeight.toStringAsFixed(1)} kg"),
                  _buildStatColumn("Current", "${currentWeight.toStringAsFixed(1)} kg"),
                  _buildStatColumn("Lost", "${lossSoFar.toStringAsFixed(1)} kg"),
                  _buildStatColumn("To Go", "${remainingWeight.toStringAsFixed(1)} kg"),
                ]),
              ],
            ),
          )),
        ],
      ),
    );
  }
  Widget _buildStatColumn(String label, String value) {
    return Expanded(child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 2)])),
      ],
    ));
  }
}
class _BlurredImageBackground extends StatelessWidget {
  final String imageUrl;
  const _BlurredImageBackground({required this.imageUrl});
  @override
  Widget build(BuildContext context) {
    return Image.network(imageUrl, fit: BoxFit.cover, color: Colors.grey.shade900.withOpacity(0.3), colorBlendMode: BlendMode.darken,
      errorBuilder: (context, error, stackTrace) => Container(color: Colors.blueGrey, child: const Icon(Icons.broken_image, color: Colors.white)),
    );
  }
}
class _SleekProgressBar extends StatelessWidget {
  final double progress; final double startValue; final double currentValue; final double targetValue;
  const _SleekProgressBar({ required this.progress, required this.startValue, required this.currentValue, required this.targetValue });
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final double width = constraints.maxWidth;
      final double currentMarkerLeft = (width * progress).clamp(0.0, width);
      return Column(children: [
        Stack(clipBehavior: Clip.none, children: [
          Container(height: 8, decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(10))),
          AnimatedContainer(
            duration: const Duration(milliseconds: 600), curve: Curves.easeOutCubic, width: width * progress, height: 8,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF8BC34A), Color(0xFF4CAF50)], begin: Alignment.centerLeft, end: Alignment.centerRight),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.4), blurRadius: 8, spreadRadius: -2)],
            ),
          ),
          Positioned(left: currentMarkerLeft - 8, top: -4, child: Container(
            width: 16, height: 16,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, border: Border.all(color: Colors.green, width: 3), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)]),
          )),
        ]),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('${startValue.toStringAsFixed(0)} kg', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          Text('${targetValue.toStringAsFixed(0)} kg', style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ]),
      ]);
    });
  }
}
class _LogWeightSheet extends StatefulWidget {
  final double initialWeight; final Function(double) onLog;
  const _LogWeightSheet({required this.initialWeight, required this.onLog});
  @override
  State<_LogWeightSheet> createState() => _LogWeightSheetState();
}
class _LogWeightSheetState extends State<_LogWeightSheet> {
  late double _selectedWeight;
  @override
  void initState() { super.initState(); _selectedWeight = widget.initialWeight; }
  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0))),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 16),
            Text('Log Your Weight', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Slide to select your current weight.', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 24),
            Text.rich(TextSpan(
              text: _selectedWeight.toStringAsFixed(1),
              style: Theme.of(context).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.primary),
              children: <TextSpan>[TextSpan(text: ' kg', style: TextStyle(fontSize: 20, fontWeight: FontWeight.normal, color: Colors.grey[800]))],
            )),
            Slider(value: _selectedWeight, min: 40, max: 150, divisions: 1100, onChanged: (value) => setState(() => _selectedWeight = value)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => widget.onLog(_selectedWeight),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.orange, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Confirm & Log', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
          ]),
        ),
      ),
    );
  }
}
class _AnimatedCount extends StatefulWidget {
  final double end;
  final TextStyle? style;
  final int precision;

  const _AnimatedCount({
    required this.end,
    this.style,
    this.precision = 0,
  });

  @override
  _AnimatedCountState createState() => _AnimatedCountState();
}
class _AnimatedCountState extends State<_AnimatedCount> with SingleTickerProviderStateMixin {
  late AnimationController _controller; late Animation<double> _animation;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _animation = Tween<double>(begin: 0, end: widget.end).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }
  @override
  void didUpdateWidget(covariant _AnimatedCount oldWidget) {
    super.didUpdateWidget(oldWidget);
    if(widget.end != oldWidget.end) {
      _animation = Tween<double>(begin: oldWidget.end, end: widget.end).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      _controller.forward(from: 0.0);
    }
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: _animation, builder: (context, child) => Text(_animation.value.toStringAsFixed(widget.precision), style: widget.style));
  }
}
class _InteractiveCard extends StatefulWidget {
  final Widget child; final VoidCallback? onTap; final EdgeInsetsGeometry padding;
  const _InteractiveCard({required this.child, this.onTap, this.padding = EdgeInsets.zero});
  @override
  State<_InteractiveCard> createState() => _InteractiveCardState();
}
class _InteractiveCardState extends State<_InteractiveCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller; late Animation<double> _scaleAnimation;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) { _controller.reverse(); widget.onTap?.call(); },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(24.0), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 15, spreadRadius: -5, offset: const Offset(0, 5))]),
          child: Container(
            padding: widget.padding,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), borderRadius: BorderRadius.circular(24.0), border: Border.all(color: Colors.white.withOpacity(0.3))),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
class StaggeredAnimation extends StatefulWidget {
  final Widget child; final int index;
  const StaggeredAnimation({super.key, required this.child, required this.index});
  @override
  State<StaggeredAnimation> createState() => _StaggeredAnimationState();
}
class _StaggeredAnimationState extends State<StaggeredAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller; late Animation<double> _opacity; late Animation<Offset> _slide;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    final delay = (widget.index * 80).clamp(0, 400);
    _opacity = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _slide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    Future.delayed(Duration(milliseconds: delay), () { if (mounted) _controller.forward(); });
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => FadeTransition(opacity: _opacity, child: SlideTransition(position: _slide, child: widget.child));
}
// MODIFIED _ProgressRingPainter to be reusable with custom colors
class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color backgroundColor;

  _ProgressRingPainter({required this.progress, this.progressColor = Colors.blue, this.backgroundColor = Colors.grey});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: size.width / 2);
    const strokeWidth = 8.0;

    // Background Arc
    final backgroundPaint = Paint()
      ..color = backgroundColor.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi, false, backgroundPaint);

    // Progress Arc
    final progressPaint = Paint()
      ..shader = SweepGradient(
        colors: [progressColor.withOpacity(0.5), progressColor.withOpacity(0.8)],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) => oldDelegate.progress != progress;
}