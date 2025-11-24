import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:fyp/services/config_service.dart';

class ActivityHistoryScreen extends StatefulWidget {
  const ActivityHistoryScreen({super.key});

  @override
  State<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends State<ActivityHistoryScreen> {
  bool _isLoading = true;
  List<dynamic> _allLogs = [];
  String _graphMode = 'Weekly'; // 'Weekly' or 'Monthly'

  // Summary Stats
  int _totalCalories = 0;
  int _totalMinutes = 0;
  int _workoutCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token') ?? prefs.getString('auth_token') ?? prefs.getString('userToken');
      
      if (token == null) throw Exception("User not authenticated.");

      debugPrint("🚀 Fetching: $baseURL/api/activities/full-history");

      final response = await http.get(
        Uri.parse("$baseURL/api/activities/full-history"), 
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        
        int cals = 0;
        int mins = 0;
        for (var log in data) {
          cals += (log['caloriesBurned'] as num).toInt();
          mins += (log['duration'] as num).toInt();
        }

        if (mounted) {
          setState(() {
            _allLogs = data;
            _totalCalories = cals;
            _totalMinutes = mins;
            _workoutCount = data.length;
            _isLoading = false;
          });
        }
      } else {
        throw Exception("Server returned ${response.statusCode}");
      }
    } catch (e) {
      if(mounted) {
        setState(() => _isLoading = false);
        debugPrint("❌ Error: $e");
      }
    }
  }

  // ✅ FIXED: Robust Date Matching for Graph
  Map<String, double> _getGraphData() {
    final Map<String, double> data = {};
    final now = DateTime.now();
    final int days = _graphMode == 'Weekly' ? 7 : 30;

    // 1. Initialize keys for the past N days
    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final key = DateFormat('MM/dd').format(date);
      data[key] = 0.0;
    }

    // 2. Populate with data using strict Day comparison
    for (var log in _allLogs) {
      if (log['date'] == null) continue;
      final logDate = DateTime.parse(log['date']).toLocal();
      
      // Check if logDate is within the range
      final difference = now.difference(logDate).inDays;
      
      if (difference <= days + 1) { // +1 buffer to catch edge cases
         // Re-format to match keys exactly
         final key = DateFormat('MM/dd').format(logDate);
         if (data.containsKey(key)) {
           data[key] = (data[key] ?? 0) + (log['caloriesBurned'] as num).toDouble();
         }
      }
    }
    return data;
  }

  Map<String, List<dynamic>> _getGroupedLogs() {
    Map<String, List<dynamic>> grouped = {};
    for (var log in _allLogs) {
      if (log['date'] == null) continue;
      final date = DateTime.parse(log['date']).toLocal();
      final now = DateTime.now();
      String key;
      
      if (date.year == now.year && date.month == now.month && date.day == now.day) {
        key = "Today";
      } else if (date.year == now.year && date.month == now.month && date.day == now.day - 1) {
        key = "Yesterday";
      } else {
        key = DateFormat('EEEE, MMM d').format(date);
      }

      if (grouped[key] == null) grouped[key] = [];
      grouped[key]!.add(log);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final graphData = _getGraphData();
    final groupedLogs = _getGroupedLogs();
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        title:  Text("Activity History", style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading:  BackButton(color: Theme.of(context).colorScheme.primary),
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: primaryColor))
        : RefreshIndicator(
            onRefresh: _fetchHistory,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // 1. STATS HEADER & GRAPH
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatsRow(),
                        const SizedBox(height: 24),
                        
                        // Graph Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Performance", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  _GraphTab(label: "Week", isSelected: _graphMode == 'Weekly', onTap: () => setState(() => _graphMode = 'Weekly')),
                                  _GraphTab(label: "Month", isSelected: _graphMode == 'Monthly', onTap: () => setState(() => _graphMode = 'Monthly')),
                                ],
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Graph Container
                        Container(
                          height: 220,
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          // ✅ FIXED: Passing Context for Directionality
                          child: CustomPaint(
                            size: Size.infinite,
                            painter: _SolidBarChartPainter(
                              data: graphData, 
                              primaryColor: primaryColor,
                              context: context // Pass context
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ✅ FIXED: "Recent History" is now its own Sliver, so it scrolls properly
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
                    child: const Text(
                      "Recent History", 
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                    ),
                  ),
                ),

                // 2. EMPTY STATE OR LIST
                if (_allLogs.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bar_chart_rounded, size: 80, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text("No activities found", style: TextStyle(fontSize: 16, color: Colors.grey[500], fontWeight: FontWeight.bold)),
                          TextButton(onPressed: _fetchHistory, child: const Text("Tap to Refresh"))
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          String key = groupedLogs.keys.elementAt(index);
                          List<dynamic> logs = groupedLogs[key]!;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12, top: 4),
                                child: Text(key.toUpperCase(), style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                              ),
                              ...logs.map((log) => _ActivityTile(log: log)).toList(),
                              const SizedBox(height: 12),
                            ],
                          );
                        },
                        childCount: groupedLogs.length,
                      ),
                    ),
                  ),
              ],
            ),
          ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _StatCard(label: "Calories", value: "$_totalCalories", unit: "kcal", color: Colors.orange, icon: Icons.local_fire_department),
        const SizedBox(width: 12),
        _StatCard(label: "Active", value: "${(_totalMinutes / 60).toStringAsFixed(1)}", unit: "hrs", color: Colors.blue, icon: Icons.timer),
        const SizedBox(width: 12),
        _StatCard(label: "Count", value: "$_workoutCount", unit: "logs", color: Colors.green, icon: Icons.check_circle),
      ],
    );
  }
}

// --- SUB WIDGETS ---

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  final IconData icon;

  const _StatCard({required this.label, required this.value, required this.unit, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
            Text(unit, style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final dynamic log;
  const _ActivityTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final activityName = log['activityName'] ?? 'Unknown';
    final date = DateTime.parse(log['date']).toLocal();
    final time = DateFormat.jm().format(date);
    
    Color color = Colors.indigo;
    IconData icon = Icons.fitness_center;
    
    if (activityName.toString().toLowerCase().contains('run')) { color = Colors.orange; icon = Icons.directions_run; }
    else if (activityName.toString().toLowerCase().contains('cycl')) { color = Colors.blue; icon = Icons.directions_bike; }
    else if (activityName.toString().toLowerCase().contains('walk')) { color = Colors.green; icon = Icons.directions_walk; }
    else if (activityName.toString().toLowerCase().contains('swim')) { color = Colors.cyan; icon = Icons.pool; }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
          child: Icon(icon, color: color),
        ),
        title: Text(activityName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text("$time • ${log['duration']} mins", style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text("+${log['caloriesBurned']}", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: color)),
            const Text("kcal", style: TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _GraphTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _GraphTab({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))] : [],
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Colors.black : Colors.grey[600])),
      ),
    );
  }
}

// ✅ FIXED: Removed hardcoded TextDirection.ltr
class _SolidBarChartPainter extends CustomPainter {
  final Map<String, double> data;
  final Color primaryColor;
  final BuildContext context; // ✅ Receive context

  _SolidBarChartPainter({required this.data, required this.primaryColor, required this.context});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final double barWidth = (size.width / data.length) * 0.5;
    final double spacing = (size.width / data.length) * 0.5;
    final double labelAreaHeight = 30.0;
    final double chartHeight = size.height - labelAreaHeight;

    double maxVal = 0;
    for (var val in data.values) if (val > maxVal) maxVal = val;
    if (maxVal == 0) maxVal = 100;

    final gridPaint = Paint()..color = Colors.grey.withOpacity(0.1)..strokeWidth = 1.5;
    canvas.drawLine(Offset(0, chartHeight), Offset(size.width, chartHeight), gridPaint);
    canvas.drawLine(Offset(0, chartHeight * 0.66), Offset(size.width, chartHeight * 0.66), gridPaint);
    canvas.drawLine(Offset(0, chartHeight * 0.33), Offset(size.width, chartHeight * 0.33), gridPaint);

    final barPaint = Paint()..style = PaintingStyle.fill;
    
    int i = 0;
    for (var entry in data.entries) {
      final double left = (i * (barWidth + spacing)) + spacing / 2;
      final double barHeight = (entry.value / maxVal) * chartHeight;
      
      final double renderHeight = (entry.value > 0 && barHeight < 5) ? 5 : barHeight;

      if (entry.value > 0) {
        final rect = Rect.fromLTWH(left, chartHeight - renderHeight, barWidth, renderHeight);
        
        barPaint.shader = LinearGradient(
          colors: [primaryColor, primaryColor.withOpacity(0.7)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(rect);

        canvas.drawRRect(RRect.fromRectAndCorners(rect, topLeft: const Radius.circular(6), topRight: const Radius.circular(6)), barPaint);
      }

      if (data.length <= 7 || i % 4 == 0) {
        final textSpan = TextSpan(
          text: entry.key,
          style: TextStyle(color: Colors.grey[600], fontSize: 11, fontWeight: FontWeight.w600),
        );
        
        // ✅ FIXED: Use Directionality.of(context) instead of hardcoded ltr
        final textPainter = TextPainter(
          text: textSpan, 
          textDirection: Directionality.of(context) 
        );
        
        textPainter.layout();
        textPainter.paint(canvas, Offset(left + (barWidth / 2) - (textPainter.width / 2), chartHeight + 8));
      }
      i++;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}