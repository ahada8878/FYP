// lib/screens/progress_screen.dart

import 'package:flutter/material.dart';
import 'dart:ui'; // Used for ImageFilter.blur
import 'dart:math' as math; // For math functions like clamp
import 'package:confetti/confetti.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// --- INTERNAL IMPORTS ---
import 'package:fyp/screens/settings_screen.dart';
import 'package:fyp/models/progress_data.dart';
import 'package:fyp/services/config_service.dart'; // Ensure baseURL is defined here or globally
import 'package:fyp/services/progress_service.dart';
import 'package:fyp/services/food_log_service.dart'; 
import 'package:fyp/screens/Features/nutritrack_page.dart'; 
import 'package:fyp/Widgets/weekly_report_sheet.dart'; 
import 'package:fyp/screens/activity_history_screen.dart'; 

class MyProgressScreen extends StatefulWidget {
  const MyProgressScreen({super.key});
  @override
  State<MyProgressScreen> createState() => _MyProgressScreenState();
}

class _MyProgressScreenState extends State<MyProgressScreen> with TickerProviderStateMixin {
  late Future<ProgressData> _progressDataFuture;

  // --- SERVICES ---
  final RealProgressService _dataService = RealProgressService();
  final FoodLogService _foodLogService = FoodLogService();

  // --- ANIMATIONS & CONTROLLERS ---
  late AnimationController _headerAnimController;
  late ConfettiController _confettiController;
  bool _isGeneratingReport = false; 

  // --- ACTIVITY OPTIONS (For Friend's Logic) ---
  final List<Map<String, dynamic>> _activities = [
    {"name": "Running", "icon": Icons.directions_run, "color": Colors.orange},
    {"name": "Cycling", "icon": Icons.directions_bike, "color": Colors.blue},
    {"name": "Walking", "icon": Icons.directions_walk, "color": Colors.green},
    {"name": "Swimming", "icon": Icons.pool, "color": Colors.cyan},
    {"name": "Yoga", "icon": Icons.self_improvement, "color": Colors.purple},
    {"name": "HIIT", "icon": Icons.flash_on, "color": Colors.red},
    {"name": "Strength", "icon": Icons.fitness_center, "color": Colors.blueGrey},
    {"name": "Jump Rope", "icon": Icons.compare_arrows, "color": Colors.deepOrange},
  ];

  @override
  void initState() {
    super.initState();
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
      _progressDataFuture = _dataService.fetchData();
      _headerAnimController.forward(from: 0.0);
    });
  }

  // ------------------------------------------------------------------------
  // ✅ FRIEND'S LOGIC: Activity Logging Integration
  // ------------------------------------------------------------------------

  void _openActivityDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _ActivitySelectionDialog(
        activities: _activities,
        onActivitySelected: (activityName) {
          Navigator.pop(ctx); 
          _openDurationDialog(activityName);
        },
      ),
    );
  }

  void _openDurationDialog(String activityName) {
    showDialog(
      context: context,
      builder: (ctx) => _DurationSelectionDialog(
        activityName: activityName,
        onDurationConfirmed: (minutes) {
          Navigator.pop(ctx);
          _submitActivityLog(activityName, minutes);
        },
      ),
    );
  }

  Future<void> _submitActivityLog(String activityName, int minutes) async {
    // 1. Show immediate visual feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Logging $activityName for $minutes mins..."), duration: const Duration(seconds: 1)),
    );

    try {
      // 2. Prepare API Call
      // NOTE: Ensure 'baseURL' is exported from config_service.dart or defined globally.
      const String apiUrl = "$baseURL/api/activities/log"; 
      
      final prefs = await SharedPreferences.getInstance();
      
      // Robust Token Check
      String? token = prefs.getString('token') ?? prefs.getString('auth_token') ?? prefs.getString('userToken');

      if (token == null) throw Exception("User not authenticated. Please Log In again.");

      // 3. Send Data
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "activityName": activityName,
          "duration": minutes,
          "date": DateTime.now().toIso8601String(),
        }),
      );

      // 4. Handle Response
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final calories = data['data']['caloriesBurned'] ?? 0;
        
        if (!mounted) return;
        
        // Success Animation
        _confettiController.play();
        
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Column(
              children: [
                Icon(Icons.local_fire_department, color: Colors.orange, size: 40),
                SizedBox(height: 10),
                Text("Great Job!", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: Text(
              "You burned approximately $calories calories.",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Awesome"),
              )
            ],
          ),
        );
        
        _refreshData(); // Update the dashboard
      } else {
        throw Exception("Failed: ${response.body}");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  // ------------------------------------------------------------------------
  // EXISTING FEATURES: Weight Log & Reports
  // ------------------------------------------------------------------------

  Future<void> _generateWeeklyReport() async {
    setState(() => _isGeneratingReport = true);
    try {
      final weeklyLogs = await _foodLogService.fetchLastSevenDaysLogs();
      final isComplete = _foodLogService.isWeeklyLogComplete(weeklyLogs);

      if (!mounted) return;

      if (!isComplete) {
        setState(() => _isGeneratingReport = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const NutriTrackPage(
              initialMessage: "Log all weekly meals to generate report",
            ),
          ),
        );
      } else {
        final reportData = await _foodLogService.fetchWeeklyReport();
        if (!mounted) return;
        setState(() => _isGeneratingReport = false);
        _showReportSheet(context, reportData);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGeneratingReport = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Report generation failed: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showReportSheet(BuildContext context, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: WeeklyReportSheet(data: data, scrollController: controller),
        ),
      ),
    );
  }

  void _showLogWeightSheet(BuildContext context, double currentWeight) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _LogWeightSheet(
        initialWeight: currentWeight,
        onLog: (newWeight) async {
          Navigator.of(ctx).pop();
          try {
            await _dataService.logWeight(newWeight);
            HapticFeedback.mediumImpact();
            _confettiController.play();
            _refreshData();
          } catch (e) {
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

  // ------------------------------------------------------------------------
  // MAIN UI BUILD
  // ------------------------------------------------------------------------

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
          final double userHeightInMeters = data.height * 0.3048; 
          final double bmi = data.currentWeight / (userHeightInMeters * userHeightInMeters);

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
                          _buildReportButton(context), 
                          const SizedBox(height: 16),
                          
                          _buildSectionHeader(context, "Your Story So Far"),
                          _buildTimelineSection(data),
                          const SizedBox(height: 24),
                          
                          _buildSectionHeader(context, "Health Overview"),
                          _HealthSnapshotSection(
                            bmi: bmi,
                            heightInMeters: userHeightInMeters,
                            currentWeight: data.currentWeight,
                            targetWeight: data.targetWeight,
                            startWeight: data.startWeight,
                            animation: _headerAnimController,
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // ✅ ACTIVITY LOG CARD
                          _LogActivityCard(
                            animationIndex: 6,
                            onTap: _openActivityDialog,
                          ),
                          
                          const SizedBox(height: 24),
                          _buildSectionHeader(context, "Weekly Snapshots"),
                          
                          _CombinedTrendCard(
                            weightData: data.weeklyWeightData,
                            stepsData: data.weeklyStepsData,
                            stepGoal: data.stepGoal,
                          ),

                          const SizedBox(height: 24),
                          _ActivityHistoryCallToAction(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ActivityHistoryScreen()),
                              );
                            },
                          ),
                          const SizedBox(height: 40), 

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
      floatingActionButton: FutureBuilder<ProgressData>(
        future: _progressDataFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: () => _showLogWeightSheet(context, snapshot.data!.currentWeight),
            icon: const Icon(Icons.add_rounded),
            label: const Text("Log Weight"),
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          );
        }
      ),
    );
  }

  // --- UI HELPER WIDGETS ---

  Widget _buildReportButton(BuildContext context) {
    return StaggeredAnimation(
      index: 0,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isGeneratingReport ? null : _generateWeeklyReport,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.orange,
            elevation: 2,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.orange.withOpacity(0.5), width: 1),
            ),
          ),
          icon: _isGeneratingReport 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange))
            : const Icon(Icons.auto_awesome_outlined),
          label: Text(
            _isGeneratingReport ? "Analyzing with AI..." : "Generate Weekly Report",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  SliverAppBar _buildHeaderSliver(ProgressData data) {
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
    return StaggeredAnimation(index: 0, child: Padding(padding: const EdgeInsets.only(bottom: 16, top: 8), child: Center(
      child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey[800]))),
    ));
  }

  Widget _buildTimelineSection(ProgressData data) {
    final bool isWeightGainGoal = data.targetWeight > data.startWeight;
    final double weightChange = data.currentWeight - data.startWeight;

    List<Widget> children = [
      StaggeredAnimation(index: 1, child: _TimelineEventCard(
        icon: Icons.scale, color: Theme.of(context).colorScheme.primary, title: "Today's Weight",
        subtitle: "You're doing great!", value: "${data.currentWeight.toStringAsFixed(1)} kg", isFirst: true)),
      
      if (data.steps > 0)
        StaggeredAnimation(index: 2, child: _TimelineEventCard(
          icon: Icons.directions_walk, color: Colors.purple, title: "Today's Steps",
          subtitle: "${(data.steps / data.stepGoal * 100).toStringAsFixed(0)}% of your goal", value: "${data.steps}")),
    ];

    if (isWeightGainGoal && weightChange > 0) {
      children.add(StaggeredAnimation(index: 3, child: _TimelineEventCard(
        icon: Icons.trending_up, color: Colors.green, title: "Total Weight Gained",
        subtitle: "An amazing accomplishment!", value: "${weightChange.abs().toStringAsFixed(1)} kg")));
    } else if (!isWeightGainGoal && weightChange < 0) {
      children.add(StaggeredAnimation(index: 3, child: _TimelineEventCard(
        icon: Icons.trending_down, color: Colors.orange, title: "Total Weight Lost",
        subtitle: "An amazing accomplishment!", value: "${weightChange.abs().toStringAsFixed(1)} kg")));
    }

    children.add(StaggeredAnimation(index: 4, child: _TimelineEventCard(
      icon: Icons.rocket_launch, color: Colors.grey.shade600, title: "Journey Started",
      subtitle: "The first step is always the hardest.", value: "${data.startWeight.toStringAsFixed(1)} kg", isLast: true)));

    return Column(children: children);
  }
}

// ------------------------------------------------------------------------
// SUB-WIDGETS & DIALOGS
// ------------------------------------------------------------------------

class _LogActivityCard extends StatelessWidget {
  final VoidCallback onTap; 
  final int animationIndex;
  const _LogActivityCard({required this.onTap, required this.animationIndex});

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
            gradient: const LinearGradient(
              colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)], 
              begin: Alignment.topLeft, 
              end: Alignment.bottomRight
            )
          ), 
          child: Padding(
            padding: const EdgeInsets.all(20.0), 
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.fitness_center, size: 30, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    children: [
                      const Text(
                        "Log Activity", 
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                      ), 
                      const SizedBox(height: 4), 
                      Text(
                        "Track workouts & burn calories.", 
                        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14)
                      )
                    ]
                  )
                ),
                const SizedBox(width: 16), 
                const Icon(Icons.add_circle_outline, color: Colors.white, size: 28),
              ]
            )
          )
        )
      )
    );
  }
}

class _ActivitySelectionDialog extends StatelessWidget {
  final List<Map<String, dynamic>> activities;
  final Function(String) onActivitySelected;
  const _ActivitySelectionDialog({required this.activities, required this.onActivitySelected});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))]),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 28),
                const SizedBox(width: 12),
                Expanded(child: Text("What did you do?", style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey[800]))),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close), color: Colors.grey)
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 350,
              child: GridView.builder(
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.1, crossAxisSpacing: 16, mainAxisSpacing: 16),
                itemCount: activities.length,
                itemBuilder: (context, index) {
                  final activity = activities[index];
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onActivitySelected(activity['name']),
                      borderRadius: BorderRadius.circular(20),
                      splashColor: activity['color'].withOpacity(0.1),
                      child: Container(
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))]),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: activity['color'].withOpacity(0.1), shape: BoxShape.circle), child: Icon(activity['icon'], size: 32, color: activity['color'])),
                            const SizedBox(height: 12),
                            Text(activity['name'], style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800], fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DurationSelectionDialog extends StatefulWidget {
  final String activityName;
  final Function(int) onDurationConfirmed;
  const _DurationSelectionDialog({required this.activityName, required this.onDurationConfirmed});
  @override
  State<_DurationSelectionDialog> createState() => _DurationSelectionDialogState();
}

class _DurationSelectionDialogState extends State<_DurationSelectionDialog> {
  int _selectedMinutes = 30;
  final List<int> _quickOptions = [10, 20, 30, 45, 60, 90, 120];

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))]),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("How long?", style: TextStyle(color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text(widget.activityName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.grey[800])),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text("$_selectedMinutes", style: TextStyle(fontSize: 64, fontWeight: FontWeight.w900, color: primaryColor)),
                const SizedBox(width: 8),
                Text("min", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[500])),
              ],
            ),
            const SizedBox(height: 24),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(activeTrackColor: primaryColor, inactiveTrackColor: primaryColor.withOpacity(0.2), thumbColor: primaryColor, overlayColor: primaryColor.withOpacity(0.1), trackHeight: 6, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12)),
              child: Slider(value: _selectedMinutes.toDouble(), min: 5, max: 180, divisions: 35, onChanged: (val) => setState(() => _selectedMinutes = val.toInt())),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Wrap(
                alignment: WrapAlignment.center, spacing: 10, runSpacing: 10,
                children: _quickOptions.map((e) {
                  final isSelected = _selectedMinutes == e;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedMinutes = e),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: isSelected ? primaryColor : Colors.grey[100], borderRadius: BorderRadius.circular(20), border: Border.all(color: isSelected ? primaryColor : Colors.transparent)),
                      child: Text("$e m", style: TextStyle(color: isSelected ? Colors.white : Colors.grey[700], fontWeight: FontWeight.bold)),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: TextButton(onPressed: () => Navigator.pop(context), style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), foregroundColor: Colors.grey[600]), child: const Text("Cancel"))),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: ElevatedButton(onPressed: () => widget.onDurationConfirmed(_selectedMinutes), style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: const Text("Log Activity", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)))),
            ]),
          ],
        ),
      ),
    );
  }
}

class _CombinedTrendCard extends StatelessWidget {
  final List<double> weightData; 
  final List<int> stepsData;
  final int stepGoal;
  
  const _CombinedTrendCard({
    required this.weightData, 
    required this.stepsData, 
    required this.stepGoal
  });

  @override
  Widget build(BuildContext context) {
    return StaggeredAnimation(
      index: 7,
      child: _InteractiveCard(
        padding: const EdgeInsets.all(0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _StepsTrendVisualization(
            data: stepsData, 
            goal: stepGoal
          ),
        ),
      ),
    );
  }
}

class _ActivityHistoryCallToAction extends StatelessWidget {
  final VoidCallback onTap;
  const _ActivityHistoryCallToAction({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return StaggeredAnimation(
      index: 8,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.history_edu_rounded, color: Colors.orange, size: 28),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Check Activity History",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "See your past workouts & stats.",
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// --- VISUALIZATION HELPERS ---

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
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
            Icon(Icons.directions_walk_rounded, color: primaryColor, size: 20),
            const SizedBox(width: 8), const Text("Steps Activity (Weekly)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 16),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: 70, height: 70, child: _CircularGoalIndicator(progress: progress, value: average, unit: 'Avg Steps', color: primaryColor, labelSize: 10)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Daily Average:", style: TextStyle(fontSize: 14, color: Colors.grey[600])), Text(average.toString(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: primaryColor)), Text("Goal: $goal steps", style: TextStyle(color: Colors.grey[700], fontSize: 14))])),
        ]),
        const SizedBox(height: 16),
        SizedBox(height: 100, child: _StepsBarChart(data: data, goal: goal)),
    ]);
  }
}

class _CircularGoalIndicator extends StatelessWidget {
  final double progress; final int value; final String unit; final Color color; final double labelSize;
  const _CircularGoalIndicator({required this.progress, required this.value, required this.unit, required this.color, this.labelSize = 10});
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: progress), duration: const Duration(milliseconds: 1000), curve: Curves.easeOutCubic,
      builder: (context, animProgress, child) {
        return CustomPaint(painter: _ProgressRingPainter(progress: animProgress, progressColor: color, backgroundColor: color.withOpacity(0.2)), child: Center(child: Text("${(animProgress * 100).toStringAsFixed(0)}%", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color))));
      },
    );
  }
}

class _StepsBarChart extends StatelessWidget {
  final List<int> data; final int goal;
  const _StepsBarChart({required this.data, required this.goal});
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(tween: Tween<double>(begin: 0, end: 1), duration: const Duration(milliseconds: 800), curve: Curves.easeOutCubic, builder: (context, value, child) => CustomPaint(size: Size.infinite, painter: _StepsBarPainter(data: data, goal: goal, animationProgress: value, primaryColor: Colors.orange)));
  }
}

class _StepsBarPainter extends CustomPainter {
  final List<int> data; final int goal; final double animationProgress; final Color primaryColor;
  _StepsBarPainter({required this.data, required this.goal, required this.animationProgress, required this.primaryColor});
  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    const double labelHeight = 20; final double chartHeight = size.height - labelHeight;
    final double maxVal = (data.isNotEmpty ? (data.reduce(math.max) > goal ? data.reduce(math.max) : goal) : goal) * 1.2;
    if (maxVal == 0) return;
    final double barWidth = size.width / (data.length * 2 - 1);
    for (int i = 0; i < data.length; i++) {
      final barHeight = (data[i] / maxVal * chartHeight) * animationProgress;
      final left = i * barWidth * 2;
      final rect = Rect.fromLTWH(left, chartHeight - barHeight, barWidth, barHeight);
      final didMeetGoal = data[i] >= goal;
      final paint = Paint()..shader = LinearGradient(colors: didMeetGoal ? [primaryColor, primaryColor.withOpacity(0.7)] : [Colors.grey.shade300, Colors.grey.shade400], begin: Alignment.bottomCenter, end: Alignment.topCenter).createShader(rect);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), paint);
    }
  }
  @override
  bool shouldRepaint(covariant _StepsBarPainter oldDelegate) => oldDelegate.animationProgress != animationProgress;
}

class _TimelineEventCard extends StatelessWidget {
  final IconData icon; final Color color; final String title; final String subtitle; final String value; final bool isFirst; final bool isLast;
  const _TimelineEventCard({ required this.icon, required this.color, required this.title, required this.subtitle, required this.value, this.isFirst = false, this.isLast = false});
  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SizedBox(width: 50, child: CustomPaint(painter: _TimelinePainter(isFirst: isFirst, isLast: isLast), child: Center(child: Container(width: 36, height: 36, decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.2)), child: Icon(icon, color: color, size: 20))))),
      const SizedBox(width: 8),
      Expanded(child: _InteractiveCard(padding: const EdgeInsets.all(16), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 4), Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 14))])), const SizedBox(width: 16), Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: color))]))),
    ]));
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
  final double bmi; final double heightInMeters; final double currentWeight; final double startWeight; final double targetWeight; final Animation<double> animation;
  const _HealthSnapshotSection({ required this.bmi, required this.heightInMeters, required this.currentWeight, required this.targetWeight, required this.startWeight, required this.animation });
  @override
  Widget build(BuildContext context) {
    return StaggeredAnimation(index: 5, child: Column(children: [_WeightToGoCard(currentWeight: currentWeight, targetWeight: targetWeight, animation: animation, startWeight: startWeight), const SizedBox(height: 1), Row(children: [Expanded(child: _BmiStatusCard(bmi: bmi)), const SizedBox(width: 16), Expanded(child: _HealthyRangeCard(heightInMeters: heightInMeters))])]));
  }
}

class _WeightToGoCard extends StatelessWidget {
  final double currentWeight; final double startWeight; final double targetWeight; final Animation<double> animation;
  const _WeightToGoCard({ required this.currentWeight, required this.targetWeight, required this.animation, required this.startWeight });
  @override
  Widget build(BuildContext context) {
    final bool isWeightGainGoal = targetWeight > startWeight;
    final double totalGoalChange = (targetWeight - startWeight).abs();
    final double differenceToGoal = isWeightGainGoal ? targetWeight - currentWeight : currentWeight - targetWeight;
    final double weightRemaining = math.max(0.0, differenceToGoal);
    final double achievedChange = totalGoalChange - weightRemaining;
    final double progress = (totalGoalChange == 0 || totalGoalChange.isNaN) ? 1.0 : (achievedChange / totalGoalChange).clamp(0.0, 1.0);
    return _InteractiveCard(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(isWeightGainGoal ? "WEIGHT TO GAIN" : "WEIGHT TO GO", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)), const SizedBox(height: 1), Text.rich(TextSpan(text: weightRemaining.toStringAsFixed(1), style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.black), children: const <TextSpan>[TextSpan(text: ' kg', style: TextStyle(fontSize: 20, fontWeight: FontWeight.normal, color: Colors.black))])), const SizedBox(height: 4), Text(progress >= 1.0 ? "Goal achieved!" : "You're so close!")])), SizedBox(width: 80, height: 80, child: AnimatedBuilder(animation: animation, builder: (context, child) { final animValue = CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic).value; return CustomPaint(painter: _ProgressRingPainter(progress: progress * animValue, progressColor: Colors.orange, backgroundColor: Colors.grey.withOpacity(0.2)), child: Center(child: Text("${(progress * 100 * animValue).toStringAsFixed(0)}%", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)))); }))]));
  }
}

class _BmiStatusCard extends StatelessWidget {
  final double bmi;
  const _BmiStatusCard({required this.bmi});
  @override
  Widget build(BuildContext context) {
    String getBmiCategory() { if (bmi.isNaN || bmi < 18.5) return "Underweight"; if (bmi < 25) return "Healthy"; if (bmi < 30) return "Overweight"; return "Obese"; }
    Color getBmiCategoryColor() { final cat = getBmiCategory(); if (cat == "Underweight") return Colors.blue; if (cat == "Healthy") return Colors.green; if (cat == "Overweight") return Colors.orange; return Colors.red; }
    return _InteractiveCard(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const Text("BMI", style: TextStyle(fontWeight: FontWeight.bold)), const Spacer(), Icon(Icons.info, color: getBmiCategoryColor(), size: 20)]), const SizedBox(height: 8), Text(bmi.isNaN ? "---" : bmi.toStringAsFixed(1), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)), Text(getBmiCategory(), style: TextStyle(color: getBmiCategoryColor(), fontWeight: FontWeight.bold))]));
  }
}

class _HealthyRangeCard extends StatelessWidget {
  final double heightInMeters;
  const _HealthyRangeCard({required this.heightInMeters});
  @override
  Widget build(BuildContext context) {
    final double lowerWeight = 18.5 * (heightInMeters * heightInMeters);
    final double upperWeight = 24.9 * (heightInMeters * heightInMeters);
    return _InteractiveCard(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Row(children: [Text("Healthy Range", style: TextStyle(fontWeight: FontWeight.bold)), Spacer(), Icon(Icons.shield_outlined, color: Colors.green, size: 20)]), const SizedBox(height: 8), Text("${lowerWeight.toStringAsFixed(1)}-${upperWeight.toStringAsFixed(1)}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), const Text("Target (kg)", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))]));
  }
}

class _PremiumProgressHeader extends StatelessWidget {
  final double startWeight; final double currentWeight; final double targetWeight; final Animation<double> animation;
  const _PremiumProgressHeader({ required this.startWeight, required this.currentWeight, required this.targetWeight, required this.animation });
  @override
  Widget build(BuildContext context) {
    final bool isWeightGainGoal = targetWeight > startWeight;
    final double totalLossGoal = (startWeight - targetWeight);
    final double lossSoFar = (startWeight - currentWeight);
    final double progress = (totalLossGoal == 0 || totalLossGoal.isNaN) ? 1.0 : (lossSoFar / totalLossGoal).clamp(0.0, 1.0);
    final double changeSoFar = (currentWeight - startWeight);
    final double weightRemainingToGoal = isWeightGainGoal ? math.max(0.0, targetWeight - currentWeight) : math.max(0.0, currentWeight - targetWeight);
    return ClipRRect(borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)), child: Stack(fit: StackFit.expand, children: [
      const _BlurredImageBackground(imageUrl: 'https://images.unsplash.com/photo-1551632811-561732d1e306?q=80&w=2940'),
      BackdropFilter(filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0), child: Container(color: Colors.black.withOpacity(0.2))),
      SafeArea(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0), child: Column(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.start, children: [
        AnimatedBuilder(animation: animation, builder: (context, child) => Opacity(opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn).value, child: Text("Your Journey Progress", style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)))),
        const SizedBox(height: 8), Text("Keep striving!", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16)),
        const SizedBox(height: 32),
        AnimatedBuilder(animation: animation, builder: (context, child) { final animValue = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic).value; return _SleekProgressBar(progress: progress * animValue, startValue: startWeight, currentValue: currentWeight, targetValue: targetWeight); }),
        const SizedBox(height: 24),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_buildStatColumn("Start", "${startWeight.toStringAsFixed(1)} kg"), _buildStatColumn("Current", "${currentWeight.toStringAsFixed(1)} kg"), _buildStatColumn(isWeightGainGoal ? "Gained" : "Lost", "${changeSoFar.abs().toStringAsFixed(1)} kg"), _buildStatColumn("To Go", "${weightRemainingToGoal.toStringAsFixed(1)} kg")])
      ])))
    ]));
  }
  Widget _buildStatColumn(String label, String value) { return Expanded(child: Column(children: [Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)), const SizedBox(height: 4), Text(value, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))])); }
}

class _BlurredImageBackground extends StatelessWidget {
  final String imageUrl;
  const _BlurredImageBackground({required this.imageUrl});
  @override
  Widget build(BuildContext context) { return Image.network(imageUrl, fit: BoxFit.cover, color: Colors.grey.shade900.withOpacity(0.3), colorBlendMode: BlendMode.darken, errorBuilder: (context, error, stackTrace) => Container(color: Colors.blueGrey)); }
}

class _SleekProgressBar extends StatelessWidget {
  final double progress; final double startValue; final double currentValue; final double targetValue;
  const _SleekProgressBar({ required this.progress, required this.startValue, required this.currentValue, required this.targetValue });
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final double width = constraints.maxWidth;
      final double currentMarkerLeft = (width * progress).clamp(0.0, width); 
      return Column(children: [Stack(clipBehavior: Clip.none, children: [Container(height: 8, decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(10))), AnimatedContainer(duration: const Duration(milliseconds: 600), curve: Curves.easeOutCubic, width: width * progress, height: 8, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF8BC34A), Color(0xFF4CAF50)]), borderRadius: BorderRadius.circular(10))), Positioned(left: currentMarkerLeft - 8, top: -4, child: Container(width: 16, height: 16, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, border: Border.all(color: Colors.green, width: 3))))]), const SizedBox(height: 8), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('${startValue.toStringAsFixed(0)} kg', style: const TextStyle(color: Colors.white70, fontSize: 12)), Text('${targetValue.toStringAsFixed(0)} kg', style: const TextStyle(color: Colors.white70, fontSize: 12))])]);
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
    return BackdropFilter(filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0), child: Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom), child: Container(padding: const EdgeInsets.all(24.0), decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0))), child: Column(mainAxisSize: MainAxisSize.min, children: [Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))), const SizedBox(height: 16), Text('Log Your Weight', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)), const SizedBox(height: 24), Text.rich(TextSpan(text: _selectedWeight.toStringAsFixed(1), style: Theme.of(context).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.primary), children: <TextSpan>[TextSpan(text: ' kg', style: TextStyle(fontSize: 20, fontWeight: FontWeight.normal, color: Colors.grey[800]))])), Slider(value: _selectedWeight, min: 40, max: 150, divisions: 1100, onChanged: (value) => setState(() => _selectedWeight = value)), const SizedBox(height: 24), ElevatedButton(onPressed: () => widget.onLog(_selectedWeight), style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.orange, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Confirm & Log', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))]))));
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
  void initState() { super.initState(); _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 200)); _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut)); }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTapDown: (_) => _controller.forward(), onTapUp: (_) { _controller.reverse(); widget.onTap?.call(); }, onTapCancel: () => _controller.reverse(), child: ScaleTransition(scale: _scaleAnimation, child: Container(margin: const EdgeInsets.symmetric(vertical: 6), decoration: BoxDecoration(borderRadius: BorderRadius.circular(24.0), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 15, spreadRadius: -5, offset: const Offset(0, 5))]), child: Container(padding: widget.padding, decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), borderRadius: BorderRadius.circular(24.0), border: Border.all(color: Colors.white.withOpacity(0.3))), child: widget.child))));
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
  void initState() { super.initState(); _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500)); final delay = (widget.index * 80).clamp(0, 400); _opacity = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut)); _slide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut)); Future.delayed(Duration(milliseconds: delay), () { if (mounted) _controller.forward(); }); }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => FadeTransition(opacity: _opacity, child: SlideTransition(position: _slide, child: widget.child));
}

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
    final backgroundPaint = Paint()..color = backgroundColor.withOpacity(0.2)..style = PaintingStyle.stroke..strokeWidth = strokeWidth;
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi, false, backgroundPaint);
    final progressPaint = Paint()..shader = SweepGradient(colors: [progressColor.withOpacity(0.5), progressColor.withOpacity(0.8)], transform: const GradientRotation(-math.pi / 2)).createShader(rect)..style = PaintingStyle.stroke..strokeWidth = strokeWidth..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, progressPaint);
  }
  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) => oldDelegate.progress != progress;
}