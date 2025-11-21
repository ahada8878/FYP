// usermealplan_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:fyp/services/meal_service.dart';
import 'package:fyp/screens/user_meal_details_screen.dart';

// --- ROBUST DATA MODELS (Unchanged) ---
class NutrientSummary {
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  NutrientSummary(
      {this.calories = 0, this.protein = 0, this.carbs = 0, this.fat = 0});
  factory NutrientSummary.fromMealList(List<MealInfo> meals) {
    double c = 0, p = 0, rb = 0, f = 0;
    for (var meal in meals) {
      c += meal.calories;
      p += meal.protein;
      rb += meal.carbs;
      f += meal.fat;
    }
    return NutrientSummary(
        calories: c.toInt(),
        protein: p.toInt(),
        carbs: rb.toInt(),
        fat: f.toInt());
  }
}

class MealInfo {
  final int id;
  final String title;
  final String imageUrl;
  final bool isLogged;
  final Map<String, dynamic> rawData;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  MealInfo(
      {required this.id,
      required this.title,
      required this.imageUrl,
      required this.isLogged,
      required this.rawData,
      this.calories = 0,
      this.protein = 0,
      this.carbs = 0,
      this.fat = 0});
  factory MealInfo.fromJson(
    Map<String, dynamic> mealJson, Map<int, dynamic> detailedRecipes) {
  final detailedMeal = detailedRecipes[mealJson['id']];
  final nutrients = detailedMeal?['nutrients'] ?? {};

  double getValue(String key) {
    try {
      return (nutrients[key.toLowerCase()] ?? nutrients[key] ?? 0.0).toDouble();
    } catch (_) {
      return 0.0;
    }
  }

  return MealInfo(
    id: mealJson['id'] ?? 0,
    title: mealJson['title'] ?? 'Untitled Meal',
    imageUrl: detailedMeal?['image'] ??
        "https://spoonacular.com/recipeImages/${mealJson['id']}-556x370.${mealJson['imageType'] ?? 'jpg'}",
    isLogged: mealJson['loggedAt'] != null,
    rawData: detailedMeal ?? mealJson,
    calories: getValue('calories'),
    protein: getValue('protein'),
    carbs: getValue('carbs'),
    fat: getValue('fat'),
  );
}

}

class DayPlan {
  final String dayName;
  final DateTime date;
  final List<MealInfo> meals;
  final NutrientSummary summary;
  DayPlan(
      {required this.dayName,
      required this.date,
      required this.meals,
      required this.summary});
  factory DayPlan.fromJson(
      MapEntry<String, dynamic> entry, Map<int, dynamic> detailedRecipes) {
    final dayData = entry.value as Map<String, dynamic>? ?? {};
    final mealListJson = dayData['meals'] as List<dynamic>? ?? [];
    final meals = mealListJson
        .map((mealJson) => MealInfo.fromJson(mealJson, detailedRecipes))
        .toList();
    return DayPlan(
      dayName: entry.key,
      date:
          DateTime.tryParse(dayData['date'] as String? ?? '') ?? DateTime.now(),
      meals: meals,
      summary: NutrientSummary.fromMealList(meals),
    );
  }
}
// --- END OF DATA MODELS ---

class UserMealPlanScreen extends StatefulWidget {
  const UserMealPlanScreen({super.key});
  @override
  State<UserMealPlanScreen> createState() => _UserMealPlanScreenState();
}

class _UserMealPlanScreenState extends State<UserMealPlanScreen> {
  List<DayPlan>? dayPlans;
  bool isLoading = true;
  String errorMessage = '';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMealPlan();
  }

  Future<void> _loadMealPlan() async {
    // Set loading to true only on the initial load.
    if (dayPlans == null) {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });
    }
    try {
      final response = await MealService.fetchUserMealPlan();
      final detailedRecipes =
          response['detailedRecipes'] as List<dynamic>? ?? [];
      final Map<int, dynamic> recipeDetailsMap = {
        for (var recipe in detailedRecipes) recipe['id']: recipe
      };
      final weekMeals = response['meals'] as Map<String, dynamic>? ?? {};
      final newDayPlans = weekMeals.entries
          .map((entry) => DayPlan.fromJson(entry, recipeDetailsMap))
          .toList();
      if (mounted) {
        setState(() {
          dayPlans = newDayPlans;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = "Failed to load meal plan.";
          isLoading = false;
        });
      }
    }
  }

  // --- MODIFIED: Updated to accept mealType and pass it to MealDetailsScreen ---
  Future<void> _navigateToDetails(MealInfo meal, DateTime date, String mealType) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MealDetailsScreen(
          meal: {
            ...meal.rawData,
            'loggedAt': meal.rawData['loggedAt'] ?? (meal.isLogged ? DateTime.now().toIso8601String() : null),
          },
          date: date,
          mealType: mealType, // Pass the determined meal type
        ),
      ),
    );

    // If the result is true, it means a meal was logged, so we reload the data.
    if (result == true && mounted) {
      _loadMealPlan();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const _LivingAnimatedBackground(),
          RefreshIndicator(
            onRefresh: _loadMealPlan,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                _buildHeader(context),
                if (isLoading)
                  const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator())),
                if (!isLoading && errorMessage.isNotEmpty)
                  SliverFillRemaining(child: Center(child: Text(errorMessage))),
                if (!isLoading &&
                    errorMessage.isEmpty &&
                    (dayPlans == null || dayPlans!.isEmpty))
                  const SliverFillRemaining(
                      child: Center(child: Text("No meal plan available"))),
                if (!isLoading &&
                    errorMessage.isEmpty &&
                    dayPlans != null &&
                    dayPlans!.isNotEmpty)
                  ..._buildMealPlanSlivers(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildHeader(BuildContext context) {
    const String imageUrl =
        'https://images.unsplash.com/photo-1484723091739-30a097e8f929?ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80&w=749';
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: ClipRRect(
          borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(40)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    Container(color: Colors.grey[300]),
                errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image, color: Colors.grey)),
              ),
              Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7)
                  ]))),
              AnimatedBuilder(
                animation: _scrollController,
                builder: (context, child) {
                  final offset = _scrollController.hasClients
                      ? _scrollController.offset
                      : 0;
                  return Transform.translate(
                      offset: Offset(0, offset * 0.5), child: child);
                },
                child: const SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Spacer(),
                        _AnimatedHeaderGreeting(
                            greeting: "Your Meal Plan",
                            subtitle: "A roadmap to a healthier week."),
                        Spacer()
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

  List<Widget> _buildMealPlanSlivers() {
    List<Widget> slivers = [];
    int animationIndex = 0;

    for (var dayPlan in dayPlans!) {
      slivers.add(
        SliverToBoxAdapter(
          child: _DayHeader(
            dayName: dayPlan.dayName,
            date: dayPlan.date,
            totalCalories: dayPlan.summary.calories,
            animationIndex: animationIndex++,
          ),
        ),
      );
      slivers.add(SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        sliver: SliverList.builder(
          itemCount: dayPlan.meals.length,
          itemBuilder: (context, index) {
            // --- MODIFIED: Determine Meal Type based on Index ---
            String mealType = 'Snack';
            if (index == 0) mealType = 'Breakfast';
            if (index == 1) mealType = 'Lunch';
            if (index == 2) mealType = 'Dinner';

            return StaggeredAnimation(
              index: animationIndex++,
              child: _MealCard(
                meal: dayPlan.meals[index],
                // Pass the determined mealType to the navigation function
                onTap: () => _navigateToDetails(dayPlan.meals[index], dayPlan.date, mealType),
              ),
            );
          },
        ),
      ));
    }
    return slivers;
  }
}

// --- WIDGETS ---

class _DayHeader extends StatelessWidget {
  final String dayName;
  final DateTime date;
  final int totalCalories;
  final int animationIndex;
  const _DayHeader(
      {required this.dayName,
      required this.date,
      required this.totalCalories,
      required this.animationIndex});

  String _formatDate(DateTime date) {
    const monthNames = [
      "",
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December"
    ];
    return '${monthNames[date.month]} ${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    return StaggeredAnimation(
      index: animationIndex,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(dayName[0].toUpperCase() + dayName.substring(1),
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800])),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 2.0),
              child: Text(_formatDate(date),
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500)),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 2.0),
              child: Text('$totalCalories kcal',
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  final MealInfo meal;
  final VoidCallback onTap;
  const _MealCard({required this.meal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textColor =
        const Color(0xFF3a5a64).withOpacity(meal.isLogged ? 0.6 : 1.0);

    // --- MODIFIED: Created a separate widget for the image to apply the filter ---
    final imageWidget = CachedNetworkImage(
      imageUrl: meal.imageUrl,
      width: 80,
      height: 80,
      fit: BoxFit.cover,
      placeholder: (context, url) =>
          Container(color: Colors.black.withOpacity(0.05)),
      errorWidget: (context, url, error) => Container(
          width: 80,
          height: 80,
          color: Colors.black.withOpacity(0.05),
          child: Icon(Icons.restaurant, color: Colors.grey[400])),
    );

    return _InteractiveCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12.0),
      child: RepaintBoundary(
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              // --- MODIFIED: Conditionally wrap the image with a ColorFiltered widget ---
              child: meal.isLogged
                  ? ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                        Colors.grey,
                        BlendMode.saturation,
                      ),
                      child: imageWidget,
                    )
                  : imageWidget,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(meal.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        decoration: meal.isLogged
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _NutrientInfo(
                          icon: Icons.local_fire_department_rounded,
                          value: '${meal.calories.toInt()} kcal',
                          color: Colors.orange.shade700,
                          textColor: textColor),
                      const SizedBox(width: 12),
                      _NutrientInfo(
                          icon: Icons.egg_outlined,
                          value: '${meal.protein.toInt()}g',
                          color: Colors.lightBlue.shade700,
                          textColor: textColor),
                    ],
                  ),
                ],
              ),
            ),
            if (meal.isLogged)
              const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Icon(Icons.check_circle, color: Colors.green))
          ],
        ),
      ),
    );
  }
}

class _NutrientInfo extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;
  final Color textColor;
  const _NutrientInfo(
      {required this.icon,
      required this.value,
      required this.color,
      required this.textColor});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: textColor.withOpacity(0.8))),
      ],
    );
  }
}

// --- THEME & ANIMATION HELPER WIDGETS ---
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
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 40))
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
      builder: (context, child) => Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors))),
    );
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
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
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
      ),
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
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        if (widget.onTap != null) widget.onTap!();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 15,
                    offset: const Offset(0, 5))
              ]),
          child: Container(
            padding: widget.padding,
            decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.85),
                    Colors.white.withOpacity(0.75)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: Colors.white.withOpacity(0.3))),
            child: widget.child,
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
    final delay = (widget.index * 50).clamp(0, 400);
    _opacity = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _slide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
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