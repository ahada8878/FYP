import 'package:flutter/material.dart';
import 'package:fyp/HomePage.dart';
import 'package:fyp/screens/meal_plan_screen.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

class CustomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onItemSelected;
  final Function() onCameraPressed;
  final PersistentTabController tabController;

  const CustomNavBar({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
    required this.onCameraPressed, 
    required this.tabController,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PersistentTabView(
      context,
      controller: tabController,
      screens: _buildScreens(),
      items: _navBarsItems(context),
      backgroundColor: Colors.grey[50]!, // Non-null assertion
      navBarStyle: NavBarStyle.style12,
      navBarHeight: 70,
      margin: EdgeInsets.zero,
      decoration: NavBarDecoration(
        colorBehindNavBar: colorScheme.surface, // Correct parameter name
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            spreadRadius: 3,
          ),
        ],
      ),
      onItemSelected: (index) {
        if (index == 2) {
          onCameraPressed();
          tabController.index = tabController.index;
        } else {
          onItemSelected(index);
          
        }
      },
    );
  }

  List<Widget> _buildScreens() => [
    const MealTrackingPage(),
    const MealTrackingPage(),
    const MealTrackingPage(),
    const MealPlanScreen(),
    const MealTrackingPage(),
  ];

  List<PersistentBottomNavBarItem> _navBarsItems(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return [
      _buildNavItem(
        active: currentIndex == 0,
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        label: 'Home',
        colorScheme: colorScheme,
      ),
      _buildNavItem(
        active: currentIndex == 1,
        icon: Icons.track_changes_outlined,
        activeIcon: Icons.track_changes,
        label: 'Track',
        colorScheme: colorScheme,
      ),
      PersistentBottomNavBarItem(
        icon: Center(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.primary,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.camera_alt, color: Colors.white, size: 28),
          ),
        ),
        title: '',
        activeColorPrimary: colorScheme.primary,
        inactiveColorPrimary: colorScheme.primary,
      ),
      _buildNavItem(
        active: currentIndex == 3,
        icon: Icons.restaurant_outlined,
        activeIcon: Icons.restaurant,
        label: 'Meals',
        colorScheme: colorScheme,
      ),
      _buildNavItem(
        active: currentIndex == 4,
        icon: Icons.person_outlined,
        activeIcon: Icons.person,
        label: 'Profile',
        colorScheme: colorScheme,
      ),
    ];
  }

  PersistentBottomNavBarItem _buildNavItem({
    required bool active,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required ColorScheme colorScheme,
  }) {
    return PersistentBottomNavBarItem(
      icon: Icon(active ? activeIcon : icon, size: 28),
      title: label,
      activeColorPrimary: colorScheme.primary,
      inactiveColorPrimary: colorScheme.onSurface.withOpacity(0.6),
      textStyle: TextStyle(
        fontSize: 12,
        fontWeight: active ? FontWeight.w600 : FontWeight.w500,
      ),
    );
  }
}