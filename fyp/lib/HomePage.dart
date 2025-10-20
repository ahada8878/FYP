import 'package:flutter/material.dart';
import 'package:fyp/Widgets/activity_log_sheet.dart';
import 'package:fyp/Widgets/calorie_summary_carousel.dart';
import 'package:fyp/Widgets/log_food_sheet.dart';
import 'package:fyp/Widgets/log_water_overlay.dart';
import 'package:fyp/Widgets/water_tracker.dart';
import 'package:fyp/screens/camera_screen.dart';
import 'package:fyp/screens/describe_meal_screen.dart';
import 'package:fyp/screens/ai_scanner_result_page.dart';
import 'package:fyp/screens/settings_screen.dart'; // Import the settings screen
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:math' as math;
import 'camera_overlay_controller.dart';

class MealTrackingPage extends StatefulWidget {
  const MealTrackingPage({super.key});

  @override
  State<MealTrackingPage> createState() => _MealTrackingPageState();
}

class _MealTrackingPageState extends State<MealTrackingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  Future<void> _openCameraScreen() async {
    Provider.of<CameraOverlayController>(context, listen: false).hide();
    final imagePath = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const CameraScreen()),
    );
    if (imagePath != null) {
      final imageFile = File(imagePath);
      _navigateToResultPage(imageFile, true);
    }
  }

  void _navigateToResultPage(File imageFile, bool fromCamera) {
    Provider.of<CameraOverlayController>(context, listen: false).hide();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AiScannerResultPage(
          imageFile: imageFile,
          fromCamera: fromCamera,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final overlayController = Provider.of<CameraOverlayController>(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          CustomScrollView(
            physics: overlayController.showOverlay
                ? const NeverScrollableScrollPhysics()
                : const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                floating: true,
                pinned: true,
                backgroundColor: Colors.transparent,
                // *** ACTION ICON TO OPEN SETTINGS ***
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 28),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsScreen()),
                      );
                    },
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    'NutriWise',
                    style: textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 10,
                          color: Colors.black.withOpacity(0.3),
                        )
                      ],
                    ),
                  ),
                  centerTitle: true,
                  background: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.primary,
                              colorScheme.primary.withOpacity(0.7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _scaleAnimation.value,
                            child: Opacity(
                              opacity: 0.3,
                              child: Center(
                                child: Icon(
                                  Icons.restaurant,
                                  size: 150,
                                  color: Colors.white.withOpacity(0.5),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const CalorieSummaryCarousel(),
                      const SizedBox(height: 30),
                      _SectionHeader(
                        title: 'Today\'s Meals',
                        icon: Icons.restaurant,
                        color: colorScheme.primary,
                      ),
                      ..._buildAnimatedMealItems(),
                      const SizedBox(height: 30),
                      _SectionHeader(
                        title: 'Water Tracker',
                        icon: Icons.local_drink,
                        color: colorScheme.primary,
                      ),
                      const WaterTracker(),
                      const SizedBox(height: 30),
                      _SectionHeader(
                        title: 'Recommended Recipes',
                        icon: Icons.local_dining,
                        color: colorScheme.primary,
                      ),
                      ..._buildAnimatedRecipePosts(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (overlayController.showOverlay) _buildCameraPageOverlay(),
        ],
      ),
    );
  }

  Widget _buildCameraPageOverlay() {
    final overlayController = Provider.of<CameraOverlayController>(context);
    // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('hehehaha')));
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      bottom: overlayController.showOverlay ? 0 : -MediaQuery.of(context).size.height * 0.7,
      left: 0,
      right: 0,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary,
                    colorScheme.primary.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'AI Scanner',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      overlayController.hide();
                      if (context.read<PersistentTabController>().index != 0) {
                        context.read<PersistentTabController>().index = 0;
                      }
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: ScannerPulseAnimation(
                child: Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        colorScheme.primary.withOpacity(0.3),
                        colorScheme.primary.withOpacity(0.1),
                      ],
                    ),
                    border: Border.all(
                      color: colorScheme.primary.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: AnimatedRotation(
                      duration: const Duration(seconds: 8),
                      turns: _animationController.value * 2,
                      child: Icon(
                        Icons.auto_awesome,
                        size: 40,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ListView(
                  children: [
                    AnimatedScannerButton(
                      icon: Icons.chat_bubble_outline,
                      text: 'Describe Meal to AI',
                      subtitle: 'Get nutritional analysis by description',
                      color: Colors.blue,
                      delay: 100,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DescribeMealScreen(),
                          ),
                        );
                      },
                    ),
                    AnimatedScannerButton(
                      icon: Icons.bookmark_border,
                      text: 'Saved Meals',
                      subtitle: 'Your frequently logged meals',
                      color: Colors.green,
                      delay: 200,
                      onTap: () {},
                    ),
                    AnimatedScannerButton(
                      icon: Icons.local_drink_outlined,
                      text: 'Log Water',
                      subtitle: 'Track your daily water intake',
                      color: Colors.lightBlue,
                      delay: 300,
                      onTap: () {
                        Provider.of<CameraOverlayController>(context, listen: false).hide();
                        showLogWaterOverlay(context);
                      },
                    ),
                    AnimatedScannerButton(
                      icon: Icons.monitor_weight_outlined,
                      text: 'Log Weight',
                      subtitle: 'Update your current weight',
                      color: Colors.orange,
                      delay: 400,
                      onTap: () {},
                    ),
                    AnimatedScannerButton(
                      icon: Icons.directions_run,
                      text: 'Log Activity',
                      subtitle: 'Add exercise or physical activity',
                      color: Colors.red,
                      delay: 500,
                      onTap: () {
                        Provider.of<CameraOverlayController>(context, listen: false).hide();
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => const ActivityLogSheet(),
                        ).then((selectedActivity) {
                          if (selectedActivity != null) {
                            // ignore: avoid_print
                            print('Logged activity: ${selectedActivity.name}');
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: _openCameraScreen,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 5,
                  shadowColor: colorScheme.primary.withOpacity(0.4),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.scanner, color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      'SCAN NOW',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAnimatedMealItems() {
    final meals = [
      {'name': 'Breakfast', 'calories': '0/691 kcal', 'icon': Icons.breakfast_dining},
      {'name': 'Lunch', 'calories': '0/968 kcal', 'icon': Icons.lunch_dining},
      {'name': 'Dinner', 'calories': '0/968 kcal', 'icon': Icons.dinner_dining},
      {'name': 'Snacks', 'calories': '0/138 kcal', 'icon': Icons.cookie},
    ];

    return meals.map((meal) {
      return AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, math.sin(_animationController.value * math.pi * 2) * 2),
            child: Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {},
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).primaryColor.withOpacity(0.2),
                              Theme.of(context).primaryColor.withOpacity(0.1),
                            ],
                          ),
                        ),
                        child: Icon(meal['icon'] as IconData, color: Theme.of(context).primaryColor),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(meal['name'] as String, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(meal['calories'] as String, style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add_circle, color: Theme.of(context).primaryColor, size: 30),
                        onPressed: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => const LogFoodSheet(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    }).toList();
  }

  List<Widget> _buildAnimatedRecipePosts() {
    final recipePosts = [
      {
        'title': 'Mediterranean Salad',
        'image': 'https://images.pexels.com/photos/1279330/pexels-photo-1279330.jpeg',
        'description': 'Fresh and healthy salad with olives, feta, and vegetables',
        'calories': '320 kcal',
        'time': '15 min'
      },
      {
        'title': 'Avocado Toast',
        'image': 'https://images.pexels.com/photos/2144112/pexels-photo-2144112.jpeg',
        'description': 'Creamy avocado on whole grain bread with cherry tomatoes',
        'calories': '280 kcal',
        'time': '10 min'
      }
    ];

    return recipePosts.map((recipe) {
      return AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: 0.98 + (_animationController.value * 0.04),
            child: Card(
              margin: const EdgeInsets.only(bottom: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: Stack(
                      children: [
                        Image.network(recipe['image'] as String, height: 200, width: double.infinity, fit: BoxFit.cover),
                        Positioned(bottom: 0, left: 0, right: 0, child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                            ),
                          ),
                        )),
                        Positioned(bottom: 16, left: 16, child: Text(
                          recipe['title'] as String,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        )),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(recipe['description'] as String, style: TextStyle(color: Colors.grey[600])),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(Icons.local_fire_department, color: Colors.orange[400]),
                            const SizedBox(width: 4), Text(recipe['calories'] as String),
                            const SizedBox(width: 16),
                            Icon(Icons.timer, color: Colors.blue[400]),
                            const SizedBox(width: 4), Text(recipe['time'] as String),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: OutlinedButton(
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: BorderSide(color: Theme.of(context).primaryColor),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text('Save Recipe', style: TextStyle(color: Theme.of(context).primaryColor)),
                            )),
                            const SizedBox(width: 16),
                            Expanded(child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                backgroundColor: Theme.of(context).primaryColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Cook Now'),
                            )),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }).toList();
  }
}

// Keep all the existing supporting animation widget classes...
// [ShimmeringIcon, FadeInAnimation, ScaleAnimation, SlideInAnimation, AnimatedButton, _SectionHeader, AnimatedScannerButton, ScannerPulseAnimation]
// They remain exactly the same as in your original code

// Supporting Animation Widgets

class ShimmeringIcon extends StatefulWidget {
  final IconData icon;
  final double size;
  final Color color;

  const ShimmeringIcon({
    super.key,
    required this.icon,
    required this.size,
    required this.color,
  });

  @override
  State<ShimmeringIcon> createState() => _ShimmeringIconState();
}

class _ShimmeringIconState extends State<ShimmeringIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _opacityAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Icon(
            widget.icon,
            size: widget.size,
            color: widget.color,
          ),
        );
      },
    );
  }
}

class FadeInAnimation extends StatefulWidget {
  final Widget child;
  final int delay;

  const FadeInAnimation({
    super.key,
    required this.child,
    required this.delay,
  });

  @override
  State<FadeInAnimation> createState() => _FadeInAnimationState();
}

class _FadeInAnimationState extends State<FadeInAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: widget.child,
    );
  }
}

class ScaleAnimation extends StatefulWidget {
  final Widget child;
  final int delay;

  const ScaleAnimation({
    super.key,
    required this.child,
    required this.delay,
  });

  @override
  State<ScaleAnimation> createState() => _ScaleAnimationState();
}

class _ScaleAnimationState extends State<ScaleAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: widget.child,
    );
  }
}

class SlideInAnimation extends StatefulWidget {
  final Widget child;
  final int delay;

  const SlideInAnimation({
    super.key,
    required this.child,
    required this.delay,
  });

  @override
  State<SlideInAnimation> createState() => _SlideInAnimationState();
}

class _SlideInAnimationState extends State<SlideInAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: widget.child,
    );
  }
}

class AnimatedButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;

  const AnimatedButton({
    super.key,
    required this.onPressed,
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
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
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: widget.backgroundColor.withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: widget.iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.2),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedScannerButton extends StatefulWidget {
  final IconData icon;
  final String text;
  final String subtitle;
  final Color color;
  final int delay;
  final VoidCallback onTap;

  const AnimatedScannerButton({
    super.key,
    required this.icon,
    required this.text,
    required this.subtitle,
    required this.color,
    required this.delay,
    required this.onTap,
  });

  @override
  State<AnimatedScannerButton> createState() => _AnimatedScannerButtonState();
}

class _AnimatedScannerButtonState extends State<AnimatedScannerButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.5, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 50, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1, curve: Curves.easeOutBack),
      ),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.translate(
            offset: Offset(_slideAnimation.value, 0),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              widget.color.withOpacity(0.1),
              Colors.transparent,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  widget.color.withOpacity(0.3),
                  widget.color.withOpacity(0.1),
                ],
              ),
            ),
            child: Icon(widget.icon, color: widget.color),
          ),
          title: Text(
            widget.text,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            widget.subtitle,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: Colors.grey[400],
          ),
          onTap: widget.onTap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }
}

class ScannerPulseAnimation extends StatefulWidget {
  final Widget child;

  const ScannerPulseAnimation({super.key, required this.child});

  @override
  State<ScannerPulseAnimation> createState() => _ScannerPulseAnimationState();
}

class _ScannerPulseAnimationState extends State<ScannerPulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.8, end: 1).animate(
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
