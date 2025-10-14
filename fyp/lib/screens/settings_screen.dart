import 'package:flutter/material.dart';
import 'package:fyp/main.dart'; // Needed to restart the app
import 'package:fyp/services/auth_service.dart';
import 'dart:ui'; // Needed for BackdropFilter

// --- Main Settings Screen Widget ---

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    // Define text styles for consistency
    final titleStyle = TextStyle(
      color: Colors.grey[800],
      fontWeight: FontWeight.w600,
      fontSize: 16,
    );
    final valueStyle = TextStyle(
      color: Colors.grey[600],
      fontSize: 15,
    );

    return Scaffold(
      body: Stack(
        children: [
          // The same animated background from the homepage for a consistent theme
          const _LivingAnimatedBackground(),

          // Use a CustomScrollView for better control over scrolling elements
          CustomScrollView(
            slivers: [
              SliverAppBar(
                title: const Text('Settings'),
                titleTextStyle: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
                backgroundColor: Colors.transparent, // Make app bar see-through
                elevation: 0,
                pinned: true,
                centerTitle: true,
              ),

              // Add padding to the main content list
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // --- System Section ---
                    _buildSectionHeader('System'),
                    _SettingsCard(
                      child: Column(
                        children: [
                          ListTile(
                            title: Text('Current Weight', style: titleStyle),
                            trailing: Text('82.0 kg', style: valueStyle),
                          ),
                          const _StyledDivider(),
                          ListTile(
                            title: Text('Target Weight', style: titleStyle),
                            trailing: Text('76.0 kg', style: valueStyle),
                          ),
                          const _StyledDivider(),
                          ListTile(
                            title: Text('Height', style: titleStyle),
                            trailing: Text('6.0 ft', style: valueStyle),
                          ),
                           const _StyledDivider(),
                           ListTile(
                            title: Text('Gender', style: titleStyle),
                            trailing: Text('Male', style: valueStyle),
                          ),
                          const _StyledDivider(),
                           ListTile(
                            title: Text('Water Goal', style: titleStyle),
                            trailing: Text('2.00 L', style: valueStyle),
                          ),
                        ],
                      ),
                    ),

                    // --- Notifications Section ---
                    _buildSectionHeader('Notifications'),
                    _SettingsCard(
                      child: SwitchListTile(
                        title: Text('Enable Notifications', style: titleStyle),
                        value: _notificationsEnabled,
                        onChanged: (value) {
                          setState(() => _notificationsEnabled = value);
                        },
                        activeColor: Theme.of(context).colorScheme.primary,
                      ),
                    ),

                    // --- Support Section ---
                     _buildSectionHeader('Support'),
                    _SettingsCard(
                      child: Column(
                        children: [
                          ListTile(
                            title: Text('Rate us', style: titleStyle),
                            trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
                            onTap: () {},
                          ),
                          const _StyledDivider(),
                          ListTile(
                            title: Text('Email Support', style: titleStyle),
                            trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
                            onTap: () {},
                          ),
                           const _StyledDivider(),
                          ListTile(
                            title: Text('Privacy Policy', style: titleStyle),
                            trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
                            onTap: () {},
                          ),
                        ],
                      )
                    ),


                    // --- Account Section ---
                    _buildSectionHeader('Account'),
                    _SettingsCard(
                      child: Column(
                        children: [
                          ListTile(
                            title: Text('Log Out', style: titleStyle),
                            trailing: Icon(Icons.logout, color: Colors.grey[400]),
                            onTap: () => _showLogoutConfirmationDialog(context),
                          ),
                          const _StyledDivider(),
                          ListTile(
                            title: Text(
                              'Delete Account',
                              style: titleStyle.copyWith(color: Colors.red.shade700),
                            ),
                            trailing: Icon(Icons.delete_outline, color: Colors.red.shade400),
                            onTap: () => _showDeleteConfirmationDialog(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- UI BUILDER WIDGETS ---

  /// Builds the header for each section, matching the homepage style.
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Center(
        child: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.grey[800],
          ),
        ),
      ),
    );
  }

  // --- DIALOGS AND HANDLERS (Functionality is unchanged) ---

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Log Out'),
          content: const Text('Are you sure you want to log out?'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Log Out', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _authService.logout();
                if (mounted) MyApp.restartApp(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: const Text('Are you sure? This action is permanent and cannot be undone.'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _handleAccountDeletion();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleAccountDeletion() async {
    try {
      await _authService.deleteAccount();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account deleted successfully.'), backgroundColor: Colors.green),
        );
        MyApp.restartApp(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst("Exception: ", "")), backgroundColor: Colors.red),
        );
      }
    }
  }
}

// --- HELPER WIDGETS FOR THE NEW DESIGN ---

/// A card that mimics the semi-transparent white style from the homepage.
class _SettingsCard extends StatelessWidget {
  final Widget child;
  const _SettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white.withOpacity(0.85), Colors.white.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24.0),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// A consistently styled divider for use inside the settings cards.
class _StyledDivider extends StatelessWidget {
  const _StyledDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.black.withOpacity(0.05),
      indent: 16,
      endIndent: 16,
    );
  }
}


/// The animated gradient background from the home page.
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
      builder: (context, child) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
        ),
      ),
    );
  }
}