import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fyp/services/auth_service.dart';
import 'package:fyp/main.dart'; // Needed to restart the app

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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSystemSection(),
            const SizedBox(height: 16),
            _buildShareSection(),
            const SizedBox(height: 16),
            _buildNotificationsSection(),
            const SizedBox(height: 16),
            _buildServicesSection(),
            const SizedBox(height: 24),
            _buildSupportSection(),
            const SizedBox(height: 24),
            _buildAccountSection(),
          ],
        ),
      ),
    );
  }

  // --- DIALOGS AND HANDLERS ---

  /// Shows a confirmation dialog before logging out.
  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Log Out'),
          content: const Text('Are you sure you want to log out?'),
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
                if (mounted) {
                  MyApp.restartApp(context);
                }
              },
            ),
          ],
        );
      },
    );
  }

  /// Shows a final confirmation dialog before deleting the user's account.
  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: const Text(
              'Are you sure? This action is permanent and cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog first
                _handleAccountDeletion(); // Call the deletion handler
              },
            ),
          ],
        );
      },
    );
  }

  /// Handles the call to the auth service and provides UI feedback.
  Future<void> _handleAccountDeletion() async {
    try {
      // Call the service to delete the account
      await _authService.deleteAccount();

      // If successful, the user is already logged out. Restart the app.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account deleted successfully.'),
            backgroundColor: Colors.green,
          ),
        );
        MyApp.restartApp(context);
      }
    } catch (e) {
      // Show an error message if something goes wrong
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- UI BUILDER WIDGETS ---

  Widget _buildSectionCard(List<Widget> children) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8, top: 16),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildAccountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Account'),
        _buildSectionCard([
          ListTile(
            title: Text('Log Out', style: GoogleFonts.poppins(fontSize: 16)),
            trailing: const Icon(Icons.logout, color: Colors.grey),
            onTap: () => _showLogoutConfirmationDialog(context),
          ),
          const Divider(height: 1),
          ListTile(
            title: Text(
              'Delete Account',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.red),
            ),
            trailing: const Icon(Icons.delete_outline, color: Colors.red),
            onTap: () => _showDeleteConfirmationDialog(context),
          ),
        ]),
      ],
    );
  }

  Widget _buildSystemSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('System'),
        _buildSectionCard([
          _buildListTile('Current Weight', '82.0 kg'),
          const Divider(height: 1),
          _buildListTile('Target Weight', '76.0 kg'),
          const Divider(height: 1),
          _buildListTile('Height', '6.0 ft'),
          const Divider(height: 1),
          _buildListTile('Gender', 'Male'),
          const Divider(height: 1),
          _buildListTile('Water Goal', '2.00 L'),
        ]),
      ],
    );
  }

  Widget _buildListTile(String title, String value) {
    return ListTile(
      title: Text(title, style: GoogleFonts.poppins(fontSize: 16)),
      trailing: Text(
        value,
        style: GoogleFonts.poppins(
          color: const Color(0xFF4CAF50),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildShareSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Share'),
        _buildSectionCard([
          ListTile(
            title: Text(
              'Share Nutriwise',
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            trailing: const Icon(Icons.share, color: Colors.grey),
            onTap: () {},
          ),
        ]),
      ],
    );
  }

  Widget _buildNotificationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Notifications'),
        _buildSectionCard([
          SwitchListTile(
            title: Text(
              'Enable Notifications',
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
            activeColor: Colors.deepPurple,
          ),
        ]),
      ],
    );
  }

  Widget _buildServicesSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildSectionTitle('Services'),
      _buildSectionCard([
        ListTile(
          title: Text(
            'Health Connect',
            style: GoogleFonts.poppins(fontSize: 16),
          ),
          trailing: const Icon(Icons.link, color: Colors.grey),
          onTap: () {},
        ),
      ])
    ]);
  }

  Widget _buildSupportSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Support'),
        _buildSectionCard([
          _buildSupportItem('Like us'),
          const Divider(height: 1),
          _buildSupportItem('Rate us'),
          const Divider(height: 1),
          _buildSupportItem('Email Support'),
          const Divider(height: 1),
          _buildSupportItem('Privacy Policy'),
          const Divider(height: 1),
          _buildSupportItem('Terms of Service'),
          const Divider(height: 1),
          _buildSupportItem('Community Guidelines'),
        ]),
      ],
    );
  }

  Widget _buildSupportItem(String title) {
    return ListTile(
      title: Text(title, style: GoogleFonts.poppins(fontSize: 16)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () {},
    );
  }
}