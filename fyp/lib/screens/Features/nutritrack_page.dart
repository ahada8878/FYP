// lib/pages/nutritrack_page.dart
import 'dart:ui'; // Needed for ImageFilter
import 'package:flutter/cupertino.dart'; // Needed for CupertinoSliverRefreshControl
import 'package:flutter/material.dart';
import 'package:fyp/models/food_log.dart'; // Your model
import 'package:fyp/services/food_log_service.dart'; // Your service
import 'package:intl/intl.dart'; // For formatting dates
import 'package:cached_network_image/cached_network_image.dart'; // For header image

class NutriTrackPage extends StatefulWidget {
  const NutriTrackPage({super.key});

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
    _logsFuture = _fetchLastSevenDaysLogs();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<Map<DateTime, List<FoodLog>>> _fetchLastSevenDaysLogs() async {
    // ... (Your existing fetch logic - no changes needed)
    Map<DateTime, List<FoodLog>> logData = {};
    List<DateTime> daysToFetch = [];
    for (int i = 0; i < 7; i++) {
      daysToFetch.add(DateTime.now().subtract(Duration(days: i)));
    }
    List<Future<List<FoodLog>>> fetchFutures = daysToFetch
        .map((date) => _foodLogService.getFoodLogsForDate(date))
        .toList();
    try {
      final List<List<FoodLog>> results = await Future.wait(fetchFutures);
      for (int i = 0; i < daysToFetch.length; i++) {
        final dateKey = daysToFetch[i];
        logData[dateKey] = results[i];
      }
      return logData;
    } catch (e) {
      print("Error fetching logs: $e");
      throw Exception('Failed to load logs: $e');
    }
  }

  // --- NEW: Refresh handler ---
  Future<void> _handleRefresh() async {
    setState(() {
      _logsFuture = _fetchLastSevenDaysLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Make scaffold transparent to see the background
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1. The Animated Background (from features.dart)
          const _LivingAnimatedBackground(),

          // 2. The Scrollable Content
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 3. The Animated Header (from features.dart)
              _buildHeader(context),

              // 4. Pull-to-refresh
              CupertinoSliverRefreshControl(
                onRefresh: _handleRefresh,
              ),

              // 5. The FutureBuilder for your logs
              FutureBuilder<Map<DateTime, List<FoodLog>>>(
                future: _logsFuture,
                builder: (context, snapshot) {
                  // --- Loading State ---
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            CircularProgressIndicator(color: Colors.white),
                            SizedBox(height: 16),
                            Text(
                              'Loading food logs...',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // --- Error State ---
                  if (snapshot.hasError) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.white, size: 60),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading logs',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(color: Colors.white),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              snapshot.error.toString(),
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // --- No Data State ---
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const SliverFillRemaining(
                      child: Center(
                        child: Text(
                          'No data found.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    );
                  }

                  // --- Success State ---
                  final logData = snapshot.data!;
                  final sortedDates = logData.keys.toList()
                    ..sort((a, b) => b.compareTo(a));

                  // Return a SliverList instead of a ListView
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final date = sortedDates[index];
                          final logs = logData[date]!;
                          // Wrap each day's tile in the StaggeredAnimation
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

  // --- NEW: Header Widget (adapted from features.dart) ---
  SliverAppBar _buildHeader(BuildContext context) {
    const String imageUrl =
        'https://plus.unsplash.com/premium_photo-1670601440146-3b33dfcd7e17?ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80&w=1238';

    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading:
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
      flexibleSpace: FlexibleSpaceBar(
        background: ClipRRect(
          borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(40)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image with parallax
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 1.0, end: 1.15),
                duration: const Duration(seconds: 25),
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: child,
                  );
                },
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      Container(color: Colors.grey[300]),
                  errorWidget: (context, url, error) =>
                      Container(color: Colors.grey[300]),
                ),
              ),
              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.2),
                      Colors.black.withOpacity(0.7),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
              // Animated text
              AnimatedBuilder(
                animation: _scrollController,
                builder: (context, child) {
                  final offset = _scrollController.hasClients
                      ? _scrollController.offset
                      : 0;
                  return Transform.translate(
                    offset: Offset(0, offset * 0.5),
                    child: child,
                  );
                },
                child: const SafeArea(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Spacer(),
                        _AnimatedHeaderGreeting(
                          greeting: "NutriTrack History",
                          subtitle: "Your daily food log.",
                        ),
                        Spacer(),
                      ],
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

  /// --- MODIFIED: Builds the ExpansionTile inside an _InteractiveCard ---
  Widget _buildDayExpansionTile(DateTime date, List<FoodLog> logs) {
    final double totalCalories =
        logs.fold(0.0, (sum, log) => sum + log.nutrients.calories);

    String title;
    final now = DateTime.now();
    // ... (Your existing date formatting logic - no changes needed)
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      title = 'Today - ${DateFormat('MMMM d').format(date)}';
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1) {
      title = 'Yesterday - ${DateFormat('MMMM d').format(date)}';
    } else {
      title = DateFormat('EEEE, MMMM d').format(date);
    }

    // Replace Card with _InteractiveCard
    return _InteractiveCard(
      padding: EdgeInsets.zero, // ExpansionTile has its own padding
      child: ExpansionTile(
        initiallyExpanded: title.startsWith('Today') && logs.isNotEmpty,
        // Make backgrounds transparent to see the frosted glass
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        iconColor: Colors.grey[800],
        collapsedIconColor: Colors.grey[800],
        leading: Icon(
          Icons.calendar_today,
          color: Theme.of(context).primaryColor,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: Color(0xFF333333),
          ),
        ),
        subtitle: Text(
          '${logs.length} items  •  ${totalCalories.round()} kcal',
          style: TextStyle(fontSize: 14, color: Colors.grey[800]),
        ),
        children: [
          if (logs.isEmpty)
            const ListTile(
              title: Center(
                child: Text(
                  'No items logged for this day.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ...logs.map((log) => _buildFoodItemTile(log)).toList(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// Builds the ListTile for a single food item (Unchanged, but looks great)
  Widget _buildFoodItemTile(FoodLog log) {
    return ListTile(
      dense: true,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            log.mealType,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            log.productName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      trailing: Text(
        '${log.nutrients.calories.round()} kcal',
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      onTap: () => _showLogDetailsDialog(context, log),
    );
  }

  /// Shows the details popup dialog (Unchanged)
  void _showLogDetailsDialog(BuildContext context, FoodLog log) {
    // ... (Your existing dialog code - no changes needed)
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: Text(
            log.productName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (log.imageUrl != null && log.imageUrl!.isNotEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10.0),
                        child: Image.network(
                          log.imageUrl!,
                          height: 150,
                          width: 150,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const SizedBox(
                              height: 150,
                              width: 150,
                              child: Center(child: CircularProgressIndicator()),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const SizedBox(
                              height: 150,
                              width: 150,
                              child: Icon(Icons.broken_image,
                                  size: 50, color: Colors.grey),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                _buildNutrientRow(
                  'Calories',
                  '${log.nutrients.calories.round()} kcal',
                ),
                _buildNutrientRow(
                  'Protein',
                  '${log.nutrients.protein.round()} g',
                ),
                _buildNutrientRow(
                  'Fat',
                  '${log.nutrients.fat.round()} g',
                ),
                _buildNutrientRow(
                  'Carbohydrates',
                  '${log.nutrients.carbohydrates.round()} g',
                ),
                if (log.brands != null && log.brands!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: _buildNutrientRow('Brand', log.brands!),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text(
                'Close',
                style: TextStyle(color: Theme.of(context).primaryColor),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  /// Helper widget for styling the nutrient rows in the dialog (Unchanged)
  Widget _buildNutrientRow(String label, String value) {
    // ... (Your existing helper widget - no changes needed)
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// --- ALL HELPER WIDGETS FROM features.dart ---
// (Paste these at the bottom of your nutritrack_page.dart file)

class _LivingAnimatedBackground extends StatefulWidget {
  const _LivingAnimatedBackground();
  @override
  State<_LivingAnimatedBackground> createState() =>
      _LivingAnimatedBackgroundState();
}

class _LivingAnimatedBackgroundState extends State<_LivingAnimatedBackground>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(seconds: 40))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = [
      Color.lerp(
          const Color(0xffa8edea), const Color(0xfffed6e3), _controller.value)!,
      Color.lerp(
          const Color(0xfffed6e3), const Color(0xffa8edea), _controller.value)!,
    ];
    return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors),
            ),
          );
        });
  }
}

class _AnimatedHeaderGreeting extends StatelessWidget {
  final String greeting;
  final String subtitle;
  const _AnimatedHeaderGreeting(
      {required this.greeting, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting,
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: Colors.white70)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InteractiveCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  const _InteractiveCard(
      {required this.child, this.onTap, this.padding = EdgeInsets.zero});

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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24.0),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(
                padding: widget.padding,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(24.0),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
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