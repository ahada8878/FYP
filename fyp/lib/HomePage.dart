import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'dart:math' as math;

class MealTrackingPage extends StatefulWidget {
  const MealTrackingPage({super.key});

  @override
  State<MealTrackingPage> createState() => _MealTrackingPageState();
}

class _MealTrackingPageState extends State<MealTrackingPage> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  int _currentIndex = 0;
  bool _showCameraPage = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _scaleAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          CustomScrollView(
            physics: _showCameraPage ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                floating: true,
                pinned: true,
                backgroundColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    'NutriTrack',
                    style: textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 10,
                          color: Colors.black.withOpacity(0.3),
                        ),
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
                            scale: 1 + (_animationController.value * 0.05),
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
                      AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _scaleAnimation.value,
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white,
                                    Colors.grey[50]!,
                                  ],
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildAnimatedMetricCircle(
                                    value: 0,
                                    label: 'Consumed',
                                    color: Colors.red[400]!,
                                    icon: Icons.local_fire_department,
                                    size: 90,
                                  ),
                                  _buildAnimatedMetricCircle(
                                    value: 2764,
                                    label: 'Remaining',
                                    color: Colors.green[400]!,
                                    icon: Icons.energy_savings_leaf,
                                    size: 110,
                                    isMain: true,
                                  ),
                                  _buildAnimatedMetricCircle(
                                    value: 0,
                                    label: 'Burned',
                                    color: Colors.orange[400]!,
                                    icon: Icons.directions_run,
                                    size: 90,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 30),
                      _SectionHeader(
                        title: 'Today\'s Meals', 
                        icon: Icons.restaurant,
                        color: colorScheme.primary,
                      ),
                      ..._buildAnimatedMealItems(),
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
          if (_showCameraPage) _buildCameraPageOverlay(),
        ],
      ),
      bottomNavigationBar: _buildCreativeBottomNavBar(colorScheme),
    );
  }

  Widget _buildCameraPageOverlay() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      bottom: _showCameraPage ? 0 : -MediaQuery.of(context).size.height * 0.7,
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
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.7),
                  ],
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
                      setState(() {
                        _showCameraPage = false;
                      });
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
                        Theme.of(context).primaryColor.withOpacity(0.3),
                        Theme.of(context).primaryColor.withOpacity(0.1),
                      ],
                    ),
                    border: Border.all(
                      color: Theme.of(context).primaryColor.withOpacity(0.5),
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
                        color: Theme.of(context).primaryColor,
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
                      onTap: () {},
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
                      onTap: () {},
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
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                  shadowColor: Theme.of(context).primaryColor.withOpacity(0.4),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.scanner, color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      'SCAN NOW',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _buildAnimatedMetricCircle({
    required int value,
    required String label,
    required Color color,
    required IconData icon,
    required double size,
    bool isMain = false,
  }) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final pulseValue = isMain 
            ? 1 + (_animationController.value * 0.05)
            : 1 + (_animationController.value * 0.02);
        
        return Transform.scale(
          scale: pulseValue,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      color.withOpacity(0.3),
                      color.withOpacity(0.1),
                    ],
                    stops: const [0.1, 1.0],
                  ),
                  border: Border.all(
                    color: color.withOpacity(0.8),
                    width: isMain ? 3 : 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: isMain ? 20 : 10,
                      spreadRadius: isMain ? 5 : 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon, 
                      color: color,
                      size: size * 0.3,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      value.toString(),
                      style: TextStyle(
                        fontSize: size * 0.25,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isMain ? FontWeight.bold : FontWeight.normal,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        );
      },
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
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
                        child: Icon(
                          meal['icon'] as IconData,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              meal['name'] as String,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              meal['calories'] as String,
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.add_circle,
                          color: Theme.of(context).primaryColor,
                          size: 30,
                        ),
                        onPressed: () {},
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: Stack(
                      children: [
                        Image.network(
                          recipe['image'] as String,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withOpacity(0.7),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 16,
                          left: 16,
                          child: Text(
                            recipe['title'] as String,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe['description'] as String,
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(Icons.local_fire_department, color: Colors.orange[400]),
                            const SizedBox(width: 4),
                            Text(recipe['calories'] as String),
                            const SizedBox(width: 16),
                            Icon(Icons.timer, color: Colors.blue[400]),
                            const SizedBox(width: 4),
                            Text(recipe['time'] as String),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {},
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  side: BorderSide(color: Theme.of(context).primaryColor),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Save Recipe',
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  backgroundColor: Theme.of(context).primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Cook Now'),
                              ),
                            ),
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

  Widget _buildCreativeBottomNavBar(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            spreadRadius: 3,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                if (index == 2) {
                  setState(() {
                    _showCameraPage = true;
                    _currentIndex = _currentIndex; // Maintain current index
                  });
                } else {
                  setState(() {
                    _currentIndex = index;
                    _showCameraPage = false;
                  });
                }
              },
              type: BottomNavigationBarType.fixed,
              backgroundColor: colorScheme.surface,
              selectedItemColor: colorScheme.primary,
              unselectedItemColor: colorScheme.onSurface.withOpacity(0.6),
              selectedLabelStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12 + (_animationController.value * 2),
              ),
              items: [
                _buildBottomNavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: 'Home',
                  isActive: _currentIndex == 0,
                ),
                _buildBottomNavItem(
                  icon: Icons.track_changes_outlined,
                  activeIcon: Icons.track_changes,
                  label: 'Track',
                  isActive: _currentIndex == 1,
                ),
                BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.primary,
                      border: Border.all(
                        color: colorScheme.surface,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  label: '',
                ),
                _buildBottomNavItem(
                  icon: Icons.restaurant_outlined,
                  activeIcon: Icons.restaurant,
                  label: 'Meals',
                  isActive: _currentIndex == 3,
                ),
                _buildBottomNavItem(
                  icon: Icons.person_outlined,
                  activeIcon: Icons.person,
                  label: 'Profile',
                  isActive: _currentIndex == 4,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildBottomNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isActive,
  }) {
    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive 
              ? Theme.of(context).primaryColor.withOpacity(0.2)
              : Colors.transparent,
        ),
        child: Icon(
          isActive ? activeIcon : icon,
          size: 24,
        ),
      ),
      label: label,
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