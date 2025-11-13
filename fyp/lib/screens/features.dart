import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart'; // Import the package

// Preserved original imports for your feature pages
import 'Features/meal_planner_page.dart';
import 'Features/label_scanner_page.dart';
import 'Features/cravings_page.dart';
import 'Features/nutrition_tips_page.dart';
import 'Features/recipe_suggestions.dart';


// --- Main Features Page Widget ---
class Features extends StatefulWidget {
  const Features({super.key});

  @override
  State<Features> createState() => _FeaturesPageState();
}

class _FeaturesPageState extends State<Features> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _navigateToPage(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white.withOpacity(0.65),
      body: Stack(
        children: [
          const _LivingAnimatedBackground(),
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildHeader(context),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
                sliver: _buildFeaturesList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildHeader(BuildContext context) {
    const String imageUrl = 'https://plus.unsplash.com/premium_photo-1670601440146-3b33dfcd7e17?ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80&w=1238';

    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: ClipRRect(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 1.0, end: 1.15),
                duration: const Duration(seconds: 25),
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: child,
                  );
                },
                // --- IMAGE WIDGET REPLACED HERE ---
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  // Placeholder while the image is loading
                  placeholder: (context, url) => Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  // Widget to show if the image fails to load
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.broken_image,
                      color: Colors.grey,
                      size: 60,
                    ),
                  ),
                ),
              ),
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
              AnimatedBuilder(
                animation: _scrollController,
                builder: (context, child) {
                  final offset = _scrollController.hasClients ? _scrollController.offset : 0;
                  return Transform.translate(
                    offset: Offset(0, offset * 0.5),
                    child: child,
                  );
                },
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Spacer(),
                        _AnimatedHeaderGreeting(
                          greeting: "Explore Features",
                          subtitle: "Good food is an investment in your well-being.",
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

  Widget _buildFeaturesList() {
    final features = [
      {'title': 'Recipe Suggestions', 'icon': Icons.restaurant_menu, 'color': Colors.blue, 'subtitle': 'Use Ingredients smartly', 'page': const RecipeSuggestion()},
      {'title': 'Label Scanner', 'icon': Icons.qr_code_scanner_rounded, 'color': Colors.green, 'subtitle': 'Analyze your groceries', 'page': const LabelScannerPage()},
      {'title': 'Craving Hunt', 'icon': Icons.food_bank_outlined, 'color': Colors.orange, 'subtitle': 'Find healthy alternatives', 'page': const CravingsPage()},
      {'title': 'Nutrition Tips', 'icon': Icons.lightbulb_outline_rounded, 'color': Colors.purple, 'subtitle': 'Get expert advice daily', 'page': const NutritionTipsPage()},
      {'title': 'Community', 'icon': Icons.people_alt_outlined, 'color': Colors.red, 'subtitle': 'Connect and share your journey', 'page': const MealPlannerPage()},
    ];

    return SliverList(
      delegate: SliverChildListDelegate([
        _buildSectionHeader(context, "How We Can Help"),
        const SizedBox(height: 8),
        ...List.generate(features.length, (index) {
          final feature = features[index];
          return StaggeredAnimation(
            index: index,
            child: _InteractiveCard(
              onTap: () => _navigateToPage(feature['page'] as Widget),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (feature['color'] as Color).withOpacity(0.15)
                    ),
                    child: Center(
                      child: Icon(
                        feature['icon'] as IconData,
                        color: feature['color'] as Color,
                        size: 22
                      )
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          feature['title'] as String,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF333333))
                        ),
                        const SizedBox(height: 4),
                        Text(
                          feature['subtitle'] as String,
                          style: TextStyle(color: Colors.grey[800], fontSize: 13)
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: Colors.black.withOpacity(0.7), size: 16),
                ],
              ),
            ),
          );
        }),
      ]),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return StaggeredAnimation(
      index: 0,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16, top: 8),
        child: Center(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[800]
            )
          ),
        ),
      ),
    );
  }
}

// --- ALL HELPER WIDGETS ---

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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = [
      Color.lerp(const Color(0xffa8edea), const Color(0xfffed6e3), _controller.value)!,
      Color.lerp(const Color(0xfffed6e3), const Color(0xffa8edea), _controller.value)!,
    ];
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
          ),
        );
      }
    );
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
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70)),
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