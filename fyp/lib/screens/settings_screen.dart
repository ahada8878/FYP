import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Needed for input formatters
import 'package:flutter_html/flutter_html.dart';
import 'package:fyp/LocalDB.dart';
import 'package:fyp/Loginpage.dart'; // Import for CreativeLoginPage
import 'package:fyp/main.dart';
import 'package:fyp/screens/privacy_policy_screen.dart';
import 'package:fyp/screens/rate_us_screen.dart';
import 'package:fyp/screens/email_support_screen.dart';
import 'package:fyp/services/auth_service.dart';
import 'dart:ui';
import 'package:fyp/services/config_service.dart';
import 'package:http/http.dart' as http; // Needed for BackdropFilter

// --- Main Settings Screen Widget ---

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  bool _notificationsEnabled = true;

  // Provide default initial values to avoid LateInitializationError
  String _userName = '';
  String _userEmail = ''; // ⭐️ NEW: Email state variable
  String _currentWeight = '0 kg';
  String _targetWeight = '0 kg';
  String _height = '0 ft';
  String _waterGoal = '2000 mL'; // Changed to 'mL' for consistency

  @override
  void initState() {
    super.initState();
    _getValues(); // Load profile data asynchronously
  }

  Future<void> _getValues() async {
    final token = await _authService.getToken();
    final localEmail = await LocalDB.getUserEmail(); // Retrieve email from LocalDB

    if (token == null || token.isEmpty) {
      throw Exception('You are not logged in. Please log in to continue.');
    }
    
    // Set email from LocalDB initially to ensure it's displayed quickly
    if (localEmail != null) {
      setState(() {
        _userEmail = localEmail;
      });
    }

    try {
      final url = Uri.parse('$baseURL/api/user/profile-summary');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _userName = data['userName'] ?? '';
            LocalDB.setUserName(_userName);

            _userEmail = data['email'] ?? localEmail ?? ''; // ⭐️ Fetch email from API
            LocalDB.setUserEmail(_userEmail); // ⭐️ Save email to LocalDB

            _currentWeight = data['currentWeight'] ?? '0 kg';
            LocalDB.setCurrentWeight(_currentWeight);

            _targetWeight = data['targetWeight'] ?? '0 kg';
            LocalDB.setTargetWeight(_targetWeight);

            _height = data['height'] ?? '0 ft';
            LocalDB.setHeight(_height);

            // Ensure water goal is formatted correctly with unit
            final apiWaterGoal = data['waterGoal']?.toString() ?? '2000';
            _waterGoal = '${apiWaterGoal} mL';
            LocalDB.setWaterGoal(int.tryParse(apiWaterGoal) ?? 2000);
          });
        } else {
          debugPrint("⚠️ API returned success=false: ${data['message']}");
          await _loadLocalDBValues();
        }
      } else {
        debugPrint(
            "⚠️ Failed to fetch profile summary. Status code: ${response.statusCode}");
        await _loadLocalDBValues();
      }
    } catch (e) {
      debugPrint("❌ Error in _getValues(): $e");
      await _loadLocalDBValues();
    }
  }

  // Corrected local DB loader
  Future<void> _loadLocalDBValues() async {
    final userName = await LocalDB.getUserName() ?? '';
    final userEmail = await LocalDB.getUserEmail() ?? ''; 
    final currentWeight = await LocalDB.getCurrentWeight() ?? '0 kg';
    final targetWeight = await LocalDB.getTargetWeight() ?? '0 kg';
    final height = await LocalDB.getHeight() ?? '0 ft';
    final waterGoal = await LocalDB.getWaterGoal() ?? 2000;

    if (mounted) {
      setState(() {
        _userName = userName;
        _userEmail = userEmail; 
        _currentWeight = currentWeight;
        _targetWeight = targetWeight;
        _height = height;
        _waterGoal = '$waterGoal mL';
      });
    }
    debugPrint("⚡ Loaded profile from LocalDB.");
  }

  /// Helper to robustly strip units from a string for editing.
  String _stripUnit(String value, String unit) {
    final trimmedUnit = unit.trim(); 
    final spacedUnit = ' $trimmedUnit'; 

    String numericValue;
    if (value.endsWith(spacedUnit)) {
      numericValue = value.substring(0, value.length - spacedUnit.length);
    } else if (value.endsWith(trimmedUnit)) {
      numericValue = value.substring(0, value.length - trimmedUnit.length);
    } else {
      numericValue = value.replaceAll(RegExp(r'[^\d.]'), '');
    }
    return numericValue.trim();
  }

  Future<void> _callAPIs(String requestType, String value) async {
    try {
      final authToken = await AuthService().getToken();
      if (authToken == null) return;
      final url =
          Uri.parse('$baseURL/api/user-details/my-profile/$requestType');
      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $authToken'
      };
      // For profile updates, the value is sent as a string (e.g., "56 kg", "6 ft")
      final body = jsonEncode({'$requestType': value});
      await http.post(url, headers: headers, body: body);
    } catch (e) {
      debugPrint("Error in _callAPIs(): $e");
    }
  }

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
                    // --- Profile Section ---
                    _SettingsCard(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 16),
                        leading:  CircleAvatar(
                          radius: 28, // Made avatar larger
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: Icon(Icons.person,
                              size: 30, color: Colors.white70),
                        ),
                        title: Text(
                          _userName,
                          style: titleStyle.copyWith(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        trailing:
                            Icon(Icons.chevron_right, color: Colors.grey[400]),
                        onTap: _editProfileName,
                      ),
                    ),

                    // --- System Section (Editable) ---
                    _buildSectionHeader('System'),
                    _SettingsCard(
                      child: Column(
                        children: [
                          // ⭐️ NEW: Email Field
                          ListTile(
                            title: Text('Email', style: titleStyle),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_userEmail, style: valueStyle.copyWith(fontSize: 13)), // Display email
                                const SizedBox(width: 8),
                                Icon(Icons.chevron_right, color: Colors.grey[400]),
                              ],
                            ),
                            onTap: _editEmail, // ⭐️ NEW: Edit Email Handler
                          ),
                          const _StyledDivider(),
                          
                          ListTile(
                            title: Text('Current Weight', style: titleStyle),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_currentWeight, style: valueStyle),
                                const SizedBox(width: 8),
                                Icon(Icons.chevron_right,
                                    color: Colors.grey[400]),
                              ],
                            ),
                            onTap: _editCurrentWeight,
                          ),
                          const _StyledDivider(),
                          ListTile(
                            title: Text('Target Weight', style: titleStyle),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_targetWeight, style: valueStyle),
                                const SizedBox(width: 8),
                                Icon(Icons.chevron_right,
                                    color: Colors.grey[400]),
                              ],
                            ),
                            onTap: _editTargetWeight,
                          ),
                          const _StyledDivider(),
                          ListTile(
                            title: Text('Height', style: titleStyle),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_height, style: valueStyle),
                                const SizedBox(width: 8),
                                Icon(Icons.chevron_right,
                                    color: Colors.grey[400]),
                              ],
                            ),
                            onTap: _editHeight,
                          ),
                          const _StyledDivider(),
                          ListTile(
                            title: Text('Water Goal', style: titleStyle),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_waterGoal, style: valueStyle),
                                const SizedBox(width: 8),
                                Icon(Icons.chevron_right,
                                    color: Colors.grey[400]),
                              ],
                            ),
                            onTap: _editWaterGoal,
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
                          trailing: Icon(Icons.chevron_right,
                              color: Colors.grey[400]),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (context) => const RateUsScreen()),
                            );
                          },
                        ),
                        const _StyledDivider(),
                        ListTile(
                          title: Text('Email Support', style: titleStyle),
                          trailing: Icon(Icons.chevron_right,
                              color: Colors.grey[400]),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const EmailSupportScreen()),
                            );
                          },
                        ),
                        const _StyledDivider(),
                        ListTile(
                          title: Text('Privacy Policy', style: titleStyle),
                          trailing: Icon(Icons.chevron_right,
                              color: Colors.grey[400]),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const PrivacyPolicyScreen()),
                            );
                          },
                        ),
                      ],
                    )),

                    // --- Account Section ---
                    _buildSectionHeader('Account'),
                    _SettingsCard(
                      child: Column(
                        children: [
                          ListTile(
                            title: Text('Change Password', style: titleStyle),
                            trailing: Icon(Icons.lock_outline, color: Colors.grey[400]),
                            onTap: () => _showPasswordUpdateDialog(context),
                          ),
                          const _StyledDivider(),
                          ListTile(
                            title: Text('Log Out', style: titleStyle),
                            trailing:
                                Icon(Icons.logout, color: Colors.grey[400]),
                            onTap: () => _showLogoutConfirmationDialog(context),
                          ),
                          const _StyledDivider(),
                          ListTile(
                            title: Text(
                              'Delete Account',
                              style: titleStyle.copyWith(
                                  color: Colors.red.shade700),
                            ),
                            trailing: Icon(Icons.delete_outline,
                                color: Colors.red.shade400),
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

  // 🚀 NEW: General Styled Edit Dialog using Modal Sheet (replaces _showEditDialog)
  Future<void> _showStyledEditDialog({
    required String title,
    required String initialValue,
    required Function(String) onSave,
    String? unitSuffix,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) async {
    final TextEditingController controller =
        TextEditingController(text: initialValue);
    final _formKey = GlobalKey<FormState>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (BuildContext innerDialogContext) {
        bool isLoading = false;
        String? errorMessage;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setInnerState) {
            final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;
            
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + keyboardPadding),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter a new value for your $title.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // --- Status Messages ---
                      if (errorMessage != null)
                        _StatusMessage(
                          message: errorMessage!,
                          icon: Icons.error_outline,
                          color: Colors.red.shade100,
                          textColor: Colors.red.shade700,
                        ),
                      if (errorMessage != null) const SizedBox(height: 16),

                      // Input Field
                      TextFormField(
                        controller: controller,
                        autofocus: true,
                        keyboardType: keyboardType,
                        inputFormatters: inputFormatters,
                        decoration: InputDecoration(
                          labelText: title,
                          suffixText: unitSuffix,
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12))
                          ),
                        ),
                        validator: validator ?? (value) {
                          if (value == null || value.isEmpty) {
                            return 'Value cannot be empty.';
                          }
                          // Additional check for numeric types
                          if (keyboardType == TextInputType.number || keyboardType == const TextInputType.numberWithOptions(decimal: true)) {
                            if (double.tryParse(value) == null) {
                              return 'Enter a valid number.';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      
                      // --- Action Buttons ---
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isLoading ? null : () => Navigator.of(innerDialogContext).pop(),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isLoading ? null : () async {
                                if (!_formKey.currentState!.validate()) return;
                                
                                setInnerState(() {
                                  isLoading = true;
                                  errorMessage = null;
                                });

                                try {
                                  // Perform the save action
                                  onSave(controller.text.trim());
                                  
                                  // Success, close the sheet
                                  setInnerState(() => isLoading = false);
                                  if(mounted) Navigator.of(innerDialogContext).pop();
                                  
                                } catch (e) {
                                  // Error is unlikely here but kept for consistency
                                  final errorMsg = e.toString().replaceFirst("Exception: ", "");
                                  setInnerState(() {
                                    errorMessage = errorMsg;
                                    isLoading = false;
                                  });
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Save'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }


  // --- Functions that use the new dialogs ---

  void _editProfileName() {
    _showStyledEditDialog(
      title: 'Name',
      initialValue: _userName,
      onSave: (newValue) {
        setState(() => _userName = newValue);
        _callAPIs("userName", '$newValue');
      },
    );
  }
  
  void _editEmail() {
    _showEmailUpdateDialog(context, _userEmail);
  }

  void _editCurrentWeight() {
    _showStyledEditDialog(
      title: 'Current Weight',
      initialValue: _stripUnit(_currentWeight, 'kg'), 
      unitSuffix: ' kg', 
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      onSave: (newValue) {
        setState(() => _currentWeight = '${newValue.trim()} kg');
        _callAPIs("currentWeight", '${newValue.trim()} kg');
        LocalDB.setCurrentWeight('${newValue.trim()} kg');
      },
    );
  }

  void _editTargetWeight() {
    _showStyledEditDialog(
      title: 'Target Weight',
      initialValue: _stripUnit(_targetWeight, 'kg'), 
      unitSuffix: ' kg', 
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      onSave: (newValue) {
        setState(() => _targetWeight = '${newValue.trim()} kg');
        _callAPIs("targetWeight", '${newValue.trim()} kg');
        LocalDB.setTargetWeight('${newValue.trim()} kg');
      },
    );
  }

  void _editHeight() {
    _showStyledEditDialog(
      title: 'Height',
      initialValue: _stripUnit(_height, 'ft'), 
      unitSuffix: ' ft', 
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onSave: (newValue) {
        setState(() => _height = '${newValue.trim()} ft');
        _callAPIs("height", '${newValue.trim()} ft');
        LocalDB.setHeight('${newValue.trim()} ft');
      },
    );
  }

  void _editWaterGoal() {
    _showStyledEditDialog(
      title: 'Water Goal',
      initialValue: _stripUnit(_waterGoal, 'mL'), 
      unitSuffix: ' mL', 
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      onSave: (newValue) {
        setState(() => _waterGoal = '${newValue.trim()} mL');
        _callAPIs("waterGoal", '${newValue.trim()} mL');
        LocalDB.setWaterGoal(int.tryParse(newValue.trim()) ?? 0);
      },
    );
  }

  // 🚀 REFACTORED: Email Update Dialog Logic using showModalBottomSheet
  Future<void> _showEmailUpdateDialog(BuildContext context, String currentEmail) async {
    final TextEditingController newEmailController = TextEditingController();
    final TextEditingController otpController = TextEditingController();
    final _formKey = GlobalKey<FormState>();
    final _authService = AuthService();
    
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (BuildContext innerDialogContext) {
        // Local state variables for the dialog
        String dialogTitle = 'Change Email';
        String dialogSubtitle = 'Enter your new email address to start the verification process.';
        bool isOtpSent = false;
        bool isLoading = false;
        String newEmail = '';
        String? errorMessage;
        String? successMessage;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setInnerState) {
            final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;
            
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + keyboardPadding),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dialogTitle,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dialogSubtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // --- Status Messages ---
                      if (errorMessage != null)
                        _StatusMessage(
                          message: errorMessage!,
                          icon: Icons.error_outline,
                          color: Colors.red.shade100,
                          textColor: Colors.red.shade700,
                        ),
                      if (successMessage != null)
                        _StatusMessage(
                          message: successMessage!,
                          icon: Icons.check_circle_outline,
                          color: Colors.green.shade100,
                          textColor: Colors.green.shade700,
                        ),
                      if (errorMessage != null || successMessage != null)
                        const SizedBox(height: 16),

                      // Input Field (changes based on step)
                      if (!isOtpSent)
                        TextFormField(
                          controller: newEmailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'New Email Address',
                            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a new email.';
                            }
                            if (!value.contains('@') || !value.contains('.')) {
                              return 'Enter a valid email address.';
                            }
                            return null;
                          },
                        )
                      else
                        TextFormField(
                          controller: otpController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          maxLength: 6,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 20, letterSpacing: 5),
                          decoration: const InputDecoration(
                            labelText: '6-Digit Code',
                            counterText: '',
                            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                            hintText: '• • • • • •',
                          ),
                          validator: (value) {
                            if (value == null || value.length != 6) {
                              return 'Enter the 6-digit code.';
                            }
                            return null;
                          },
                        ),
                      const SizedBox(height: 24),

                      // --- Action Buttons ---
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isLoading || successMessage != null ? null : () => Navigator.of(innerDialogContext).pop(),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isLoading || successMessage != null ? null : () async {
                                if (!_formKey.currentState!.validate()) return;
                                
                                setInnerState(() {
                                  isLoading = true;
                                  errorMessage = null;
                                  successMessage = null;
                                });

                                try {
                                  if (!isOtpSent) {
                                    // Step 1: Send OTP
                                    newEmail = newEmailController.text.trim();
                                    await _authService.sendUpdateOtp(newEmail);
                                    setInnerState(() {
                                      isOtpSent = true;
                                      dialogTitle = 'Verify New Email';
                                      dialogSubtitle = 'A 6-digit code has been sent to $newEmail. Please enter it below.';
                                    });
                                  } else {
                                    // Step 2: Verify OTP and Update Email
                                    final otp = otpController.text.trim();
                                    await _authService.verifyUpdateEmail(otp, newEmail);
                                    
                                    // Success
                                    setInnerState(() {
                                      successMessage = 'Email updated successfully!';
                                      // Update the parent state immediately
                                      if (mounted) setState(() => _userEmail = newEmail);
                                    });

                                    // Close dialog after delay
                                    await Future.delayed(const Duration(seconds: 2));
                                    if(mounted) Navigator.of(innerDialogContext).pop();
                                    return;
                                  }
                                } catch (e) {
                                  errorMessage = e.toString().replaceFirst("Exception: ", "");
                                }
                                setInnerState(() => isLoading = false);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : Text(isOtpSent ? 'Verify' : 'Send Code'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 🚀 REFACTORED: Password Update Dialog Logic (From previous step, included here for completeness)
  Future<void> _showPasswordUpdateDialog(BuildContext context) async {
    final TextEditingController oldPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();
    final _formKey = GlobalKey<FormState>();
    
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (BuildContext innerDialogContext) {
        bool isLoading = false;
        bool isNewPasswordVisible = false;
        bool isOldPasswordVisible = false;
        bool isConfirmPasswordVisible = false;
        String? successMessage; 
        String? errorMessage;   

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setInnerState) {
            final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;

            return Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + keyboardPadding),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Change Password',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'For security, please enter your old and new passwords.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // --- Status Messages ---
                      if (errorMessage != null)
                        _StatusMessage(
                          message: errorMessage!,
                          icon: Icons.error_outline,
                          color: Colors.red.shade100,
                          textColor: Colors.red.shade700,
                        ),
                      if (successMessage != null)
                        _StatusMessage(
                          message: successMessage!,
                          icon: Icons.check_circle_outline,
                          color: Colors.green.shade100,
                          textColor: Colors.green.shade700,
                        ),
                      
                      if (errorMessage != null || successMessage != null)
                        const SizedBox(height: 16),
                        
                      // Old Password Field
                      TextFormField(
                        controller: oldPasswordController,
                        obscureText: !isOldPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'Old Password',
                          border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                          prefixIcon: const Icon(Icons.vpn_key),
                          suffixIcon: IconButton(
                            icon: Icon(
                              isOldPasswordVisible ? Icons.visibility : Icons.visibility_off,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            onPressed: () {
                              setInnerState(() {
                                isOldPasswordVisible = !isOldPasswordVisible;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your old password.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // New Password Field
                      TextFormField(
                        controller: newPasswordController,
                        obscureText: !isNewPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'New Password',
                          border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                          prefixIcon: const Icon(Icons.lock_open),
                          suffixIcon: IconButton(
                            icon: Icon(
                              isNewPasswordVisible ? Icons.visibility : Icons.visibility_off,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            onPressed: () {
                              setInnerState(() {
                                isNewPasswordVisible = !isNewPasswordVisible;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.length < 6) {
                            return 'Password must be at least 6 characters.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Confirm New Password Field 
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: !isConfirmPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'Confirm New Password',
                          border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                          prefixIcon: const Icon(Icons.check_circle_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            onPressed: () {
                              setInnerState(() {
                                isConfirmPasswordVisible = !isConfirmPasswordVisible;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value != newPasswordController.text) {
                            return 'Passwords do not match.';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // --- Action Buttons ---
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isLoading || successMessage != null 
                                  ? null 
                                  : () => Navigator.of(innerDialogContext).pop(),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isLoading || successMessage != null ? null : () async {
                                if (!_formKey.currentState!.validate()) return;
                                
                                setInnerState(() {
                                  isLoading = true;
                                  errorMessage = null;
                                  successMessage = null;
                                });

                                try {
                                  await _authService.changePassword(
                                    oldPasswordController.text,
                                    newPasswordController.text,
                                  );

                                  setInnerState(() {
                                    isLoading = false; 
                                    successMessage = 'Password updated successfully!';
                                  });

                                  await Future.delayed(const Duration(seconds: 2));
                                  if(mounted) Navigator.of(innerDialogContext).pop(); 
                                  
                                } catch (e) {
                                  final errorMsg = e.toString().replaceFirst("Exception: ", "");
                                  setInnerState(() {
                                    errorMessage = errorMsg;
                                    isLoading = false;
                                    successMessage = null;
                                  });
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(successMessage != null ? 'Done' : 'Change Password'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }


  // 🚀 NEW: General Styled Confirmation Dialog using Modal Sheet (replaces showDialog for Logout/Delete)
  Future<void> _showStyledConfirmationDialog({
    required BuildContext context,
    required String title,
    required String content,
    required String confirmText,
    required Color confirmColor,
    required Future<void> Function() onConfirm,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (BuildContext innerDialogContext) {
        bool isLoading = false;
        String? errorMessage;
        
        return StatefulBuilder(
          builder: (context, setInnerState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    confirmColor == Colors.red ? Icons.warning_amber_rounded : Icons.help_outline,
                    size: 40,
                    color: confirmColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: confirmColor == Colors.red ? confirmColor : Theme.of(context).colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    content,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  if (errorMessage != null)
                     Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _StatusMessage(
                        message: errorMessage!,
                        icon: Icons.error_outline,
                        color: Colors.red.shade100,
                        textColor: Colors.red.shade700,
                      ),
                    ),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isLoading ? null : () => Navigator.of(innerDialogContext).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isLoading ? null : () async {
                            setInnerState(() {
                              isLoading = true;
                              errorMessage = null;
                            });
                            try {
                              await onConfirm();
                              // The onConfirm usually handles navigation (e.g., pop/pushReplacement)
                              // If it fails to navigate, we ensure the modal closes
                              if(mounted && Navigator.canPop(innerDialogContext)) {
                                Navigator.of(innerDialogContext).pop();
                              }
                            } catch (e) {
                              setInnerState(() {
                                errorMessage = e.toString().replaceFirst("Exception: ", "");
                                isLoading = false;
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: confirmColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Text(confirmText, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    _showStyledConfirmationDialog(
      context: context,
      title: 'Log Out',
      content: 'Are you sure you want to log out? You will be taken back to the login screen.',
      confirmText: 'Log Out',
      confirmColor: Theme.of(context).colorScheme.primary, // Using primary color for positive action
      onConfirm: () async {
        await _authService.logout();
        MyApp.restartApp(context);

        if (mounted) {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const CreativeLoginPage()));
        }
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    _showStyledConfirmationDialog(
      context: context,
      title: 'Delete Account',
      content: 'Warning! This action is permanent and cannot be undone. All your data will be lost.',
      confirmText: 'Delete Permanently',
      confirmColor: Colors.red.shade700,
      onConfirm: () async {
        await _handleAccountDeletion();
        // Navigation is handled inside _handleAccountDeletion, but will also pop the dialog
      },
    );
  }
  
  // NOTE: This function's content remains largely the same, but it's now called from the styled confirmation dialog
  Future<void> _handleAccountDeletion() async {
    try {
      await _authService.deleteAccount();
      if (mounted) {
        // SnackBar for final confirmation before app restart
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Account deleted successfully.'),
              backgroundColor: Colors.green),
        );
        MyApp.restartApp(context);
      }
    } catch (e) {
      // Re-throw the exception so the confirmation dialog can display the error message
      throw Exception(e.toString().replaceFirst("Exception: ", ""));
    }
  }
}

// --- NEW HELPER WIDGETS ---

/// Custom styled container for showing success or error messages
class _StatusMessage extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color color;
  final Color textColor;

  const _StatusMessage({
    required this.message,
    required this.icon,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// --- HELPER WIDGETS FOR THE NEW DESIGN (Unchanged) ---

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
              colors: [
                Colors.white.withOpacity(0.85),
                Colors.white.withOpacity(0.7)
              ],
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

/// A consistently styled divide
class _StyledDivider extends StatelessWidget {
  const _StyledDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      color: Colors.black12,
      indent: 16,
      endIndent: 16,
    );
  }
}

/// A simple animated background for visual flair.
class _LivingAnimatedBackground extends StatefulWidget {
  const _LivingAnimatedBackground();

  @override
  _LivingAnimatedBackgroundState createState() =>
      _LivingAnimatedBackgroundState();
}

class _LivingAnimatedBackgroundState extends State<_LivingAnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
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
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(
                math.cos(_controller.value * 2 * math.pi),
                math.sin(_controller.value * 2 * math.pi),
              ),
              end: Alignment(
                math.cos((_controller.value * 2 * math.pi) + math.pi),
                math.sin((_controller.value * 2 * math.pi) + math.pi),
              ),
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.1),
                Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                Theme.of(context).colorScheme.tertiary.withOpacity(0.1),
              ],
            ),
          ),
        );
      },
    );
  }
}