import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fyp/screens/userMealPlanScreen.dart';
import 'package:fyp/services/config_service.dart';
// import 'package:fyp/services/config_service.dart'; // Commented out to use mock baseURL
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import 'dart:math' as math;
// Removed fl_chart import

// Mocking Dependencies and Helpers from other files

class AuthService {
  // Static const String _tokenKey = 'auth_token';
  Future<String?> getToken() async {
    // Mock token
    return 'mock_auth_token_12345';
  }
}

// ------------------------------------------------------------
// --- NEW WIDGET: Creative Health Loader (Pulsing Animation) ---
// ------------------------------------------------------------

class CreativeHealthLoader extends StatefulWidget {
  const CreativeHealthLoader({super.key});

  @override
  State<CreativeHealthLoader> createState() => _CreativeHealthLoaderState();
}

class _CreativeHealthLoaderState extends State<CreativeHealthLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  // New dark yellow color for the loader icon (matches step chart color)
  final Color darkYellow = const Color(0xFFFFA000);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true); // Repeat the animation back and forth

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Icon(
                  Icons.monitor_heart_rounded,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary, // Used new color
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            'Analyzing Health Data...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Generating personalized recommendations.',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.primary, // Used new color
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// --- Mocking Dependencies and Helpers from other files ---
// ------------------------------------------------------------

// Recreating StaggeredAnimation to match the style of HomePage.dart
class StaggeredAnimation extends StatefulWidget {
  final Widget child;
  final int index;
  const StaggeredAnimation(
      {super.key, required this.child, required this.index});
  @override
  State<StaggeredAnimation> createState() => _StaggeredAnimationState();
}

class _StaggeredAnimationState extends State<StaggeredAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    final delay = (widget.index * 80).clamp(0, 400);
    _opacity = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _slide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child));
}

// Recreating _InteractiveCard to match the style of HomePage.dart
class _InteractiveCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final bool isWarning;
  final bool isGlass; // Added property for the new style

  const _InteractiveCard({
    required this.child,
    this.onTap,
    this.padding = EdgeInsets.zero,
    this.isWarning = false,
    this.isGlass = false, // Default is false
  });
  @override
  State<_InteractiveCard> createState() => _InteractiveCardState();
}

class _InteractiveCardState extends State<_InteractiveCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final warningGradient = LinearGradient(
      colors: [
        Colors.white.withOpacity(0.95),
        Colors.red.shade50.withOpacity(0.9),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    // Regular Gradient for white background (slightly off-white)
    final regularGradient = LinearGradient(
      colors: [Colors.white.withOpacity(0.85), Colors.white.withOpacity(0.75)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    // New Glass Gradient (White/Clear)
    final glassGradient = LinearGradient(
      colors: [
        Colors.white.withOpacity(0.3),
        Colors.white.withOpacity(0.1),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    // Common border radius for the card
    const cardRadius = 24.0;

    Widget cardContent = Container(
      padding: widget.padding,
      decoration: BoxDecoration(
          // Use a special gradient for glass, warning for warning, and regular otherwise
          gradient: widget.isGlass
              ? glassGradient
              : widget.isWarning
                  ? warningGradient
                  : regularGradient,
          borderRadius: BorderRadius.circular(cardRadius),
          border: Border.all(
              color: widget.isGlass
                  ? Colors.white.withOpacity(0.4)
                  : Colors.white.withOpacity(widget.isWarning ? 0.8 : 0.3),
              width: widget.isGlass ? 1 : 1)),
      child: widget.child,
    );

    // Apply BackdropFilter only for Glass style
    if (widget.isGlass) {
      cardContent = ClipRRect(
        borderRadius: BorderRadius.circular(cardRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: cardContent,
        ),
      );
    }

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(cardRadius),
            boxShadow: [
              BoxShadow(
                color: widget.isWarning
                    ? Colors.red.withOpacity(0.3)
                    : widget.isGlass
                        ? Colors.black.withOpacity(0.1)
                        : primaryColor.withOpacity(0.1),
                blurRadius: 15,
                spreadRadius: widget.isWarning ? 2 : -5,
                offset: const Offset(0, 5),
              )
            ],
          ),
          child: cardContent,
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// --- Data Models for AI Response and Step Analysis ---
// ------------------------------------------------------------

// Helper enum for risk/consumption levels
enum Likelihood {
  low,
  medium,
  high, // Added 'high' to differentiate from 'veryHigh'
  veryHigh,
}

// Map string to enum
Likelihood parseLikelihood(String? value) {
  switch (value?.toLowerCase()) {
    case 'medium':
      return Likelihood.medium;
    case 'high':
      return Likelihood.high; // Differentiate 'high'
    case 'very high':
      return Likelihood.veryHigh;
    case 'low':
    default:
      return Likelihood.low;
  }
}

// Data model for the entire AI response
class HealthAnalysis {
  final Map<String, Likelihood> healthRisks;
  final Map<String, Likelihood> consumptionWarnings;
  final List<String> recommendations;
  final Map<String, dynamic> userProfile;

  HealthAnalysis({
    required this.healthRisks,
    required this.consumptionWarnings,
    required this.recommendations,
    required this.userProfile,
  });

  factory HealthAnalysis.fromJson(Map<String, dynamic> json) {
    final risksMap = (json['health_risks'] as Map<String, dynamic>?) ?? {};
    final consumptionMap = (json['consumption'] as Map<String, dynamic>?) ?? {};
    final profileMap = (json['profile'] as Map<String, dynamic>?) ?? {};

    return HealthAnalysis(
      healthRisks: risksMap.map((k, v) => MapEntry(k, parseLikelihood(v))),
      consumptionWarnings:
          consumptionMap.map((k, v) => MapEntry(k, parseLikelihood(v))),
      recommendations: (json['recommendations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      // NOTE: userProfile map now contains cleaned values (number instead of string+unit)
      userProfile: profileMap,
    );
  }
}

// Data model for Step Analysis
class StepAnalysis {
  final bool okData;
  final List<int> steps;

  StepAnalysis({required this.okData, required this.steps});

  factory StepAnalysis.fromJson(Map<String, dynamic> json) {
    return StepAnalysis(
      okData: json['OkData'] as bool,
      // Map dynamic list to int list
      steps: (json['steps'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
          [],
    );
  }
}

// ------------------------------------------------------------
// --- ( ENTIRE WIDGET REBUILT ) ---
// --- CREATIVE WIDGET: Daily Steps Chart (Data Fetching & Display) ---
// ------------------------------------------------------------

// 2. Custom Painter for the Radial "Speedometer"
// (MOVED a-SIDE a)
class _StepRadialPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final Color color;
  final Color trackColor;

  _StepRadialPainter(
      {required this.progress,
      required this.color,
      required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    const double strokeWidth = 12.0;
    final Offset center = size.center(Offset.zero);
    final double radius = (size.width - strokeWidth) / 3;

    // Define the "speedometer" arcs
    const double startAngle = -math.pi * 0.85; // ~2 o'clock
    const double totalAngle = math.pi * 1.7; // ~10 o'clock

    // Paint for the background track
    final Paint trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Paint for the progress arc
    final Paint progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Draw the track
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      totalAngle,
      false,
      trackPaint,
    );

    // Draw the progress
    final double progressAngle = progress * totalAngle;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      progressAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class DailyStepsChartCard extends StatefulWidget {
  const DailyStepsChartCard({super.key});

  @override
  State<DailyStepsChartCard> createState() => _DailyStepsChartCardState();
}

class _DailyStepsChartCardState extends State<DailyStepsChartCard> {
  late Future<StepAnalysis> _stepAnalysisFuture;
  final AuthService _authService = AuthService();

  // Color palette for the new dark card
  final Color darkYellow =
      const Color(0xFFFFA000); // Amber 700 (Used for achievement)
  final Color cardBackgroundColor =
      const Color(0xFF1A2E35); // Dark Teal/Blue
  final Color cardBackgroundGradientEnd =
      const Color(0xFF1A2E35); // Darker shade
  final Color progressTrackColor = Colors.white.withOpacity(0.1);
  final Color lightTextColor = Colors.white.withOpacity(0.8);
  final Color veryLightTextColor = Colors.white.withOpacity(0.4);

  final stepGoal = 10000.0; // The fixed goal

  @override
  void initState() {
    super.initState();
    _stepAnalysisFuture = _fetchStepAnalysis();
  }

  // UNCHANGED: Fetch logic for step data
  Future<StepAnalysis> _fetchStepAnalysis() async {
    final String apiUrl = '$baseURL/api/get_last_7days_steps';
    final token = await _authService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Authentication required for step data.');
    }

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonBody = json.decode(response.body);
        return StepAnalysis.fromJson(jsonBody);
      } else {
        // Fallback for failed API, keeping the existing structure
        print(
            'Step API failed with status ${response.statusCode}. Falling back to mock data.');
        final mockData = {
          'OkData': true,
          'steps': [8000, 12000, 9500, 10500, 7000, 11000, 10000]
        };
        return StepAnalysis.fromJson(mockData);
      }
    } catch (e) {
      // Fallback for network error
      print(
          'Network error for step data: ${e.toString()}. Falling back to mock data.');
      final mockData = {
        'OkData': true,
        'steps': [8000, 12000, 9500, 10500, 7000, 11000, 10000]
      };
      return StepAnalysis.fromJson(mockData);
    }
  }

  // --- NEW WIDGETS FOR CREATIVE UI ---

  // 1. The main dark container for all states (loading, error, success)
  Widget _buildDarkContainer({required Widget child}) {
    return StaggeredAnimation(
      index: 2, // Keeps its place in the page animation
      child: Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cardBackgroundColor, cardBackgroundGradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: -5,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: child,
      ),
    );
  }

  // 2. Custom Painter for the Radial "Speedometer"
  /* (MOVED b-SIDE b) */

  // 3. Vertical bar for the weekly chart
  Widget _buildVerticalBar({
    required String dayLabel,
    required int steps,
    required double goal,
    required double maxSteps, // Max steps in the week for scaling
    required Color color,
  }) {
    const double maxBarHeight = 80.0;
    final bool achieved = steps >= goal;
    final double barHeight = (steps / maxSteps) * maxBarHeight;
    final barColor =
        achieved ? color : Colors.white.withOpacity(0.6);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // The animated bar
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: barHeight),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (context, height, child) {
            return Container(
              width: 18,
              height: height,
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        // Day label
        Text(
          dayLabel,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: achieved ? Colors.white : veryLightTextColor,
          ),
        ),
      ],
    );
  }

  // 4. NEW: Dark-themed widget for when data is not available
  Widget _buildDataNotAvailable(BuildContext context, StepAnalysis? analysis) {
    final bool notEnoughData = analysis?.okData == false;
    final String title;
    final String message;
    final IconData icon;

    // Use light text colors for the dark card
    final Color color = Colors.white.withOpacity(0.7);

    if (notEnoughData) {
      title = 'Insufficient Data';
      message = 'Need 7 full days of step history to show your dashboard.';
      icon = Icons.calendar_today_rounded;
    } else {
      title = 'Data Unavailable';
      message =
          'Feature isn\'t available, Server issue. Please try again later.';
      icon = Icons.gpp_bad_rounded;
    }

    return Container(
      height: 300, // Give it a fixed height
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: color.withOpacity(0.6)),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 5. NEW: Rebuilt Chart UI with "Speedometer" and Vertical Bars
  Widget _buildChartUI(BuildContext context, List<int> dailySteps) {
    // 1. Calculate Averages and Status
    final int recentSteps = dailySteps.last; // Get the most recent day
    final double progress = (recentSteps / stepGoal).clamp(0.0, 1.0);
    // Find max steps for scaling the bar chart
    final double maxWeeklySteps = (dailySteps.reduce(math.max) * 1.1);

    // Logic for dynamic day labels (Mon, Tue, etc.)
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final todayIndex = (DateTime.now().weekday - 1) % 7;

    List<String> chartDays = [];
    for (int i = 0; i < dailySteps.length; i++) {
      final dayOffset = (todayIndex - (dailySteps.length - 1) + i) % 7;
      final chartDayIndex = (dayOffset < 0 ? dayOffset + 7 : dayOffset);
      chartDays.add(days[chartDayIndex]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // --- HEADER ---
        Row(
          children: [
            Icon(Icons.directions_run_rounded, color: darkYellow, size: 28),
            const SizedBox(width: 10),
            Text(
              'Step Dashboard',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 50),

        // --- HERO SECTION: RADIAL "SPEEDOMETER" ---
        SizedBox(
          width: 200,
          height: 200,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: progress),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (context, animatedProgress, child) {
              return CustomPaint(
                painter: _StepRadialPainter(
                  progress: animatedProgress,
                  color: darkYellow,
                  trackColor: progressTrackColor,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20), // Offset for dial
                      Text(
                        '${recentSteps.toInt()}',
                        style: const TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '/ ${stepGoal.toInt()} steps',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: lightTextColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: recentSteps >= stepGoal
                              ? darkYellow.withOpacity(0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: recentSteps >= stepGoal
                                ? darkYellow
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          recentSteps >= stepGoal ? 'GOAL MET!' : 'Recent Day',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: recentSteps >= stepGoal
                                ? darkYellow
                                : lightTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 30,),
        const Divider(height: 40, color: Colors.white24, thickness: 1),

        // --- VISUALIZATION: WEEKLY VERTICAL BARS ---
        Text(
          'Weekly Review',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: lightTextColor,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 110, // Fixed height for bars + labels
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: dailySteps.asMap().entries.map((entry) {
              final index = entry.key;
              final steps = entry.value;

              return _buildVerticalBar(
                dayLabel: chartDays[index],
                steps: steps,
                goal: stepGoal,
                maxSteps: maxWeeklySteps,
                color: darkYellow,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // --- Main Build Method (FutureBuilder) ---
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StepAnalysis>(
      future: _stepAnalysisFuture,
      builder: (context, snapshot) {
        // STATE 1: LOADING
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildDarkContainer(
            child: const SizedBox(
              height: 300, // Give it a fixed height
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFFFA000), // Use darkYellow
                  strokeWidth: 2.0,
                ),
              ),
            ),
          );
        }

        // STATE 2: ERROR or OK_DATA = FALSE
        if (snapshot.hasError || (snapshot.hasData && !snapshot.data!.okData)) {
          return _buildDarkContainer(
            child: _buildDataNotAvailable(context, snapshot.data),
          );
        }

        // STATE 3: SUCCESS
        // (snapshot.hasData && snapshot.data!.okData)
        final dailySteps = snapshot.data!.steps;
        return _buildDarkContainer(
          child: _buildChartUI(context, dailySteps),
        );
      },
    );
  }
}

// ------------------------------------------------------------
// --- REFACTORED WIDGET: Health Snapshot Content (for Header) ---
// ------------------------------------------------------------

class _HealthSnapshotContent extends StatelessWidget {
  final HealthAnalysis analysis;
  // Removed shrinkOffset and maxExtent, as the header is now static

  const _HealthSnapshotContent({
    required this.analysis,
  });

  String _formatValue(dynamic value, String unit) {
    // If the value is already a number (due to cleaning in _cleanProfileValues), display it.
    if (value is num) {
      return '${value.round()} $unit';
    } else if (value != null) {
      // Fallback for any other string value (shouldn't happen with cleaning)
      return '$value $unit';
    }
    return 'N/A';
  }

  @override
  Widget build(BuildContext context) {
    // Map the keys from the API's 'profile' to the display strings and icons
    // The units are added here, but the values in `analysis.userProfile` are now cleaned numbers.
    final entries = [
      {
        'label': 'Avg. Calories',
        'value': _formatValue(
            analysis.userProfile['Average Calories'], 'kcal'),
        'icon': Icons.local_fire_department
      },
      {
        'label': 'Avg. Sugar',
        'value': _formatValue(
            analysis.userProfile['Average Blood Sugar'], 'mg/dL'),
        'icon': Icons.bloodtype_rounded
      },
      {
        'label': 'Avg. Cholesterol',
        'value': _formatValue(
            analysis.userProfile['Average Cholesterol'], 'mg/dL'),
        'icon': Icons.spa_rounded
      },
      {
        'label': 'Avg. Fats',
        'value': _formatValue(analysis.userProfile['Average Fats'], 'g'),
        'icon': Icons.opacity_rounded
      },
      {
        'label': 'Avg. Carbs',
        'value': _formatValue(analysis.userProfile['Average Carbs'], 'g'),
        'icon': Icons.grain_rounded
      },
      {
        'label': 'Avg. Protein',
        'value': _formatValue(analysis.userProfile['Average Protein'], 'g'),
        'icon': Icons.egg_alt_outlined
      },
      {
        'label': 'Cals Burned',
        'value': _formatValue(
            analysis.userProfile['Average Calories Burned'], 'kcal'),
        'icon': Icons.directions_run
      },
    ];

    final currentCondition = analysis.userProfile['Health Conditions'] != null
        ? analysis.userProfile['Health Conditions'].toString()
        : 'None Reported';

    // The logic for collapseFactor, opacity, and offsetY has been removed.
    final double opacity = 1.0;
    final double offsetY = 0.0;

    return Opacity(
      opacity: opacity,
      child: Transform.translate(
        offset: Offset(0, offsetY),
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            // Stretch to allow the inner column to take full width for centering
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // FIX: Add spacing at the top to push content down from the roof
              const SizedBox(height: 30),

              // Header with current health condition
              Column(
                // Center the text content (REQUESTED CHANGE)
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 30),

                  // Removed the icon and SizedBox here (REQUESTED CHANGE)
                  const Text(
                    'Your Health Snapshot',
                    textAlign: TextAlign.center, // Center the text (REQUESTED CHANGE)
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Condition: ${currentCondition.isNotEmpty ? currentCondition : 'None Reported'}',
                    textAlign: TextAlign.center, // Center the text (REQUESTED CHANGE)
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Grid of Metrics (Wrapped in a glass card for contrast)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                  child: Container(
                    // FIX: Moved the color property into the BoxDecoration
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2), // Semi-transparent white
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.3), width: 1),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 1.5,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: 6, // Show only the first 6 metrics for space
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              entry['value'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                      color: Colors.black38,
                                      blurRadius: 1,
                                      offset: Offset(0, 0.5))
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              entry['label'] as String,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white.withOpacity(0.8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// --- NEW WIDGET: Static Header (Replaces SliverAppBar) ---
// ------------------------------------------------------------
class _StaticHeader extends StatelessWidget {
  final HealthAnalysis analysis;
  const _StaticHeader({required this.analysis});

  // FIX: Increased height from 300.0 to 400.0 to prevent pixel overflow and give more space
  static const double fixedHeight = 400.0;

  @override
  Widget build(BuildContext context) {
    // The background image URL from the old _NutritionTipsHeader
    const String imageUrl =
        'https://images.unsplash.com/photo-1625937286074-9ca519d5d9df?ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80&w=1332';

    return SliverToBoxAdapter(
      child: ClipRRect(
        // Retain the rounded bottom border from the original header
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
        child: SizedBox(
          height: fixedHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Background Image
              CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                errorWidget: (context, error, stackTrace) =>
                    Container(color: Theme.of(context).colorScheme.primary),
              ),

              // 2. Blurred effect (REQUESTED CHANGE) and Dark Overlay
              ClipRRect(
                child: BackdropFilter(
                  filter:
                      ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0), // Added blur
                  child: Container(
                    // Dark Overlay for text contrast (similar to HomePage.dart)
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          // FIX: Slightly lighten the top overlay for image visibility
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.1),
                          Colors.black.withOpacity(0.0),
                        ],
                        stops: const [0.0, 0.4, 1.0],
                      ),
                    ),
                  ),
                ),
              ),

              // 3. Health Snapshot Content
              Align(
                alignment: Alignment.bottomCenter,
                child: _HealthSnapshotContent(analysis: analysis),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// --- Main Page Widget (Keep the rest of the code) ---
// ------------------------------------------------------------

class NutritionTipsPage extends StatefulWidget {
  const NutritionTipsPage({super.key});

  @override
  State<NutritionTipsPage> createState() => _NutritionTipsPageState();
}

class _NutritionTipsPageState extends State<NutritionTipsPage> {
  late Future<HealthAnalysis> _analysisFuture;
  final AuthService _authService = AuthService();

  // User's current data (mocked to match the backend snippet)
  final Map<String, dynamic> _userData = {
    'averageCalories': 1000,
    'averageSugar': 120,
    'averageFats': 35,
    'averageCholesterol': 210,
    'averageCarbs': 250,
    'averageProtein': 50,
    'averageCaloriesBurned': 500,
    'currentHealthCondition': ["Hypertension"],
  };

  @override
  void initState() {
    super.initState();
    _analysisFuture = _fetchHealthAnalysis();
  }
  
  // FIX: Helper to clean profile values from "100 kcal" (String) to 100 (num)
  Map<String, dynamic> _cleanProfileValues(Map<String, dynamic> rawJson) {
    final profile = rawJson['profile'] as Map<String, dynamic>?;
    if (profile == null) return rawJson;

    final keysToClean = [
      'Average Calories',
      'Average Blood Sugar',
      'Average Cholesterol',
      'Average Fats',
      'Average Carbs',
      'Average Protein',
      'Average Calories Burned'
    ];

    for (var key in keysToClean) {
      var value = profile[key];
      if (value is String) {
        // Use regex to extract the first number found (integer or decimal)
        // This handles "100 kcal", "12 mg/dL", etc.
        final numberMatch = RegExp(r"(\d+(\.\d+)?)").firstMatch(value);
        if (numberMatch != null) {
          // Replace the string with the parsed number
          profile[key] = num.tryParse(numberMatch.group(0)!) ?? value;
        }
      }
    }
    return rawJson;
  }

  // --- CORRECTED API Fetch Logic (Actual Implementation) ---
  Future<HealthAnalysis> _fetchHealthAnalysis() async {
    // 1. Use ConfigService for the correct API URL
    final String apiUrl = '$baseURL/api/generate-ai-content';
    final token = await _authService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Authentication required.');
    }

    try {
      // 2. Perform the HTTP POST call
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        // Send the user's data as the request body, which the backend expects.
        body: json.encode(_userData),
      );

      if (response.statusCode == 200) {
        String responseBody = response.body;

        // --- CRITICAL FIX START: Robust JSON Parsing ---
        String aiJsonString;
        dynamic firstDecode;

        // Step 1: Attempt to decode the response body.
        try {
          // This will fail if the body is wrapped in "```json\n{...}\n```"
          firstDecode = json.decode(responseBody);
        } catch (_) {
          // If the first decode fails, treat the body as a raw string.
          firstDecode = responseBody;
        }

        if (firstDecode is String) {
          aiJsonString = firstDecode.trim();

          // Step 2: Clean the raw JSON string by removing wrapping quotes and Markdown fences.
          // FIX: Explicitly remove Markdown fences "```json\n" and "\n```"
          aiJsonString = aiJsonString.replaceAll('```json', '').replaceAll('```', '').trim();

          // Also remove any remaining surrounding double quotes if they exist (e.g. from an outer server layer)
          if (aiJsonString.startsWith('"') && aiJsonString.endsWith('"')) {
            aiJsonString = aiJsonString.substring(1, aiJsonString.length - 1);
          }

          // Final sanity check
          if (!aiJsonString.startsWith('{')) {
            throw Exception(
                'Cleaned string is not valid JSON (Missing starting curly brace). Raw: $responseBody');
          }

          // Step 3: Perform the final decode to get the usable Map
          final Map<String, dynamic> aiJson = json.decode(aiJsonString);

          // Step 4: Clean the profile values (e.g., "100 kcal" -> 100)
          final cleanedJson = _cleanProfileValues(aiJson);
          return HealthAnalysis.fromJson(cleanedJson);

        } else if (firstDecode is Map<String, dynamic>) {
          // Response was clean JSON, just needs value cleaning
          final cleanedJson = _cleanProfileValues(firstDecode);
          return HealthAnalysis.fromJson(cleanedJson);
        } else {
          throw Exception(
              'AI content response format is unexpected: not a string or map after first decode.');
        }
        // --- CRITICAL FIX END ---
      } else {
        // Log the status code and body for debugging
        print(
            'AI Content API failed: ${response.statusCode}, Body: ${response.body}');
        throw Exception(
            'Failed to generate health analysis. Status: ${response.statusCode}. Body: ${response.body}');
      }
    } on http.ClientException {
      // Handle network errors (e.g., no internet, server not running)
      throw Exception(
          'Network error: Could not connect to backend server. Ensure server is running at ');
    } catch (e) {
      // Catch all other errors
      print('DEBUG ERROR: Health analysis fetch failed: $e');
      throw Exception('Could not fetch health analysis: ${e.toString()}');
    }
  }

  // --- UI Helper Functions ---

  Color _getRiskColor(Likelihood likelihood) {
    switch (likelihood) {
      case Likelihood.veryHigh:
        return Colors.red.shade700;
      case Likelihood.high:
        return Colors.orange.shade700;
      case Likelihood.medium:
        return Colors.amber.shade700;
      case Likelihood.low:
      default:
        return Colors.green.shade700;
    }
  }

  IconData _getRiskIcon(String risk) {
    switch (risk.toLowerCase()) {
      case 'hypertension':
        return Icons.monitor_heart_rounded;
      case 'diabetes':
        return Icons.bloodtype_rounded;
      case 'obesity':
        return Icons.monitor_weight_rounded;
      case 'high cholesterol':
        return Icons.spa_rounded;
      case 'heart disease':
        return Icons.favorite_rounded;
      case 'arthritis':
        return Icons.accessible_forward_rounded;
      case 'asthma':
        return Icons.air_rounded;
      default:
        return Icons.health_and_safety_rounded;
    }
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  Widget _buildSectionHeader(
      BuildContext context, String title, IconData icon) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 16, left: 20, right: 20),
      child: Row(
  mainAxisAlignment: MainAxisAlignment.center, // Center horizontally
  children: [
    const SizedBox(width: 12),
    Expanded(
      child: Text(
        title,
        textAlign: TextAlign.center, // Center text within Expanded
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.grey[800],
        ),
        overflow: TextOverflow.ellipsis,
      ),
    ),
  ],
),

    );
  }

  Widget _buildRiskPredictionGrid(HealthAnalysis analysis) {
    // Filter to show only HIGH and VERY HIGH risks
    final highRisks = analysis.healthRisks.entries
        .where((e) => e.value.index >= Likelihood.high.index)
        .toList()
      ..sort((a, b) => b.value.index.compareTo(a.value.index));

    // Staggered index starts after DailyStepsChartCard (index 2)
    const int initialStaggerIndex = 3;

    if (highRisks.isEmpty) {
      return StaggeredAnimation(
        index: initialStaggerIndex,
        child: Padding(
  padding: const EdgeInsets.only(left: 20, right: 20, top: 0, bottom: 0),
          child: _InteractiveCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.thumb_up_alt_rounded,
                    color: Colors.green.shade700, size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Great job! No immediate high health risks detected based on your current data.',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                        fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
  padding: const EdgeInsets.only(left: 20, right: 20, top: 0, bottom: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          GridView.builder(
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
            ),
            itemCount: highRisks.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final risk = highRisks[index];
              final riskColor = _getRiskColor(risk.value);
              final levelText =
                  risk.value.toString().split('.').last.toUpperCase();

              return StaggeredAnimation(
                index: index + initialStaggerIndex,
                child: _InteractiveCard(
                  isWarning: true, // Always true for highRisks
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // --- 1. Elevated Icon (More pronounced) ---
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: riskColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: riskColor.withOpacity(0.5), width: 1),
                        ),
                        child: Icon(_getRiskIcon(risk.key),
                            size: 36, color: riskColor),
                      ),
                      const SizedBox(height: 12),

                      // --- 2. Risk Name (More prominent) ---
                      Expanded(
                        child: Text(
                          risk.key,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),

                      // --- 3. Level Badge (Stylized) ---
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: riskColor.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: riskColor.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ]),
                        child: Text(
                          levelText,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildConsumptionWarnings(HealthAnalysis analysis) {
    // Filter to show only HIGH and VERY HIGH consumption warnings
    final warnings = analysis.consumptionWarnings.entries
        .where((e) => e.value.index >= Likelihood.high.index)
        .toList()
      ..sort((a, b) => b.value.index.compareTo(a.value.index));

    if (warnings.isEmpty) {
      return const SizedBox.shrink(); // Hide if no critical warnings
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: warnings.map((warning) {
          final warningColor = _getRiskColor(warning.value);
          final level = warning.value.toString().split('.').last;

          return StaggeredAnimation(
            index: warnings.indexOf(warning) + 12,
            child: _InteractiveCard(
              isWarning: true,
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.warning_rounded, color: warningColor, size: 36),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CRITICAL ${_capitalize(warning.key)} Intake',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: warningColor,
                              fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your average intake is at a "${level.replaceAll('_', ' ')}" level. Immediate action is required.',
                          style:
                              TextStyle(color: Colors.grey[700], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: warningColor.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      level.toUpperCase(),
                      style: TextStyle(
                          color: warningColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecommendations(HealthAnalysis analysis) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: StaggeredAnimation(
        index: 14,
        child: _InteractiveCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              

              // --- ENHANCED RECOMMENDATION LIST (Timeline/Step-by-Step) ---
              ...analysis.recommendations.asMap().entries.map((entry) {
                final index = entry.key;
                final recommendation = entry.value;
                final isLast = index == analysis.recommendations.length - 1;

                return StaggeredAnimation(
                  index: index + 15,
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Step Indicator and Vertical Line
                        Column(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                  color: primaryColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    // Add subtle shadow for lift
                                    BoxShadow(
                                        color: primaryColor.withOpacity(0.4),
                                        blurRadius: 5,
                                        offset: const Offset(0, 2))
                                  ]),
                              child: Center(
                                child: Text(
                                  (index + 1).toString(), // Step number
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            if (!isLast)
                              Expanded(
                                child: Container(
                                  width: 2,
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        // Recommendation Text
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                                bottom: isLast ? 0 : 20.0, top: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "STEP ${index + 1}", // Bold Step label
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  recommendation,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[800],
                                    height: 1.4,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Page background remains the same as requested
    const Color pageBackgroundColor = const Color(0xffa8edea);

    return Scaffold(
      backgroundColor: pageBackgroundColor, // UNCHANGED
      // REMOVED old AppBar
      body: FutureBuilder<HealthAnalysis>(
        future: _analysisFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Loader when waiting for data
            return const CreativeHealthLoader();
          }

          if (snapshot.hasError) {
            // Error handling
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.gpp_bad_rounded,
                        color: Colors.red.shade400, size: 60),
                    const SizedBox(height: 16),
                    Text(
                      "Feature Unavailable",
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    // Display the requested user-friendly message
                    Text(
                      "Feature isn't available, Server issue. Please try again later.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[700], fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    // Show the error detail for debugging
                    Text(
                      'Details: ${snapshot.error.toString()}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
            );
          }

          if (snapshot.hasData) {
            final analysis = snapshot.data!;

            // USE CUSTOMSCROLLVIEW
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 1. STATIC HEADER (New _StaticHeader replaces _NutritionTipsHeader)
                _StaticHeader(analysis: analysis),

                // 2. MAIN PAGE CONTENT (Wrapped in a SliverList)
                SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      const SizedBox(height: 10), // Padding below the header

                      // Meal Plan Card (Staggered index is 1, as it's the first card in the list)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: _MealPlanCard(),
                      ),

                                            const SizedBox(height: 30,),


                      // Steps card
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        // THIS IS THE WIDGET THAT WAS REBUILT
                        child: DailyStepsChartCard(),
                      ),

                                            const SizedBox(height: 30,),


                      // Risk Predictions Section (starts around index 3/4)
                      _buildSectionHeader(
                          context, 'Health Risk Prediction', Icons.psychology),
                      _buildRiskPredictionGrid(analysis),


                      const SizedBox(height: 30,),

                      // Recommendations Section
                      _buildSectionHeader(
                          context, 'Action Plan', Icons.list_alt_rounded),
                      _buildRecommendations(analysis),

                      const SizedBox(height: 40),

                      // Consumption Warnings Section
                      if (analysis.consumptionWarnings.entries
                          .where((e) => e.value.index >= Likelihood.high.index)
                          .isNotEmpty)
                        Column(
                          children: [
                            _buildSectionHeader(context,
                                'Critical Intake Warnings', Icons.local_fire_department_rounded),
                            _buildConsumptionWarnings(analysis),
                            const SizedBox(height: 40),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            );
          }

          return const Center(child: Text("Waiting for analysis data..."));
        },
      ),
    );
  }
}

class _MealPlanCard extends StatelessWidget {
  const _MealPlanCard();

  // Helper to determine the current day number (1=Monday, 7=Sunday)
  int _getCurrentDayOfWeek() {
    // Dart's DateTime.weekday returns 1 for Monday through 7 for Sunday.
    return DateTime.now().weekday;
  }

  @override
  Widget build(BuildContext context) {
    const String imageUrl =
        'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1780&q=80';
    final cardColor = Colors.teal;

    // Calculate the current day count to pass to the indicator
    final currentDay = _getCurrentDayOfWeek();

    return SizedBox(
        height: 200,
        child: StaggeredAnimation(
            index: 1, // Changed to index 1 as it is the first card in the list
            // FIX: Replaced _TiltableCard with the simpler _InteractiveCard
            child: _InteractiveCard(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const UserMealPlanScreen())),
                child: Stack(fit: StackFit.expand, children: [
                  ClipRRect(
                      borderRadius: BorderRadius.circular(24.0),
                      child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          color: cardColor.withOpacity(0.5),
                          colorBlendMode: BlendMode.colorBurn,
                          errorWidget: (context, error, stackTrace) =>
                              Container(color: cardColor.shade400))),
                  ClipRRect(
                      borderRadius: BorderRadius.circular(24.0),
                      child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                          child: Container(
                              decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.5)),
                                  borderRadius: BorderRadius.circular(24.0)),
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                  // Removed const here to allow dynamic widget below
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Column(
                                              // Added const back to static Column
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text('Weekly Nutrition',
                                                    style: TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w500)),
                                                SizedBox(height: 4),
                                                Text('Get On Track!',
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 26,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        letterSpacing: 0.5))
                                              ]),

                                          // FIX: Pass the dynamically calculated currentDay
                                          _PlanProgressIndicator(
                                              plannedDays: currentDay)
                                        ]),
                                    const _MealPlanCtaChip(
                                        accentColor: Colors.white)
                                  ]))))
                ]))));
  }
}

class _PlanProgressIndicator extends StatelessWidget {
  final int plannedDays;
  final int totalDays;
  const _PlanProgressIndicator({this.totalDays = 7, required this.plannedDays});

  // Helper to calculate progress
  double get progress => plannedDays / totalDays;

  @override
  Widget build(BuildContext context) => SizedBox(
      width: 50,
      height: 50,
      child: Stack(alignment: Alignment.center, children: [
        SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
                value: progress, // Uses the calculated progress
                strokeWidth: 4,
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white))),

        // FIX: Display plannedDays / totalDays (e.g., 2/7)
        Text('$plannedDays/$totalDays',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))
      ]));
}

class _MealPlanCtaChip extends StatelessWidget {
  final Color accentColor;
  const _MealPlanCtaChip({required this.accentColor});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
          color: accentColor,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                spreadRadius: 1)
          ]),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.fastfood_rounded, color: Colors.teal.shade700, size: 20),
        const SizedBox(width: 8),
        Text('Explore Your Week',
            style: TextStyle(
                color: Colors.teal.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 15))
      ]));
}