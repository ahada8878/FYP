// user_meal_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:confetti/confetti.dart';

// --- SERVICE IMPORTS ---
import 'package:fyp/services/food_log_service.dart'; // For nutrient logging
import 'package:fyp/services/meal_service.dart';     // For updating meal plan status

// --- FINAL THEMED DESIGN SCREEN ---

class MealDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> meal;
  final DateTime date;
  final String mealType; 

  const MealDetailsScreen({
    super.key,
    required this.meal,
    required this.date,
    required this.mealType,
  });

  @override
  State<MealDetailsScreen> createState() => _MealDetailsScreenState();
}

class _MealDetailsScreenState extends State<MealDetailsScreen>
    with TickerProviderStateMixin {
  late AnimationController _macroAnimationController;
  late ConfettiController _confettiController;
  final ScrollController _scrollController = ScrollController();

  String? _selectedMacro;
  final Set<int> _checkedIngredients = {};

  @override
  void initState() {
    super.initState();
    _macroAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..forward();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 1));
  }

  @override
  void dispose() {
    _macroAnimationController.dispose();
    _confettiController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  void _onMacroSelected(String? macro) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedMacro = (_selectedMacro == macro) ? null : macro;
    });
  }

  void _onIngredientToggled(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_checkedIngredients.contains(index)) {
        _checkedIngredients.remove(index);
      } else {
        _checkedIngredients.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.meal['image'] ??
        "https://spoonacular.com/recipeImages/${widget.meal['id']}-636x393.jpg";
    final nutrients = widget.meal['nutrients'] as Map<String, dynamic>? ?? {};
    final rawIngredients = widget.meal['ingredients'] as List<dynamic>? ?? [];
    final instructionsList = (widget.meal['instructions'] as String? ?? '')
        .split(RegExp(r'\.\s+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final mealTitle = widget.meal['title'] ?? 'Meal Details';

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              _CreativeMagazineHeaderDelegate(
                imageUrl: imageUrl,
                mealTitle: mealTitle,
                nutrients: nutrients,
                servings: widget.meal['servings']?.toString() ?? '-',
                readyInMinutes:
                    widget.meal['readyInMinutes']?.toString() ?? '-',
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildCreativeSectionHeader(context,
                        title: 'Nutrition Profile',
                        icon: Icons.pie_chart_rounded),
                    _InteractiveMacroCard(
                        nutrients: nutrients,
                        animationController: _macroAnimationController,
                        selectedMacro: _selectedMacro,
                        onMacroSelected: _onMacroSelected),
                    const SizedBox(height: 24),
                    _buildCreativeSectionHeader(context,
                        title: 'Ingredients',
                        icon: Icons.shopping_basket_rounded),
                    _buildIngredientsSection(rawIngredients),
                    const SizedBox(height: 24),
                    _buildCreativeSectionHeader(context,
                        title: 'Instructions', icon: Icons.local_dining_rounded),
                    _buildInstructionsSection(instructionsList),
                  ]),
                ),
              ),
            ],
          ),
          // Only show log button if it's the current date
          if (isSameDate(widget.date, DateTime.now()))
            _AnimatedLogButton(
              meal: widget.meal,
              confettiController: _confettiController,
              mealType: widget.mealType,
            ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                emissionFrequency: 0.05,
                numberOfParticles: 25),
          ),
        ],
      ),
    );
  }

  Widget _buildCreativeSectionHeader(BuildContext context,
      {required String title, required IconData icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold, color: Colors.grey[800])),
        ],
      ),
    );
  }

  Widget _buildIngredientsSection(List<dynamic> ingredients) {
    return Column(
      children: ingredients.asMap().entries.map((entry) {
        final index = entry.key;
        final ingredientData = entry.value as Map<String, dynamic>;
        final isChecked = _checkedIngredients.contains(index);

        return _InteractiveIngredientTile(
          key: ValueKey(index),
          ingredientData: ingredientData,
          capitalize: _capitalize,
          isChecked: isChecked,
          onTap: () => _onIngredientToggled(index),
        );
      }).toList(),
    );
  }

  Widget _buildInstructionsSection(List<String> instructions) {
    final displayInstructions =
        instructions.isNotEmpty ? instructions : ['No instructions available.'];
    return _InteractiveCard(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: displayInstructions
            .asMap()
            .entries
            .map((entry) => _InstructionStep(
                index: entry.key,
                instruction: entry.value,
                isLast: entry.key == displayInstructions.length - 1))
            .toList(),
      ),
    );
  }
}

class _CreativeMagazineHeaderDelegate extends SliverPersistentHeader {
  final String imageUrl, mealTitle, servings, readyInMinutes;
  final Map<String, dynamic> nutrients;
  _CreativeMagazineHeaderDelegate({
    required this.imageUrl,
    required this.mealTitle,
    required this.nutrients,
    required this.servings,
    required this.readyInMinutes,
  }) : super(
            pinned: true,
            delegate: _HeaderDelegate(
              imageUrl: imageUrl,
              mealTitle: mealTitle,
              nutrients: nutrients,
              servings: servings,
              readyInMinutes: readyInMinutes,
              minExtent: kToolbarHeight + 40,
              maxExtent: 400,
            ));
}

class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  final String imageUrl, mealTitle, servings, readyInMinutes;
  final Map<String, dynamic> nutrients;
  @override
  final double minExtent;
  @override
  final double maxExtent;
  _HeaderDelegate({
    required this.imageUrl,
    required this.mealTitle,
    required this.nutrients,
    required this.servings,
    required this.readyInMinutes,
    required this.minExtent,
    required this.maxExtent,
  });

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final progress = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final primaryColor = Theme.of(context).colorScheme.primary;

    final blurredImageOpacity = 1.0 - progress * 2;
    final titleCardTop = lerpDouble(200, 0, progress)!;
    final titleCardHorizontalPadding = lerpDouble(24, 60, progress)!;
    final titleFontSize = lerpDouble(36, 20, progress)!;
    final mainImageScale = lerpDouble(1.0, 0.0, progress)!;
    final mainImageTop = lerpDouble(100, 0, progress)!;
    final statsOpacity = (1.0 - progress * 1.5).clamp(0.0, 1.0);
    final collapsedTitleOpacity = (progress - 0.5) * 2;

    return Stack(fit: StackFit.expand, children: [
      Opacity(
          opacity: blurredImageOpacity.clamp(0.0, 1.0),
          child: CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover)),
      ClipRRect(
          child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.black.withOpacity(0.2)))),
      Positioned(
          top: mainImageTop,
          left: 0,
          right: 0,
          child: Transform.scale(
              scale: mainImageScale,
              child: Container(
                  height: 200,
                  margin: const EdgeInsets.symmetric(horizontal: 60),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5)
                      ],
                      image: DecorationImage(
                          image: CachedNetworkImageProvider(imageUrl),
                          fit: BoxFit.cover))))),
      Positioned(
          top: titleCardTop,
          left: 0,
          right: 0,
          child: Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: titleCardHorizontalPadding),
              child: Column(children: [
                _GlassCard(
                    child: Text(mealTitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.2),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis)),
                const SizedBox(height: 16),
                Opacity(
                    opacity: statsOpacity,
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _StatChip(
                              icon: Icons.local_fire_department_rounded,
                              label:
                                  '${nutrients['calories'] ?? '-'} kcal'),
                          _StatChip(
                              icon: Icons.access_time_filled_rounded,
                              label: '$readyInMinutes min'),
                          _StatChip(
                              icon: Icons.groups_2_rounded,
                              label: '$servings serv'),
                        ]))
              ]))),
      Container(
          height: minExtent,
          color: primaryColor.withOpacity(progress),
          child: SafeArea(
              child: Opacity(
                  opacity: collapsedTitleOpacity.clamp(0.0, 1.0),
                  child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Align(
                          alignment: Alignment.center,
                          child: Text(mealTitle,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis)))))),
    ]);
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}

class _InteractiveIngredientTile extends StatefulWidget {
  final Map<String, dynamic> ingredientData;
  final bool isChecked;
  final VoidCallback onTap;
  final String Function(String) capitalize;

  const _InteractiveIngredientTile({
    super.key,
    required this.ingredientData,
    required this.isChecked,
    required this.onTap,
    required this.capitalize,
  });

  @override
  State<_InteractiveIngredientTile> createState() =>
      _InteractiveIngredientTileState();
}

class _InteractiveIngredientTileState
    extends State<_InteractiveIngredientTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final String name = widget.ingredientData['name'] ?? '';
    final String amount = (widget.ingredientData['amount'] ?? '').toString();
    final String unit = widget.ingredientData['unit'] ?? '';
    final String imageUrl =
        'https://spoonacular.com/cdn/ingredients_500x500/${name.replaceAll(' ', '-')}';
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            height: _isExpanded ? 120 : 60,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ]),
            child: Stack(fit: StackFit.expand, children: [
              // Frosted Glass background (visible when collapsed)
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _isExpanded ? 0.0 : 1.0,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.65),
                      border:
                          Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                  ),
                ),
              ),
              // Image background (visible when expanded)
              AnimatedOpacity(
                duration: const Duration(milliseconds: 500),
                opacity: _isExpanded ? 1.0 : 0.0,
                child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) =>
                        Container(color: Colors.grey.shade200)),
              ),
              // Color overlay (visible when expanded)
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                decoration: BoxDecoration(
                  color: _isExpanded
                      ? primaryColor.withOpacity(0.7)
                      : Colors.white.withOpacity(0.45),
                ),
              ),
              // Main Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 300),
                            style: TextStyle(
                                color: _isExpanded
                                    ? Colors.white
                                    : Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                            child: Text(widget.capitalize(name)),
                          ),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 300),
                            style: TextStyle(
                                color: _isExpanded
                                    ? Colors.white70
                                    : Colors.grey.shade600,
                                fontSize: 14),
                            child: Text("$amount $unit".trim()),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.onTap,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 500),
                        opacity: _isExpanded ? 1.0 : 0.0,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: widget.isChecked
                                    ? Colors.transparent
                                    : Colors.white,
                                width: 2),
                            color: widget.isChecked
                                ? primaryColor
                                : Colors.transparent,
                          ),
                          child: widget.isChecked
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 18)
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ... All other helper widgets remain below
class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _InteractiveMacroCard extends StatelessWidget {
  final Map<String, dynamic> nutrients;
  final AnimationController animationController;
  final String? selectedMacro;
  final ValueChanged<String?> onMacroSelected;

  const _InteractiveMacroCard({
    required this.nutrients,
    required this.animationController,
    required this.selectedMacro,
    required this.onMacroSelected,
  });

  @override
  Widget build(BuildContext context) {
    final double carbs = (nutrients['carbs'] as num?)?.toDouble() ?? 0.0;
    final double protein = (nutrients['protein'] as num?)?.toDouble() ?? 0.0;
    final double fat = (nutrients['fat'] as num?)?.toDouble() ?? 0.0;
    final total = carbs + protein + fat;
    final double carbsPercent = total == 0 ? 0 : carbs / total;
    final double proteinPercent = total == 0 ? 0 : protein / total;
    final double fatPercent = total == 0 ? 0 : fat / total;
    String centerText = 'Macros';
    if (selectedMacro == 'Carbs')
      centerText = '${(carbsPercent * 100).toInt()}%';
    if (selectedMacro == 'Protein')
      centerText = '${(proteinPercent * 100).toInt()}%';
    if (selectedMacro == 'Fat')
      centerText = '${(fatPercent * 100).toInt()}%';

    return _InteractiveCard(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: GestureDetector(
              onTap: () => onMacroSelected(null),
              child: CustomPaint(
                painter: _MacroRingsPainter(
                    animation: animationController,
                    carbsPercent: carbsPercent,
                    proteinPercent: proteinPercent,
                    fatPercent: fatPercent,
                    selectedMacro: selectedMacro),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) =>
                        FadeTransition(opacity: animation, child: child),
                    child: Text(centerText,
                        key: ValueKey<String>(centerText),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFF333333))),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MacroLegend(
                    label: 'Carbs',
                    grams: carbs,
                    percent: carbsPercent,
                    isSelected: selectedMacro == 'Carbs',
                    color: Colors.orange,
                    onTap: () => onMacroSelected('Carbs')),
                const SizedBox(height: 12),
                _MacroLegend(
                    label: 'Protein',
                    grams: protein,
                    percent: proteinPercent,
                    isSelected: selectedMacro == 'Protein',
                    color: Colors.lightBlue,
                    onTap: () => onMacroSelected('Protein')),
                const SizedBox(height: 12),
                _MacroLegend(
                    label: 'Fat',
                    grams: fat,
                    percent: fatPercent,
                    isSelected: selectedMacro == 'Fat',
                    color: Colors.purple,
                    onTap: () => onMacroSelected('Fat')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedLogButton extends StatefulWidget {
  final Map<String, dynamic> meal;
  final ConfettiController confettiController;
  final String mealType;

  const _AnimatedLogButton({
    required this.meal,
    required this.confettiController,
    required this.mealType,
  });

  @override
  State<_AnimatedLogButton> createState() => _AnimatedLogButtonState();
}

class _AnimatedLogButtonState extends State<_AnimatedLogButton> {
  int _buttonState = 0; // 0: Idle, 1: Loading, 2: Success
  bool _isAlreadyLogged = false;
  final FoodLogService _foodLogService = FoodLogService();

  @override
  void initState() {
    super.initState();
    _isAlreadyLogged = widget.meal['loggedAt'] != null;
  }

  // --- UPDATED: Logs to BOTH Food Log AND Meal Plan Backend ---
  Future<void> _handleLog() async {
    if (_buttonState != 0 || _isAlreadyLogged) return;

    HapticFeedback.lightImpact();
    setState(() => _buttonState = 1);

    try {
      // 1. Log to Food Log (Nutrients & Diary)
      final nutrients = widget.meal['nutrients'] as Map<String, dynamic>? ?? {};
      final imageUrl = widget.meal['image'] ??
          "https://spoonacular.com/recipeImages/${widget.meal['id']}-636x393.jpg";
      final title = widget.meal['title'] ?? 'Meal';

      final backendNutrients = {
        'calories': nutrients['calories'] ?? 0,
        'protein': nutrients['protein'] ?? 0,
        'fat': nutrients['fat'] ?? 0,
        'carbohydrates': nutrients['carbs'] ?? 0,
      };

      final bool foodLogSuccess = await _foodLogService.logFood(
        mealType: widget.mealType,
        productName: title,
        nutrients: backendNutrients,
        imageUrl: imageUrl,
        date: DateTime.now(),
      );

      if (!foodLogSuccess) {
        throw Exception('Failed to add to food log');
      }

      // 2. Update Meal Plan Status in Backend (Set loggedAt)
      // This matches the previous implementation using MealService
      await MealService.logMeal(widget.meal['id'] as int);

      // Success
      widget.confettiController.play();
      setState(() => _buttonState = 2);
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) Navigator.pop(context, true);

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
        setState(() => _buttonState = 0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final screenWidth = MediaQuery.of(context).size.width;
    final double buttonWidth = _buttonState == 1 ? 56 : screenWidth - 48;

    // --- DISABLED BUTTON STATE (If already logged) ---
    if (_isAlreadyLogged) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Container(
            width: screenWidth - 48,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Center(
              child: Text(
                'Log as ${widget.mealType}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // --- ACTIVE BUTTON STATE ---
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFF0F2F5).withOpacity(0.0),
              const Color(0xFFF0F2F5).withOpacity(0.9),
              const Color(0xFFF0F2F5)
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: InkWell(
          onTap: _handleLog,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            width: buttonWidth,
            height: 56,
            decoration: BoxDecoration(
              color: _buttonState == 2 ? Colors.green : primaryColor,
              borderRadius:
                  BorderRadius.circular(_buttonState == 1 ? 28.0 : 16.0),
              boxShadow: [
                BoxShadow(
                    color: (_buttonState == 2 ? Colors.green : primaryColor)
                        .withOpacity(0.4),
                    blurRadius: 10,
                    spreadRadius: 1,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: _buildButtonChild(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButtonChild() {
    if (_buttonState == 0)
      return Text('Log as ${widget.mealType}',
          key: const ValueKey('text'),
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white));
    if (_buttonState == 1)
      return const SizedBox(
          key: ValueKey('spinner'),
          height: 24,
          width: 24,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white));
    return const Icon(Icons.check_circle_rounded,
        key: ValueKey('icon'), color: Colors.white, size: 28);
  }
}

class _InstructionStep extends StatelessWidget {
  final int index;
  final String instruction;
  final bool isLast;

  const _InstructionStep(
      {required this.index, required this.instruction, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.orange.withOpacity(0.2),
                  child: Text('${index + 1}',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800))),
              if (!isLast)
                Expanded(
                    child:
                        Container(width: 2, color: Colors.orange.withOpacity(0.2))),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
              child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
                  child: Text(instruction,
                      style: TextStyle(
                          color: Colors.grey[800], fontSize: 15, height: 1.5)))),
        ],
      ),
    );
  }
}

class _MacroRingsPainter extends CustomPainter {
  final Animation<double> animation;
  final double carbsPercent, proteinPercent, fatPercent;
  final String? selectedMacro;

  _MacroRingsPainter(
      {required this.animation,
      required this.carbsPercent,
      required this.proteinPercent,
      required this.fatPercent,
      this.selectedMacro})
      : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final strokeWidth = 10.0;
    final progress = Curves.easeInOutCubic.transform(animation.value);

    void drawArc(String label, double percent, Color color, double radius) {
      final bool isSelected = selectedMacro == label;
      final bool isDimmed = selectedMacro != null && !isSelected;
      final paint = Paint()
        ..color = color.withOpacity(isDimmed ? 0.3 : 1.0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? strokeWidth * 1.2 : strokeWidth
        ..strokeCap = StrokeCap.round;
      final backgroundPaint = Paint()
        ..color = color.withOpacity(isDimmed ? 0.05 : 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
          -math.pi / 2, 2 * math.pi, false, backgroundPaint);
      canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          -math.pi / 2,
          2 * math.pi * percent * progress,
          false,
          paint);
    }

    drawArc('Carbs', carbsPercent, Colors.orange,
        size.width / 2 - strokeWidth * 0.5);
    drawArc('Protein', proteinPercent, Colors.lightBlue,
        size.width / 2 - strokeWidth * 1.8);
    drawArc('Fat', fatPercent, Colors.purple,
        size.width / 2 - strokeWidth * 3.1);
  }

  @override
  bool shouldRepaint(covariant _MacroRingsPainter oldDelegate) => true;
}

class _MacroLegend extends StatelessWidget {
  final String label;
  final Color color;
  final double grams, percent;
  final bool isSelected;
  final VoidCallback onTap;

  const _MacroLegend(
      {required this.label,
      required this.color,
      required this.grams,
      required this.percent,
      required this.isSelected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: isSelected ? 1.0 : 0.8,
        child: Row(
          children: [
            Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Color(0xFF333333))),
            const Spacer(),
            Text('${grams.toStringAsFixed(1)}g',
                style: TextStyle(color: Colors.grey[800])),
            const SizedBox(width: 8),
            SizedBox(
              width: 45,
              child: Text('${(percent * 100).toInt()}%',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                      color: color)),
            ),
          ],
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98)
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
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 15,
                  spreadRadius: -5,
                  offset: const Offset(0, 5))
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24.0),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: widget.padding,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.65),
                    border: Border.all(color: Colors.white.withOpacity(0.3))),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}