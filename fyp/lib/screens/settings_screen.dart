import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
          value: true,
          onChanged: (value) {},
        ),
      ]),
    ],
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

  Widget _buildServicesSection() {
    return _buildSectionCard([
      ListTile(
        title: Text(
          'Health Connect',
          style: GoogleFonts.poppins(fontSize: 16),
        ),
        trailing: const Icon(Icons.link, color: Colors.grey),
        onTap: () {/* Add health connect logic */},
      ),
    ]);
  }

  Widget _buildSupportSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            'Support',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
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
      onTap: () {/* Add navigation */},
    );
  }

  Widget _buildAccountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            'Account',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        _buildSectionCard([
          ListTile(
            title: Text(
              'Log In',
              style: GoogleFonts.poppins(fontSize: 16)),
            trailing: const Icon(Icons.login, color: Colors.grey),
            onTap: () {/* Add login logic */},
          ),
          const Divider(height: 1),
          ListTile(
            title: Text(
              'Delete Account',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.red,
              ),
            ),
            trailing: const Icon(
              Icons.delete_outline,
              color: Colors.red,
            ),
            onTap: () {/* Add delete confirmation */},
          ),
        ]),
      ],
    );
  }
}