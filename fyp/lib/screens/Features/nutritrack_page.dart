// lib/pages/nutritrack_page.dart

import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

// 🚨 IMPORTANT: Replace the dummy classes with your actual imports
// Assuming these are the paths based on previous context:
import 'package:fyp/models/food_log.dart'; 
import 'package:fyp/services/food_log_service.dart'; 


// =========================================================
// MOCK CLASSES for Compilation (DELETE THIS SECTION IF YOU USE IMPORTS ABOVE)
// If the actual imports fail, temporarily use this to verify the UI:
// class FoodLog { final String id; final String mealType; final String productName; final Nutrients nutrients; final String? imageUrl; final String? brands; FoodLog({required this.id, required this.mealType, required this.productName, required this.nutrients, this.imageUrl, this.brands}); }
// class Nutrients { final double calories; final double protein; final double fat; final double carbohydrates; Nutrients({required this.calories, required this.protein, required this.fat, required this.carbohydrates}); }
// class FoodLogService { Future<bool> logFood({ required String mealType, required String productName, required Map<String, dynamic> nutrients, String? imageUrl, required DateTime date, }) async { await Future.delayed(const Duration(milliseconds: 500)); return true; } Future<List<FoodLog>> getFoodLogsForDate(DateTime date) async { await Future.delayed(const Duration(milliseconds: 500)); if (date.day == DateTime.now().day) { return [ FoodLog(id: '1', mealType: 'Breakfast', productName: 'Oatmeal with berries', nutrients: Nutrients(calories: 350, protein: 10, fat: 5, carbohydrates: 60)), FoodLog(id: '2', mealType: 'Lunch', productName: 'Chicken Salad', nutrients: Nutrients(calories: 450, protein: 30, fat: 15, carbohydrates: 25)), ]; } return []; } Future<Map<DateTime, List<FoodLog>>> fetchLastSevenDaysLogs() async { await Future.delayed(const Duration(milliseconds: 500)); return {DateTime.now(): []}; } }
// =========================================================


class NutriTrackPage extends StatefulWidget {
  // ✅ --- NEW: Optional message to display when navigating here ---
  final String? initialMessage;
  
  const NutriTrackPage({super.key, this.initialMessage});

  @override
  State<NutriTrackPage> createState() => _NutriTrackPageState();
}

class _NutriTrackPageState extends State<NutriTrackPage> {
  final FoodLogService _foodLogService = FoodLogService();
  final ScrollController _scrollController = ScrollController();
  late Future<Map<DateTime, List<FoodLog>>> _logsFuture;

  @override
  void initState() {
    super.initState();
    // ✅ Use the new efficient service method
    _logsFuture = _foodLogService.fetchLastSevenDaysLogs();

    // ✅ Show SnackBar if initialMessage is present
    if (widget.initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.initialMessage!),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(label: 'OK', textColor: Colors.white, onPressed: (){}),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    // This function is used by the CupertinoSliverRefreshControl
    setState(() {
      // ✅ Use the new efficient service method
      _logsFuture = _foodLogService.fetchLastSevenDaysLogs();
    });
  }

  /// Logs a skipped meal with 0 nutrients for a specific date
  Future<void> _skipMeal(String mealType, DateTime date) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Skipping $mealType for ${DateFormat('MM/dd').format(date)}...')),
      );

      final success = await _foodLogService.logFood(
        mealType: mealType,
        productName: "Skipped - $mealType",
        // Nutrients map keys match the Mongoose schema keys (all 0)
        nutrients: {'calories': 0, 'protein': 0, 'fat': 0, 'carbohydrates': 0},
        date: date, 
        imageUrl: null,
      );

      if (success) {
        _handleRefresh(); // Refresh the list
        if (mounted) {
           ScaffoldMessenger.of(context).hideCurrentSnackBar();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to skip meal.'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const _LivingAnimatedBackground(),
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildHeader(context),
              CupertinoSliverRefreshControl(
                onRefresh: _handleRefresh,
              ),
              FutureBuilder<Map<DateTime, List<FoodLog>>>(
                future: _logsFuture,
                builder: (context, snapshot) {
                  // --- Error and Loading States must be wrapped in Slivers ---
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            CircularProgressIndicator(color: Colors.white),
                            SizedBox(height: 16),
                            Text('Loading food logs...', style: TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return SliverFillRemaining(
                      child: Center(child: Text('Error loading logs: ${snapshot.error}', style: TextStyle(color: Colors.red))),
                    );
                  }

                  // --- Data Loaded State ---
                  final logData = snapshot.data ?? {};
                  final sortedDates = logData.keys.toList()..sort((a, b) => b.compareTo(a));

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final date = sortedDates[index];
                          final logs = logData[date]!;
                          return StaggeredAnimation(
                            index: index,
                            child: _buildDayExpansionTile(date, logs),
                          );
                        },
                        childCount: sortedDates.length,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildHeader(BuildContext context) {
    const String imageUrl =
        'https://images.unsplash.com/photo-1490818387583-1baba5e63849?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1470&q=80';

    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: ClipRRect(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Spacer(),
                      _AnimatedHeaderGreeting(greeting: "NutriTrack History", subtitle: "Your daily food log."),
                      Spacer(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayExpansionTile(DateTime date, List<FoodLog> logs) {
    final double totalCalories = logs.fold(0.0, (sum, log) => sum + log.nutrients.calories);
    
    final now = DateTime.now();
    // Check if the date is not in the future (allowing logging for all displayed historical days)
    final isTodayOrPast = date.isBefore(DateTime(now.year, now.month, now.day).add(const Duration(days: 1)));
    
    String title;
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      title = 'Today - ${DateFormat('MMMM d').format(date)}';
    } else if (date.year == now.year && date.month == now.month && date.day == now.day - 1) {
      title = 'Yesterday - ${DateFormat('MMMM d').format(date)}';
    } else {
      title = DateFormat('EEEE, MMMM d').format(date);
    }

    // --- Missing Meals Logic (Applies to all past/today dates) ---
    List<Widget> missingMealWidgets = [];
    if (isTodayOrPast) {
      final loggedMealTypes = logs.map((l) => l.mealType).toSet();
      // ✅ Use shared validation list from Service if desired, but hardcoding here is fine for UI display
      final allMealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];
      
      for (var type in allMealTypes) {
        if (!loggedMealTypes.contains(type)) {
          missingMealWidgets.add(_buildMissingMealRow(type, date)); 
        }
      }
    }
    // --- END MISSING MEAL LOGIC ---

    return _InteractiveCard(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        initiallyExpanded: title.startsWith('Today') && logs.isNotEmpty,
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        iconColor: Colors.grey[800],
        collapsedIconColor: Colors.grey[800],
        leading: Icon(Icons.calendar_today, color: Theme.of(context).primaryColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF333333))),
        subtitle: Text('${logs.length} items  •  ${totalCalories.round()} kcal', style: TextStyle(fontSize: 14, color: Colors.grey[800])),
        children: [
          // 1. Display Missing Meals Section
          if (missingMealWidgets.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Text("Missing Logs", style: TextStyle(color: Colors.orange[800], fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
            ...missingMealWidgets,
            const Divider(height: 24),
          ],
          
          // 2. Display Logged Items
          if (logs.isEmpty && missingMealWidgets.isEmpty)
            const ListTile(title: Center(child: Text('No items logged.', style: TextStyle(color: Colors.grey)))),
          
          ...logs.map((log) => _buildFoodItemTile(log)).toList(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildMissingMealRow(String mealType, DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        children: [
          Text(mealType, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const Spacer(),
          // Skip Button
          TextButton(
            onPressed: () => _skipMeal(mealType, date),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text("Skip", style: TextStyle(fontSize: 13)),
          ),
          const SizedBox(width: 8),
          // Log Button
          ElevatedButton(
            onPressed: () => _openManualLogSheet(mealType, date),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text("Log", style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodItemTile(FoodLog log) {
    bool isSkipped = log.nutrients.calories == 0 && log.productName.startsWith("Skipped");
    
    return ListTile(
      dense: true,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(log.mealType, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Theme.of(context).primaryColor)),
          const SizedBox(height: 2),
          Text(
            log.productName, 
            style: TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.w600, 
              color: isSkipped ? Colors.grey : const Color(0xFF333333),
              fontStyle: isSkipped ? FontStyle.italic : FontStyle.normal
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      trailing: Text('${log.nutrients.calories.round()} kcal', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
      onTap: () => _showLogDetailsDialog(context, log),
    );
  }

  void _showLogDetailsDialog(BuildContext context, FoodLog log) {
     showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
          title: Text(log.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 _buildNutrientRow('Calories', '${log.nutrients.calories.round()} kcal'),
                _buildNutrientRow('Protein', '${log.nutrients.protein.round()} g'),
                _buildNutrientRow('Fat', '${log.nutrients.fat.round()} g'),
                _buildNutrientRow('Carbohydrates', '${log.nutrients.carbohydrates.round()} g'),
                if (log.brands != null && log.brands!.isNotEmpty)
                   Padding(padding: const EdgeInsets.only(top: 10.0), child: _buildNutrientRow('Brand', log.brands!)),
              ],
            ),
          ),
          actions: [
            TextButton(child: Text('Close', style: TextStyle(color: Theme.of(context).primaryColor)), onPressed: () => Navigator.of(context).pop()),
          ],
        );
      },
    );
  }

  Widget _buildNutrientRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.black54)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}


// --- MANUAL LOG SHEET (Receives Date) ---
class _ManualLogFoodSheet extends StatefulWidget {
  final String mealType;
  final DateTime date; // Specific date for logging
  final VoidCallback onSuccess;

  const _ManualLogFoodSheet({
    required this.mealType, 
    required this.date, 
    required this.onSuccess
  });

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

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _carbsController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      _logToBackend(widget.mealType);
    }
  }

  Future<void> _logToBackend(String mealType) async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saving to food log...')));

    try {
      final nutrients = {
        'calories': int.tryParse(_caloriesController.text) ?? 0,
        'carbohydrates': double.tryParse(_carbsController.text) ?? 0.0,
        'protein': double.tryParse(_proteinController.text) ?? 0.0,
        'fat': double.tryParse(_fatController.text) ?? 0.0,
      };

      final success = await _foodLogService.logFood(
        mealType: mealType,
        productName: _nameController.text.trim(),
        nutrients: nutrients,
        date: widget.date, // Use the specific date from the widget
        imageUrl: null,
      );

      if (success) {
        if (mounted) {
          Navigator.of(context).pop(); // Close the Bottom Sheet
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Food logged successfully! 🎉'), backgroundColor: Colors.green),
          );
          widget.onSuccess(); // Refresh the parent page
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to log food. Please try again.'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    InputDecoration inputDecoration(String label, IconData icon) {
      return InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        labelText: label,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide.none),
        floatingLabelBehavior: FloatingLabelBehavior.never,
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 5, margin: const EdgeInsets.symmetric(vertical: 8), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 8),
              Text('Log ${widget.mealType}', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              Text('for ${DateFormat('EEEE, MMM d').format(widget.date)}', style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: inputDecoration('Food Name', Icons.restaurant_menu_rounded),
                      validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter a name' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _caloriesController,
                      decoration: inputDecoration('Calories (kcal)', Icons.local_fire_department_rounded),
                      keyboardType: TextInputType.number,
                      validator: (value) => (value == null || int.tryParse(value) == null || int.parse(value) < 0) ? 'Please enter valid calories' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: TextFormField(controller: _carbsController, decoration: inputDecoration('Carbs (g)', Icons.grain_rounded), keyboardType: TextInputType.number)),
                        const SizedBox(width: 12),
                        Expanded(child: TextFormField(controller: _proteinController, decoration: inputDecoration('Protein (g)', Icons.egg_alt_outlined), keyboardType: TextInputType.number)),
                        const SizedBox(width: 12),
                        Expanded(child: TextFormField(controller: _fatController, decoration: inputDecoration('Fat (g)', Icons.opacity_rounded), keyboardType: TextInputType.number)),
                      ],
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0))),
                      child: const Text('Log Meal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- COPIED HELPER WIDGETS ---

class _LivingAnimatedBackground extends StatefulWidget {
  const _LivingAnimatedBackground();
  @override
  State<_LivingAnimatedBackground> createState() => _LivingAnimatedBackgroundState();
}

class _LivingAnimatedBackgroundState extends State<_LivingAnimatedBackground> with TickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 40))..repeat(reverse: true);
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final colors = [
      Color.lerp(const Color(0xffa8edea), const Color(0xfffed6e3), _controller.value)!,
      Color.lerp(const Color(0xfffed6e3), const Color(0xffa8edea), _controller.value)!,
    ];
    return AnimatedBuilder(animation: _controller, builder: (context, child) => Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors))));
  }
}

class _AnimatedHeaderGreeting extends StatelessWidget {
  final String greeting;
  final String subtitle;
  const _AnimatedHeaderGreeting({required this.greeting, required this.subtitle});
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(opacity: value, child: Transform.translate(offset: Offset(0, 20 * (1 - value)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(greeting, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(subtitle, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70))]))),
    );
  }
}

class _InteractiveCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  const _InteractiveCard({required this.child, this.onTap, this.padding = EdgeInsets.zero});
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
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) { _controller.reverse(); widget.onTap?.call(); },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24.0),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(
                padding: widget.padding,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.65), borderRadius: BorderRadius.circular(24.0), border: Border.all(color: Colors.white.withOpacity(0.3))),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
    Future.delayed(Duration(milliseconds: delay), () { if (mounted) _controller.forward(); });
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => FadeTransition(opacity: _opacity, child: SlideTransition(position: _slide, child: widget.child));
}