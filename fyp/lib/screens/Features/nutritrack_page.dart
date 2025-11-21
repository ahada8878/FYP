import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart'; 
// 🚨 Ensure these point to your actual files
import 'package:fyp/models/food_log.dart'; 
import 'package:fyp/services/food_log_service.dart'; 

// --- 🎨 COLOR PALETTE ---
const Color safeGreen = Color(0xFF2E7D32);
const Color calorieOrange = Color(0xFFFF6D00);
const Color darkText = Color(0xFF2D3436);
const Color greyText = Color(0xFF636E72);
const Color lightBg = Color(0xFFFAFAFA);

class NutriTrackPage extends StatefulWidget {
  // ✅ Added this back so your other screen doesn't crash
  final String? initialMessage;

  const NutriTrackPage({super.key, this.initialMessage});

  @override
  State<NutriTrackPage> createState() => _NutriTrackPageState();
}

class _NutriTrackPageState extends State<NutriTrackPage> {
  final FoodLogService _foodLogService = FoodLogService();
  late Future<Map<DateTime, List<FoodLog>>> _logsFuture;

  @override
  void initState() {
    super.initState();
    // ✅ Start with loader enabled
    _logsFuture = _fetchLastSevenDaysLogs(isInitialLoad: true);

    // ✅ Handle the initial message (SnackBar)
    if (widget.initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.initialMessage!),
            backgroundColor: calorieOrange,
            duration: const Duration(seconds: 3),
          ),
        );
      });
    }
  }

  Future<Map<DateTime, List<FoodLog>>> _fetchLastSevenDaysLogs({bool isInitialLoad = false}) async {
    // --- ⏳ 5-SECOND LOADER (Only on first load) ---
    if (isInitialLoad) {
      await Future.delayed(const Duration(seconds: 5));
    }

    Map<DateTime, List<FoodLog>> logData = {};
    List<DateTime> daysToFetch = [];
    final now = DateTime.now();
    
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      daysToFetch.add(DateTime(date.year, date.month, date.day));
    }
    
    List<Future<List<FoodLog>>> fetchFutures = daysToFetch
        .map((date) => _foodLogService.getFoodLogsForDate(date))
        .toList();
        
    try {
      final List<List<FoodLog>> results = await Future.wait(fetchFutures);
      for (int i = 0; i < daysToFetch.length; i++) {
        logData[daysToFetch[i]] = results[i];
      }
      return logData;
    } catch (e) {
      throw Exception('Failed to load logs: $e');
    }
  }

  Future<void> _handleRefresh() async {
    setState(() {
      // ✅ Instant refresh (no delay)
      _logsFuture = _fetchLastSevenDaysLogs(isInitialLoad: false);
    });
  }

  Future<void> _skipMeal(String mealType, DateTime date) async {
    try {
      final success = await _foodLogService.logFood(
        mealType: mealType,
        productName: "Skipped - $mealType",
        nutrients: {'calories': 0, 'protein': 0, 'fat': 0, 'carbohydrates': 0},
        date: date, 
        imageUrl: null,
      );
      if (success) _handleRefresh();
    } catch (e) {
      debugPrint("Error skipping meal: $e");
    }
  }

  void _openManualLogSheet(String mealType, DateTime date) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, 
      builder: (context) => _ManualLogFoodSheet(
        mealType: mealType,
        date: date, 
        onSuccess: _handleRefresh,
      ),
    );
  }

  // --- LOADING VIEW ---
  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
              padding: const EdgeInsets.all(20), 
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5), 
                  shape: BoxShape.circle, 
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 30)]
              ), 
              child: Lottie.asset('assets/animation/Loading_12.json', width: 200, height: 200)
          ),
          const SizedBox(height: 40),
          Text(
              "Loading History...", 
              style: TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.w900, 
                  color: Theme.of(context).colorScheme.primary 
              )
          ),
          const SizedBox(height: 10),
          const Padding(
              padding: EdgeInsets.symmetric(horizontal: 50), 
              child: Text(
                  "Fetching your nutritional journey.", 
                  textAlign: TextAlign.center, 
                  style: TextStyle(fontSize: 15, color: greyText)
              )
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text("Food History", style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).colorScheme.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          const _LivingAnimatedBackground(),
          Container(color: Colors.white.withOpacity(0.3)),
          
          SafeArea(
            bottom: false,
            child: FutureBuilder<Map<DateTime, List<FoodLog>>>(
              future: _logsFuture,
              builder: (context, snapshot) {
                
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingView();
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline_rounded, size: 60, color: Colors.red.shade400),
                        const SizedBox(height: 16),
                        Text("Failed to load history", style: TextStyle(color: darkText, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    )
                  );
                }

                final logData = snapshot.data ?? {};
                final sortedDates = logData.keys.toList()..sort((a, b) => b.compareTo(a));

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: _buildWeeklySummary(logData),
                      ),
                    ),

                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final date = sortedDates[index];
                          final logs = logData[date]!;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            child: _GlassDayCard(
                              date: date, 
                              logs: logs,
                              onSkip: (meal) => _skipMeal(meal, date),
                              onLog: (meal) => _openManualLogSheet(meal, date),
                            ),
                          );
                        },
                        childCount: sortedDates.length,
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 50)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklySummary(Map<DateTime, List<FoodLog>> data) {
    int totalCals = 0;
    data.forEach((key, value) {
      for(var log in value) { totalCals += log.nutrients.calories.toInt(); }
    });
    int avgCals = data.isNotEmpty ? (totalCals / data.length).round() : 0;

    return _GlassContainer(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Weekly Average", style: TextStyle(color: greyText, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("$avgCals", style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 28, fontWeight: FontWeight.w900)),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5, left: 4),
                    child: Text("kcal / day", style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              )
            ],
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: calorieOrange.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.insights_rounded, color: calorieOrange, size: 24),
          )
        ],
      ),
    );
  }
}

// --- 🎨 GLASS WIDGETS ---

class _GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const _GlassContainer({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.65),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))]
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlassDayCard extends StatelessWidget {
  final DateTime date;
  final List<FoodLog> logs;
  final Function(String) onSkip;
  final Function(String) onLog;

  const _GlassDayCard({
    required this.date, 
    required this.logs,
    required this.onSkip,
    required this.onLog
  });

  @override
  Widget build(BuildContext context) {
    final double totalCalories = logs.fold(0.0, (sum, log) => sum + log.nutrients.calories);
    final now = DateTime.now();
    final isTodayOrPast = date.isBefore(DateTime(now.year, now.month, now.day).add(const Duration(days: 1)));

    String title;
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      title = 'Today';
    } else if (date.year == now.year && date.month == now.month && date.day == now.day - 1) {
      title = 'Yesterday';
    } else {
      title = DateFormat('EEEE').format(date);
    }
    String subtitleDate = DateFormat('MMM d').format(date);

    List<Widget> missingMealWidgets = [];
    if (isTodayOrPast) {
      final loggedMealTypes = logs.map((l) => l.mealType).toSet();
      final allMealTypes = ['Breakfast', 'Lunch', 'Dinner'];
      for (var type in allMealTypes) {
        if (!loggedMealTypes.contains(type)) {
          missingMealWidgets.add(_buildMissingAction(context, type));
        }
      }
    }

    return _GlassContainer(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: title == 'Today',
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          childrenPadding: const EdgeInsets.only(bottom: 16),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.primary)),
                  Text(subtitleDate, style: const TextStyle(fontSize: 12, color: greyText, fontWeight: FontWeight.w600)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: safeGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Text("${totalCalories.round()} kcal", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: safeGreen)),
              )
            ],
          ),
          children: [
            if (missingMealWidgets.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(children: [
                  Icon(Icons.info_outline_rounded, size: 14, color: calorieOrange),
                  SizedBox(width: 6),
                  Text("Pending Meals", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: calorieOrange))
                ]),
              ),
              ...missingMealWidgets,
              if (logs.isNotEmpty) const Divider(height: 20, indent: 20, endIndent: 20),
            ],

            if (logs.isEmpty && missingMealWidgets.isEmpty)
              const Padding(padding: EdgeInsets.all(16), child: Text("Nothing logged.", style: TextStyle(color: greyText, fontSize: 12))),

            ...logs.map((log) => _buildLoggedItem(log)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMissingAction(BuildContext context, String type) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        children: [
          Text(type, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: darkText)),
          const Spacer(),
          InkWell(
            onTap: () => onSkip(type),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text("Skip", style: TextStyle(fontSize: 12, color: greyText.withOpacity(0.7), fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: () => onLog(type),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(20)),
              child: const Text("Log +", style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoggedItem(FoodLog log) {
    bool isSkipped = log.nutrients.calories == 0 && log.productName.startsWith("Skipped");
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        children: [
          Container(
            width: 4, height: 30,
            decoration: BoxDecoration(
              color: isSkipped ? Colors.grey.shade300 : safeGreen,
              borderRadius: BorderRadius.circular(2)
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.productName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isSkipped ? greyText : darkText, decoration: isSkipped ? TextDecoration.lineThrough : null)),
                Text(log.mealType, style: TextStyle(fontSize: 11, color: greyText.withOpacity(0.8))),
              ],
            ),
          ),
          if (!isSkipped)
            Text("${log.nutrients.calories.round()} kcal", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: darkText)),
        ],
      ),
    );
  }
}

// --- 📝 MANUAL LOG SHEET (Modern) ---
class _ManualLogFoodSheet extends StatefulWidget {
  final String mealType;
  final DateTime date;
  final VoidCallback onSuccess;

  const _ManualLogFoodSheet({required this.mealType, required this.date, required this.onSuccess});
  @override
  State<_ManualLogFoodSheet> createState() => _ManualLogFoodSheetState();
}

class _ManualLogFoodSheetState extends State<_ManualLogFoodSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _carbsController = TextEditingController();
  final _proteinController = TextEditingController();
  final _fatController = TextEditingController();
  final FoodLogService _foodLogService = FoodLogService();

  void _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      final nutrients = {
        'calories': int.tryParse(_caloriesController.text) ?? 0,
        'carbohydrates': double.tryParse(_carbsController.text) ?? 0.0,
        'protein': double.tryParse(_proteinController.text) ?? 0.0,
        'fat': double.tryParse(_fatController.text) ?? 0.0,
      };
      
      await _foodLogService.logFood(
        mealType: widget.mealType,
        productName: _nameController.text.trim(),
        nutrients: nutrients,
        date: widget.date,
        imageUrl: null,
      );
      if(mounted) {
        widget.onSuccess();
        Navigator.pop(context);
      }
    }
  }

  InputDecoration _cleanInputDecor(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: greyText, size: 20),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      labelStyle: const TextStyle(color: greyText),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text("Log ${widget.mealType}", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.primary)),
            Text(DateFormat('MMMM d').format(widget.date), style: const TextStyle(color: greyText)),
            const SizedBox(height: 30),
            
            TextFormField(controller: _nameController, decoration: _cleanInputDecor("Food Name", Icons.restaurant), validator: (v) => v!.isEmpty ? 'Required' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _caloriesController, keyboardType: TextInputType.number, decoration: _cleanInputDecor("Calories", Icons.local_fire_department_rounded), validator: (v) => v!.isEmpty ? 'Required' : null),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextFormField(controller: _carbsController, keyboardType: TextInputType.number, decoration: _cleanInputDecor("Carbs", Icons.grain_rounded))),
              const SizedBox(width: 12),
              Expanded(child: TextFormField(controller: _proteinController, keyboardType: TextInputType.number, decoration: _cleanInputDecor("Protein", Icons.egg_alt_outlined))),
            ]),
            const SizedBox(height: 30),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0
                ),
                child: const Text("Save Entry", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            )
          ],
        ),
      ),
    );
  }
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