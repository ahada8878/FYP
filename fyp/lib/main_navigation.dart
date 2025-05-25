// main_navigation.dart
import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:provider/provider.dart';
import 'camera_overlay_controller.dart';
import 'custom_nav_bar.dart';

class MainNavigationWrapper extends StatelessWidget {
  const MainNavigationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CameraOverlayController(),
      child: const _MainNavigationContent(),
    );
  }
}

class _MainNavigationContent extends StatefulWidget {
  const _MainNavigationContent();

  @override
  State<_MainNavigationContent> createState() => _MainNavigationContentState();
}

class _MainNavigationContentState extends State<_MainNavigationContent> {
  late final PersistentTabController _tabController ;

@override
  void initState() {
    super.initState();
    _tabController =context.read<PersistentTabController>() ;

  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomNavBar(
        currentIndex: _tabController.index,
        onItemSelected: (index) => setState(() {
          _tabController.index = index; // Update the tab controller
        }),
        onCameraPressed: () {
          _tabController.index = 0;
          
          // Show overlay after navigation completes
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<CameraOverlayController>().show();
          });
        }, tabController: _tabController,
      ),
    );
  }
}