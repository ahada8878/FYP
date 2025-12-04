import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fyp/screens/Features/label_scanner_page.dart';
import 'package:fyp/screens/userMealPlanScreen.dart';
import 'package:fyp/services/config_service.dart';
import 'package:fyp/services/health_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:lottie/lottie.dart';

// Mocking Dependencies
// Auth Service
class AuthService {
  static const String _tokenKey = 'auth_token';
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }
}

// ------------------------------------------------------------
// --- NEW WIDGET: Creative Health Loader (Matches Initial Style) ---
// ------------------------------------------------------------

class CreativeHealthLoader extends StatelessWidget {
  const CreativeHealthLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 110),

          // Glassmorphic Circle container
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 30
                )
              ],
            ),
            child: Lottie.asset(
              'assets/animation/Loading.json', 
              width: 200, 
              height: 200
            ),
          ),
          const SizedBox(height: 80),
          Text(
            "Analyzing Health Data...",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 50),
            child: Text(
              "Generating personalized recommendations based on your profile.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Color(0xFF636E72)),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// --- Animations & Cards ---
// ------------------------------------------------------------

class StaggeredAnimation extends StatefulWidget {
  final Widget child;
  final int index;
  const StaggeredAnimation({super.key, required this.child, required this.index});
  @override
  State<StaggeredAnimation> createState() => _StaggeredAnimationState();
}

class _StaggeredAnimationState extends State<StaggeredAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    final delay = (widget.index * 80).clamp(0, 400);
    _opacity = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _slide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
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
  Widget build(BuildContext context) => FadeTransition(opacity: _opacity, child: SlideTransition(position: _slide, child: widget.child));
}

class _InteractiveCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final bool isWarning;
  final bool isGlass;

  const _InteractiveCard({
    required this.child,
    this.onTap,
    this.padding = EdgeInsets.zero,
    this.isWarning = false,
    this.isGlass = false, 
  });
  @override
  State<_InteractiveCard> createState() => _InteractiveCardState();
}

class _InteractiveCardState extends State<_InteractiveCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
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
      colors: [Colors.white.withOpacity(0.95), Colors.red.shade50.withOpacity(0.9)],
      begin: Alignment.topLeft, end: Alignment.bottomRight,
    );
    final regularGradient = LinearGradient(
      colors: [Colors.white.withOpacity(0.9), Colors.white.withOpacity(0.8)],
      begin: Alignment.topLeft, end: Alignment.bottomRight,
    );
    final glassGradient = LinearGradient(
      colors: [Colors.white.withOpacity(0.3), Colors.white.withOpacity(0.1)],
      begin: Alignment.topLeft, end: Alignment.bottomRight,
    );

    const cardRadius = 24.0;
    Widget cardContent = Container(
      padding: widget.padding,
      decoration: BoxDecoration(
          gradient: widget.isGlass ? glassGradient : widget.isWarning ? warningGradient : regularGradient,
          borderRadius: BorderRadius.circular(cardRadius),
          border: Border.all(
              color: widget.isGlass ? Colors.white.withOpacity(0.4) : Colors.white.withOpacity(widget.isWarning ? 0.8 : 0.3),
              width: widget.isGlass ? 1 : 1)),
      child: widget.child,
    );

    if (widget.isGlass) {
      cardContent = ClipRRect(
        borderRadius: BorderRadius.circular(cardRadius),
        child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0), child: cardContent),
      );
    }

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) { _controller.reverse(); widget.onTap?.call(); },
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
                color: widget.isWarning ? Colors.red.withOpacity(0.3) : widget.isGlass ? Colors.black.withOpacity(0.1) : primaryColor.withOpacity(0.1),
                blurRadius: 15, spreadRadius: widget.isWarning ? 2 : -5, offset: const Offset(0, 5),
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
// --- Data Models ---
// ------------------------------------------------------------

enum Likelihood { low, medium, high, veryHigh }

Likelihood parseLikelihood(String? value) {
  switch (value?.toLowerCase()) {
    case 'medium': return Likelihood.medium;
    case 'high': return Likelihood.high;
    case 'very high': return Likelihood.veryHigh;
    case 'low': default: return Likelihood.low;
  }
}

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
      consumptionWarnings: consumptionMap.map((k, v) => MapEntry(k, parseLikelihood(v))),
      recommendations: (json['recommendations'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      userProfile: profileMap,
    );
  }
}

class StepAnalysis {
  final bool okData;
  final List<int> steps;

  StepAnalysis({required this.okData, required this.steps});

  factory StepAnalysis.fromJson(Map<String, dynamic> json) {
    // Ensure steps are parsed as int
    final List<dynamic> stepsData = json['steps'] ?? [];
    final List<int> parsedSteps = stepsData.map((s) => s as int? ?? 0).toList();

    return StepAnalysis(
      okData: json['OkData'] as bool? ?? false,
      steps: parsedSteps,
    );
  }
}

// ------------------------------------------------------------
// --- CHART PAINTER ---
// ------------------------------------------------------------

class _StepRadialPainter extends CustomPainter {
  final double progress; 
  final Color color;
  final Color trackColor;

  _StepRadialPainter({required this.progress, required this.color, required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    const double strokeWidth = 12.0;
    final Offset center = size.center(Offset.zero);
    final double radius = (size.width - strokeWidth) / 3;
    const double startAngle = -math.pi * 0.85; 
    const double totalAngle = math.pi * 1.7; 

    final Paint trackPaint = Paint()..color = trackColor..style = PaintingStyle.stroke..strokeWidth = strokeWidth..strokeCap = StrokeCap.round;
    final Paint progressPaint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = strokeWidth..strokeCap = StrokeCap.round;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, totalAngle, false, trackPaint);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, progress * totalAngle, false, progressPaint);
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
  final HealthService _healthService = HealthService();

  final Color darkYellow = const Color(0xFFFFA000); 
  final Color cardBackgroundColor = const Color(0xFF1A2E35); 
  final Color cardBackgroundGradientEnd = const Color(0xFF1A2E35); 
  final Color progressTrackColor = Colors.white.withOpacity(0.1);
  final Color lightTextColor = Colors.white.withOpacity(0.8);
  final Color veryLightTextColor = Colors.white.withOpacity(0.4);
  final stepGoal = 10000.0; 

  @override
  void initState() {
    super.initState();
    _stepAnalysisFuture = _fetchStepAnalysis();
  }
 
  Future<StepAnalysis> _fetchStepAnalysis() async {
    try {
      // Fetch steps with callbacks for user confirmation
      final List<int> realSteps = await _healthService.fetchWeeklySteps(
        // 1. Ask before Installing Health Connect (Android)
        onAppInstallConfirmation: () async {
          return await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("Install Google Health Connect?"),
                  content: const Text(
                      "To sync your steps, we need to install the Health Connect app. Would you like to proceed?"),
                  actions: [
                    TextButton(
                      onPressed: () =>
                          Navigator.pop(ctx, false), // User said No
                      child: const Text("No"),
                    ),
                    TextButton(
                      onPressed: () =>
                          Navigator.pop(ctx, true), // User said Yes
                      child: const Text("Install"),
                    ),
                  ],
                ),
              ) ??
              false; // Default to false if dismissed
        },

        // 2. Ask before Requesting Permissions
        onUserPermissionConfirmation: () async {
          return await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("Sync Step Data?"),
                  content: const Text(
                      "We can sync your steps from your phone to make your report more accurate. Allow access?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text("Allow"),
                    ),
                  ],
                ),
              ) ??
              false;
        },
      );

      // Process the data
      if (realSteps.isNotEmpty && realSteps.any((s) => s > 0)) {
        return StepAnalysis.fromJson({
          'OkData': true,
          'steps': realSteps,
        });
      } else {
        // If we got [0,0,0...] (either permission denied or new install), show dummy data
        throw Exception("No real data returned");
      }
    } catch (e) {
      print('Step fetch skipped or failed: $e. Using mock data.');

      // Fallback Mock Data
      final mockData = {
        'OkData': true,
        'steps': [8000, 12000, 9500, 10500, 7000, 11000, 10000]
      };
      return StepAnalysis.fromJson(mockData);
    }
  }
  


  Widget _buildDarkContainer({required Widget child}) {
    return StaggeredAnimation(
      index: 2, 
      child: Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cardBackgroundColor, cardBackgroundGradientEnd],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, spreadRadius: -5, offset: const Offset(0, 10))],
        ),
        child: child,
      ),
    );
  }

  Widget _buildVerticalBar({required String dayLabel, required int steps, required double goal, required double maxSteps, required Color color}) {
    const double maxBarHeight = 80.0;
    final bool achieved = steps >= goal;
    final double barHeight = (steps / maxSteps) * maxBarHeight;
    final barColor = achieved ? color : Colors.white.withOpacity(0.6);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: barHeight),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (context, height, child) {
            return Container(width: 18, height: height, decoration: BoxDecoration(color: barColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(6))));
          },
        ),
        const SizedBox(height: 6),
        Text(dayLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: achieved ? Colors.white : veryLightTextColor)),
      ],
    );
  }

  Widget _buildDataNotAvailable(BuildContext context, StepAnalysis? analysis) {
    final bool notEnoughData = analysis?.okData == false;
    final String title = notEnoughData ? 'Insufficient Data' : 'Data Unavailable';
    final String message = notEnoughData ? 'Need 7 full days of step history.' : 'Server issue. Try again later.';
    final IconData icon = notEnoughData ? Icons.calendar_today_rounded : Icons.gpp_bad_rounded;
    final Color color = Colors.white.withOpacity(0.7);

    return SizedBox(
      height: 300, 
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: color.withOpacity(0.6)),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(message, style: TextStyle(fontSize: 15, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildChartUI(BuildContext context, List<int> dailySteps) {
    final int recentSteps = dailySteps.last; 
    final double progress = (recentSteps / stepGoal).clamp(0.0, 1.0);
    final double maxWeeklySteps = (dailySteps.reduce(math.max) * 1.1);
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
        Row(children: [Icon(Icons.directions_run_rounded, color: darkYellow, size: 28), const SizedBox(width: 10), Text('Step Dashboard', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white))]),
        const SizedBox(height: 50),
        SizedBox(
          width: 200, height: 200,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: progress),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (context, animatedProgress, child) {
              return CustomPaint(
                painter: _StepRadialPainter(progress: animatedProgress, color: darkYellow, trackColor: progressTrackColor),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      Text('${recentSteps.toInt()}', style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.white)),
                      Text('/ ${stepGoal.toInt()} steps', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: lightTextColor)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: recentSteps >= stepGoal ? darkYellow.withOpacity(0.2) : Colors.transparent, borderRadius: BorderRadius.circular(12), border: Border.all(color: recentSteps >= stepGoal ? darkYellow : Colors.transparent, width: 1.5)),
                        child: Text(recentSteps >= stepGoal ? 'GOAL MET!' : 'Recent Day', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: recentSteps >= stepGoal ? darkYellow : lightTextColor)),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 30),
        const Divider(height: 40, color: Colors.white24, thickness: 1),
        Text('Weekly Review', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: lightTextColor)),
        const SizedBox(height: 20),
        SizedBox(
          height: 110, 
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: dailySteps.asMap().entries.map((entry) {
              return _buildVerticalBar(dayLabel: chartDays[entry.key], steps: entry.value, goal: stepGoal, maxSteps: maxWeeklySteps, color: darkYellow);
            }).toList(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StepAnalysis>(
      future: _stepAnalysisFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildDarkContainer(child: const SizedBox(height: 300, child: Center(child: CircularProgressIndicator(color: Color(0xFFFFA000), strokeWidth: 2.0))));
        }
        if (snapshot.hasError || (snapshot.hasData && !snapshot.data!.okData)) {
          return _buildDarkContainer(child: _buildDataNotAvailable(context, snapshot.data));
        }
        return _buildDarkContainer(child: _buildChartUI(context, snapshot.data!.steps));
      },
    );
  }
}

class _HealthSnapshotContent extends StatelessWidget {
  final HealthAnalysis analysis;
  const _HealthSnapshotContent({required this.analysis});

  String _formatValue(dynamic value, String unit) {
    if (value is num) return '${value.round()} $unit';
    else if (value != null) return '$value $unit';
    return 'N/A';
  }

  @override
  Widget build(BuildContext context) {
    final entries = [
      {'label': 'Avg. Calories', 'value': _formatValue(analysis.userProfile['Average Calories'], 'kcal')},
      {'label': 'Avg. Sugar', 'value': _formatValue(analysis.userProfile['Average Blood Sugar'], 'mg/dL')},
      {'label': 'Avg. Cholesterol', 'value': _formatValue(analysis.userProfile['Average Cholesterol'], 'mg/dL')},
      {'label': 'Avg. Fats', 'value': _formatValue(analysis.userProfile['Average Fats'], 'g')},
      {'label': 'Avg. Carbs', 'value': _formatValue(analysis.userProfile['Average Carbs'], 'g')},
      {'label': 'Avg. Protein', 'value': _formatValue(analysis.userProfile['Average Protein'], 'g')},
    ];
    final currentCondition = analysis.userProfile['Health Conditions'] != null ? analysis.userProfile['Health Conditions'].toString() : 'None Reported';

    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 30),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 30),
              const Text('Your Health Snapshot', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
              const SizedBox(height: 4),
              Text('Condition: ${currentCondition.isNotEmpty ? currentCondition : 'None Reported'}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 13), overflow: TextOverflow.ellipsis),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: Container(
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.3), width: 1)),
                padding: const EdgeInsets.all(12),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 1.5, crossAxisSpacing: 8, mainAxisSpacing: 8),
                  itemCount: 6, 
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(entry['value'] as String, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(entry['label'] as String, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w600)),
                    ]);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StaticHeader extends StatelessWidget {
  final HealthAnalysis analysis;
  const _StaticHeader({required this.analysis});
  static const double fixedHeight = 400.0;

  @override
  Widget build(BuildContext context) {
    const String imageUrl = 'https://images.unsplash.com/photo-1625937286074-9ca519d5d9df?ixlib=rb-4.1.0&auto=format&fit=crop&q=80&w=1332';

    return SliverToBoxAdapter(
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
        child: SizedBox(
          height: fixedHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover, errorWidget: (context, error, stackTrace) => Container(color: Theme.of(context).colorScheme.primary)),
              ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        colors: [Colors.black.withOpacity(0.3), Colors.black.withOpacity(0.1), Colors.black.withOpacity(0.0)],
                        stops: const [0.0, 0.4, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              Align(alignment: Alignment.bottomCenter, child: _HealthSnapshotContent(analysis: analysis)),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// --- Main Page Widget (Updated Scaffold & Build) ---
// ------------------------------------------------------------

class NutritionTipsPage extends StatefulWidget {
  const NutritionTipsPage({super.key});
  @override
  State<NutritionTipsPage> createState() => _NutritionTipsPageState();
}

class _NutritionTipsPageState extends State<NutritionTipsPage> {
  late Future<HealthAnalysis> _analysisFuture;
  final AuthService _authService = AuthService();
  // Mock user data for the request
  final Map<String, dynamic> _userData = {
    'averageCalories': 1000,
    'averageSugar': 120,
    'averageFats': 35,
    'averageCholesterol': 210,
    'averageCarbs': 250,
    'averageProtein': 50,
    'averageCaloriesBurned': 500,
    'currentHealthCondition': ["Hypertension"]
  };

  @override
  void initState() {
    super.initState();
    _analysisFuture = _fetchHealthAnalysis();
  }
  
  // Helper to clean API data
  Map<String, dynamic> _cleanProfileValues(Map<String, dynamic> rawJson) {
    final profile = rawJson['profile'] as Map<String, dynamic>?;
    if (profile == null) return rawJson;
    final keysToClean = ['Average Calories', 'Average Blood Sugar', 'Average Cholesterol', 'Average Fats', 'Average Carbs', 'Average Protein', 'Average Calories Burned'];
    for (var key in keysToClean) {
      var value = profile[key];
      if (value is String) {
        final numberMatch = RegExp(r"(\d+(\.\d+)?)").firstMatch(value);
        if (numberMatch != null) profile[key] = num.tryParse(numberMatch.group(0)!) ?? value;
      }
    }
    return rawJson;
  }

  Future<HealthAnalysis> _fetchHealthAnalysis() async {
    final String apiUrl = '$baseURL/api/generate-ai-content';

    final token = await _authService.getToken();
    if (token == null || token.isEmpty) throw Exception('Authentication required.');

    try {
      final response = await http.post(Uri.parse(apiUrl), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}, body: json.encode(_userData));
      if (response.statusCode == 200) {
        String responseBody = response.body;
        String aiJsonString;
        dynamic firstDecode;
        try { firstDecode = json.decode(responseBody); } catch (_) { firstDecode = responseBody; }

        if (firstDecode is String) {
          aiJsonString = firstDecode.trim().replaceAll('```json', '').replaceAll('```', '').trim();
          if (aiJsonString.startsWith('"') && aiJsonString.endsWith('"')) aiJsonString = aiJsonString.substring(1, aiJsonString.length - 1);
          if (!aiJsonString.startsWith('{')) throw Exception('Cleaned string is not valid JSON.');
          final Map<String, dynamic> aiJson = json.decode(aiJsonString);
          return HealthAnalysis.fromJson(_cleanProfileValues(aiJson));
        } else if (firstDecode is Map<String, dynamic>) {
          return HealthAnalysis.fromJson(_cleanProfileValues(firstDecode));
        } else {
          throw Exception('Unexpected AI response format.');
        }
      } else {
        throw Exception('Failed to generate health analysis. Status: ${response.statusCode}.');
      }
    } catch (e) {
      throw Exception('Could not fetch health analysis: ${e.toString()}');
    }
  }

  // --- UI Helpers ---
  Color _getRiskColor(Likelihood likelihood) {
    switch (likelihood) {
      case Likelihood.veryHigh: return Colors.red.shade700;
      case Likelihood.high: return Colors.orange.shade700;
      case Likelihood.medium: return Colors.amber.shade700;
      case Likelihood.low: default: return Colors.green.shade700;
    }
  }

  IconData _getRiskIcon(String risk) {
    switch (risk.toLowerCase()) {
      case 'hypertension': return Icons.monitor_heart_rounded;
      case 'diabetes': return Icons.bloodtype_rounded;
      case 'obesity': return Icons.monitor_weight_rounded;
      case 'high cholesterol': return Icons.spa_rounded;
      case 'heart disease': return Icons.favorite_rounded;
      case 'arthritis': return Icons.accessible_forward_rounded;
      case 'asthma': return Icons.air_rounded;
      default: return Icons.health_and_safety_rounded;
    }
  }

  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 16, left: 20, right: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(width: 12),
          Expanded(child: Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey[800]), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildRiskPredictionGrid(HealthAnalysis analysis) {
    final highRisks = analysis.healthRisks.entries.where((e) => e.value.index >= Likelihood.high.index).toList()..sort((a, b) => b.value.index.compareTo(a.value.index));
    const int initialStaggerIndex = 3;

    if (highRisks.isEmpty) {
      return StaggeredAnimation(
        index: initialStaggerIndex,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 0, bottom: 0),
          child: _InteractiveCard(
            padding: const EdgeInsets.all(20),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.thumb_up_alt_rounded, color: Colors.green.shade700, size: 30), const SizedBox(width: 12), Expanded(child: Text('Great job! No immediate high health risks detected based on your current data.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700, fontSize: 16)))]),
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
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.1),
            itemCount: highRisks.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final risk = highRisks[index];
              final riskColor = _getRiskColor(risk.value);
              final levelText = risk.value.toString().split('.').last.toUpperCase();
              return StaggeredAnimation(
                index: index + initialStaggerIndex,
                child: _InteractiveCard(
                  isWarning: true,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: riskColor.withOpacity(0.1), shape: BoxShape.circle, border: Border.all(color: riskColor.withOpacity(0.5), width: 1)), child: Icon(_getRiskIcon(risk.key), size: 36, color: riskColor)),
                      const SizedBox(height: 12),
                      Expanded(child: Text(risk.key, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF333333)))),
                      const SizedBox(height: 4),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: riskColor.withOpacity(0.85), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: riskColor.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))]), child: Text(levelText, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5))),
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
    final warnings = analysis.consumptionWarnings.entries.where((e) => e.value.index >= Likelihood.high.index).toList()..sort((a, b) => b.value.index.compareTo(a.value.index));
    if (warnings.isEmpty) return const SizedBox.shrink();

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
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('CRITICAL ${_capitalize(warning.key)} Intake', style: TextStyle(fontWeight: FontWeight.bold, color: warningColor, fontSize: 16)), const SizedBox(height: 4), Text('Your average intake is at a "${level.replaceAll('_', ' ')}" level. Immediate action is required.', style: TextStyle(color: Colors.grey[700], fontSize: 13))])),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: warningColor.withOpacity(0.25), borderRadius: BorderRadius.circular(20)), child: Text(level.toUpperCase(), style: TextStyle(color: warningColor, fontWeight: FontWeight.bold, fontSize: 12))),
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
                        Column(children: [Container(width: 32, height: 32, decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle, boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.4), blurRadius: 5, offset: const Offset(0, 2))]), child: Center(child: Text((index + 1).toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)))), if (!isLast) Expanded(child: Container(width: 2, margin: const EdgeInsets.symmetric(vertical: 4), decoration: BoxDecoration(color: primaryColor.withOpacity(0.4), borderRadius: BorderRadius.circular(1))))]),
                        const SizedBox(width: 16),
                        Expanded(child: Padding(padding: EdgeInsets.only(bottom: isLast ? 0 : 20.0, top: 4), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("STEP ${index + 1}", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: primaryColor)), const SizedBox(height: 4), Text(recommendation, style: TextStyle(fontSize: 16, color: Colors.grey[800], height: 1.4, fontWeight: FontWeight.w500))]))),
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

  // --- NEW: Dedicated Error View with Retry ---
  Widget _buildError(BuildContext context, String errorDetails) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sentiment_dissatisfied_rounded, size: 74, color: Theme.of(context).colorScheme.primary,),
            const SizedBox(height: 20),
            Text(
              "Analysis Failed",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: darkText),
            ),
            const SizedBox(height: 10),
            const Text(
              "Feature isn't available, Server issue. Please try again later.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF636E72), fontSize: 16, height: 1.4),
            ),
            const SizedBox(height: 40),
            InkWell(
              onTap: () {
                // Retry logic
                setState(() {
                  _analysisFuture = _fetchHealthAnalysis();
                });
              },
              borderRadius: BorderRadius.circular(50),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 15),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: const Text(
                  "TRY AGAIN",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<HealthAnalysis>(
      future: _analysisFuture,
      builder: (context, snapshot) {
        // Logic: Show AppBar if Loading OR Error
        final bool showAppBar = snapshot.connectionState == ConnectionState.waiting || snapshot.hasError;

        return Scaffold(
          extendBodyBehindAppBar: true,
          // Conditional AppBar
          appBar: showAppBar
              ? AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  centerTitle: true,
                  title: Text(
                    "Nutrition Tips", 
                    style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 22)
                  ),
                  leading: IconButton(
                    icon:  Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).colorScheme.primary,),
                    onPressed: () => Navigator.pop(context),
                  ),
                )
              : null, // No AppBar when loaded
          body: Stack(
            children: [
              // Animated Background
              const _LivingAnimatedBackground(),
              // White Tint
              Container(color: Colors.white.withOpacity(0.3)),
              // Body Content
              if (snapshot.connectionState == ConnectionState.waiting)
                const SafeArea(child: CreativeHealthLoader())
              else if (snapshot.hasError)
                SafeArea(child: _buildError(context, snapshot.error.toString()))
              else if (snapshot.hasData)
                CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _StaticHeader(analysis: snapshot.data!),
                    SliverList(
                      delegate: SliverChildListDelegate([
                        const SizedBox(height: 10),
                        const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: _MealPlanCard()),
                        const SizedBox(height: 30),
                        const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: DailyStepsChartCard()),
                        const SizedBox(height: 30),
                        _buildSectionHeader(context, 'Health Risk Prediction', Icons.psychology),
                        _buildRiskPredictionGrid(snapshot.data!),
                        const SizedBox(height: 30),
                        _buildSectionHeader(context, 'Action Plan', Icons.list_alt_rounded),
                        _buildRecommendations(snapshot.data!),
                        const SizedBox(height: 40),
                        if (snapshot.data!.consumptionWarnings.entries.where((e) => e.value.index >= Likelihood.high.index).isNotEmpty)
                          Column(children: [
                            _buildSectionHeader(context, 'Critical Intake Warnings', Icons.local_fire_department_rounded),
                            _buildConsumptionWarnings(snapshot.data!),
                            const SizedBox(height: 40)
                          ]),
                      ]),
                    ),
                  ],
                )
            ],
          ),
        );
      },
    );
  }
}

class _MealPlanCard extends StatelessWidget {
  const _MealPlanCard();
  int _getCurrentDayOfWeek() => DateTime.now().weekday;

  @override
  Widget build(BuildContext context) {
    const String imageUrl = 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1780&q=80';
    final cardColor = Colors.teal;
    final currentDay = _getCurrentDayOfWeek();

    return SizedBox(
        height: 200,
        child: StaggeredAnimation(
            index: 1,
            child: _InteractiveCard(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const UserMealPlanScreen())),
                child: Stack(fit: StackFit.expand, children: [
                  ClipRRect(borderRadius: BorderRadius.circular(24.0), child: CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover, color: cardColor.withOpacity(0.5), colorBlendMode: BlendMode.colorBurn, errorWidget: (context, error, stackTrace) => Container(color: cardColor.shade400))),
                  ClipRRect(borderRadius: BorderRadius.circular(24.0), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0), child: Container(decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), border: Border.all(color: Colors.white.withOpacity(0.5)), borderRadius: BorderRadius.circular(24.0)), padding: const EdgeInsets.all(24.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start, children: [const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Weekly Nutrition', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)), SizedBox(height: 4), Text('Get On Track!', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 0.5))]), _PlanProgressIndicator(plannedDays: currentDay)]), const _MealPlanCtaChip(accentColor: Colors.white)]))))
                ]))));
  }
}

class _PlanProgressIndicator extends StatelessWidget {
  final int plannedDays;
  final int totalDays;
  const _PlanProgressIndicator({this.totalDays = 7, required this.plannedDays});
  double get progress => plannedDays / totalDays;
  @override
  Widget build(BuildContext context) => SizedBox(width: 50, height: 50, child: Stack(alignment: Alignment.center, children: [SizedBox(width: 50, height: 50, child: CircularProgressIndicator(value: progress, strokeWidth: 4, backgroundColor: Colors.white.withOpacity(0.2), valueColor: const AlwaysStoppedAnimation<Color>(Colors.white))), Text('$plannedDays/$totalDays', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))]));
}

class _MealPlanCtaChip extends StatelessWidget {
  final Color accentColor;
  const _MealPlanCtaChip({required this.accentColor});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, spreadRadius: 1)]), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.fastfood_rounded, color: Colors.teal.shade700, size: 20), const SizedBox(width: 8), Text('Explore Your Week', style: TextStyle(color: Colors.teal.shade700, fontWeight: FontWeight.bold, fontSize: 15))]));
}

// --- ANIMATED BACKGROUND ---
class _LivingAnimatedBackground extends StatefulWidget {
  const _LivingAnimatedBackground();
  @override
  State<_LivingAnimatedBackground> createState() => _LivingAnimatedBackgroundState();
}

class _LivingAnimatedBackgroundState extends State<_LivingAnimatedBackground> with TickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(seconds: 40))..repeat(reverse: true); }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: _c, builder: (ctx, _) => Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color.lerp(const Color(0xffa8edea), const Color(0xfffed6e3), _c.value)!, Color.lerp(const Color(0xfffed6e3), const Color(0xffa8edea), _c.value)!]))));
}