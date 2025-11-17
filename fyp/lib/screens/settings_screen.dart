// Import necessary Dart and Flutter packages
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Needed for input formatters
import 'package:fyp/LocalDB.dart'; // Local database utility
import 'package:fyp/Loginpage.dart'; // Login screen for navigation after logout
import 'package:fyp/main.dart'; // Main application entry point for restart logic
import 'package:fyp/screens/privacy_policy_screen.dart'; // Navigation target screen
import 'package:fyp/screens/rate_us_screen.dart'; // Navigation target screen
import 'package:fyp/screens/email_support_screen.dart'; // Navigation target screen
import 'package:fyp/services/auth_service.dart'; // Service for authentication logic
import 'dart:ui'; // Used for blurring effects
import 'package:fyp/services/config_service.dart'; // Configuration service (e.g., baseURL)
import 'package:http/http.dart' as http; // HTTP client for API communication

// --- Main Settings Screen Widget ---

// Define the main StatefulWidget for the Settings Screen
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

// A static list of all possible health concerns for display and API mapping
const List<String> _kAvailableHealthConcerns = [
  "I don't have any", // Special case to handle 'none'
  'Hypertension',
  'High Cholesterol',
  'Obesity',
  'Diabetes',
  'Heart Disease',
  'Arthritis',
  'Asthma', 
];


// Define the State for the Settings Screen
class _SettingsScreenState extends State<SettingsScreen> {
  // Instance of the authentication service
  final AuthService _authService = AuthService();
  // State variable for notification preference
  bool _notificationsEnabled = true;

  // --- Profile State Variables with default initialization ---
  String _userName = '';
  String _userEmail = ''; 
  String _currentWeight = '0 kg';
  String _targetWeight = '0 kg';
  String _startWeight = '0 kg'; // 👈 ADDED: State for Start Weight
  String _height = '0 ft';
  String _waterGoal = '2000 mL'; 
  // Map to store the boolean state of all health concerns
  Map<String, bool> _healthConcerns = { "I don't have any": true }; 

  // Initialize state: Load profile data on startup
  @override
  void initState() {
    super.initState();
    _getValues(); // Load profile data asynchronously
  }

  // ----------------------------------------------------------------------
  // 💾 DATA LOADING/SAVING FUNCTIONS
  // ----------------------------------------------------------------------

  // Fetches user profile data from the backend API
  Future<void> _getValues() async {
    final token = await _authService.getToken();
    final localEmail = await LocalDB.getUserEmail(); 

    if (token == null || token.isEmpty) {
      await _loadLocalDBValues(); // Fallback to local data if no token
      return; 
    }
    
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
            // Update all profile fields from API response
            _userName = data['userName'] ?? '';
            LocalDB.setUserName(_userName);

            _userEmail = data['email'] ?? localEmail ?? '';
            LocalDB.setUserEmail(_userEmail); 

            _currentWeight = data['currentWeight'] ?? '0 kg';
            LocalDB.setCurrentWeight(_currentWeight);

            _startWeight = data['startWeight'] ?? '0 kg'; // 👈 FETCH Start Weight
            LocalDB.setStartWeight(_startWeight); // 👈 SAVE Start Weight Locally

            _targetWeight = data['targetWeight'] ?? '0 kg';
            LocalDB.setTargetWeight(_targetWeight);

            _height = data['height'] ?? '0 ft';
            LocalDB.setHeight(_height);

            final apiWaterGoal = data['waterGoal']?.toString() ?? '2000';
            _waterGoal = '${apiWaterGoal} mL';
            LocalDB.setWaterGoal(int.tryParse(apiWaterGoal) ?? 2000);
            
            // --- Health Concerns Logic ---
            Map<String, dynamic> apiHealthConcerns = data['healthConditions'] ?? {};
            
            // Prepare a map to hold the final state
            Map<String, bool> finalConcerns = {};
            for (var condition in _kAvailableHealthConcerns) {
                // Populate map, defaulting to false
                finalConcerns[condition] = (apiHealthConcerns[condition] is bool)
                    ? apiHealthConcerns[condition] as bool
                    : false; 
            }
            
            // Ensure state consistency: If no specific concerns are TRUE, set "I don't have any" to TRUE.
            final bool hasAnySpecificConcerns = finalConcerns.entries
                .where((e) => e.key != "I don't have any")
                .any((e) => e.value == true);
            
            if (!hasAnySpecificConcerns) {
                finalConcerns["I don't have any"] = true;
            } else {
                finalConcerns["I don't have any"] = false;
            }

            _healthConcerns = finalConcerns; 
          });
        } else {
          debugPrint("⚠️ API returned success=false: ${data['message']}");
          await _loadLocalDBValues(); // Fallback
        }
      } else {
        debugPrint(
            "⚠️ Failed to fetch profile summary. Status code: ${response.statusCode}");
        await _loadLocalDBValues(); // Fallback
      }
    } catch (e) {
      debugPrint("❌ Error in _getValues(): $e");
      await _loadLocalDBValues(); // Fallback
    }
  }

  // Loads profile data from local storage as a fallback
  Future<void> _loadLocalDBValues() async {
    final userName = await LocalDB.getUserName() ?? '';
    final userEmail = await LocalDB.getUserEmail() ?? ''; 
    final currentWeight = await LocalDB.getCurrentWeight() ?? '0 kg';
    final startWeight = await LocalDB.getStartWeight() ?? '0 kg'; // 👈 LOAD Start Weight Locally
    final targetWeight = await LocalDB.getTargetWeight() ?? '0 kg';
    final height = await LocalDB.getHeight() ?? '0 ft';
    final waterGoal = await LocalDB.getWaterGoal() ?? 2000;

    if (mounted) {
      setState(() {
        _userName = userName;
        _userEmail = userEmail; 
        _currentWeight = currentWeight;
        _startWeight = startWeight; // 👈 SET Start Weight State
        _targetWeight = targetWeight;
        _height = height;
        _waterGoal = '$waterGoal mL';
      });
    }
    debugPrint("⚡ Loaded basic profile from LocalDB.");
  }

  /// Helper to remove units (like 'kg', 'ft', 'mL') from a string for editing.
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

  // General API function to update simple profile fields (name, weight, height, goal)
  Future<void> _callAPIs(String requestType, String value) async {
    try {
      final authToken = await AuthService().getToken();
      if (authToken == null) throw Exception('No authentication token found.');

      final url = Uri.parse('$baseURL/api/user-details/my-profile/$requestType');
      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $authToken'
      };
      
      // Request body contains the field name and its new value
      final body = jsonEncode({requestType: value}); 

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode != 200 && response.statusCode != 201) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to update. Status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("Error in _callAPIs($requestType): $e");
      throw Exception('API call failed: $e');
    }
  }

  // Specialized API call for Health Concerns (sends the full Map<String, bool>)
  Future<void> _callHealthConcernsAPI(Map<String, bool> concerns) async {
    try {
      final authToken = await AuthService().getToken();
      if (authToken == null) throw Exception('No authentication token found.');

      // Send the full map for a complete overwrite in the backend
      final Map<String, bool> concernsToSend = Map<String, bool>.from(concerns);

      final url = Uri.parse('$baseURL/api/user-details/my-profile/healthConcerns');
      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $authToken'
      };
      
      // The API expects the map under the key 'healthConcerns'
      final body = jsonEncode({'healthConcerns': concernsToSend});
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode != 200 && response.statusCode != 201) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to update. Status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("Error in _callHealthConcernsAPI(): $e");
      throw Exception("Failed to save health concerns.");
    }
  }
  
  // ----------------------------------------------------------------------
  // 🖼️ UI BUILDER
  // ----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // Define reusable text styles
    final titleStyle = TextStyle(
      color: Colors.grey[800],
      fontWeight: FontWeight.w600,
      fontSize: 16,
    );
    final valueStyle = TextStyle(
      color: Colors.grey[600],
      fontSize: 15,
    );

    // Format selected health concerns for display in the list tile
    final selectedConcernsList = _healthConcerns.entries
        .where((e) => e.value == true && e.key != "I don't have any")
        .map((e) => e.key)
        .toList();
    
    final selectedConcernsText = selectedConcernsList.isEmpty 
        ? 'None' 
        : selectedConcernsList.take(1).join(', ') + 
          (selectedConcernsList.length > 1 
            ? ' +${selectedConcernsList.length - 1}' 
            : '');


    return Scaffold(
      body: Stack(
        children: [
          const _LivingAnimatedBackground(), // Animated background layer
          CustomScrollView(
            slivers: [
              // Custom app bar with transparency
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
                backgroundColor: Colors.transparent, 
                elevation: 0,
                pinned: true,
                centerTitle: true,
              ),
              // Main content area
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
                          radius: 28, 
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: const Icon(Icons.person,
                              size: 30, color: Colors.white70),
                        ),
                        title: Text(
                          _userName,
                          style: titleStyle.copyWith(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        trailing:
                            Icon(Icons.chevron_right, color: Colors.grey[400]),
                        onTap: _editProfileName, // Handler for name change
                      ),
                    ),

                    // --- System Section (Editable fields) ---
                    _buildSectionHeader('System'),
                    _SettingsCard(
                      child: Column(
                        children: [
                          // Email
                          ListTile(
                            title: Text('Email', style: titleStyle),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_userEmail, style: valueStyle.copyWith(fontSize: 13)), 
                                const SizedBox(width: 8),
                                Icon(Icons.chevron_right, color: Colors.grey[400]),
                              ],
                            ),
                            onTap: _editEmail, // Handler for email change
                          ),
                          const _StyledDivider(),
                          
                          // Current Weight
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
                            onTap: _editCurrentWeight, // Handler for current weight
                          ),
                          const _StyledDivider(),
                          
                          // ⭐️ Start Weight
                          ListTile(
                            title: Text('Start Weight', style: titleStyle),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_startWeight, style: valueStyle),
                                const SizedBox(width: 8),
                                Icon(Icons.chevron_right,
                                    color: Colors.grey[400]),
                              ],
                            ),
                            onTap: _editStartWeight, // 👈 Handler for start weight
                          ),
                          const _StyledDivider(),
                          
                          // Target Weight
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
                            onTap: _editTargetWeight, // Handler for target weight
                          ),
                          const _StyledDivider(),
                          
                          // Height
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
                            onTap: _editHeight, // Handler for height
                          ),
                          const _StyledDivider(),
                          
                          // Water Goal
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
                            onTap: _editWaterGoal, // Handler for water goal
                          ),
                          
                          // Health Concerns Field
                          const _StyledDivider(),
                          ListTile(
                            title: Text('Health Concerns', style: titleStyle),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Display comma-separated list of selected concerns
                                ConstrainedBox(
                                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.35),
                                  child: Text(
                                    selectedConcernsText,
                                    style: valueStyle.copyWith(fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.chevron_right, color: Colors.grey[400]),
                              ],
                            ),
                            onTap: _editHealthConditions, // Handler for health concerns
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

  // ----------------------------------------------------------------------
  // 🔨 HELPER & DIALOG FUNCTIONS
  // ----------------------------------------------------------------------
  
  /// Builds the header for each settings section.
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

  // General Modal Bottom Sheet for editing a single profile field
  Future<void> _showStyledEditDialog({
    required String title,
    required String initialValue,
    required Future<void> Function(String) onSave, 
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
                      // Dialog Header
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
                      
                      // Status Messages
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
                        // Basic validator
                        validator: validator ?? (value) {
                          if (value == null || value.isEmpty) {
                            return 'Value cannot be empty.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      
                      // Action Buttons
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
                                  await onSave(controller.text.trim());
                                  
                                  // Success
                                  setInnerState(() => isLoading = false);
                                  if(mounted) Navigator.of(innerDialogContext).pop();
                                  
                                } catch (e) {
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


  // --- Individual Edit Handlers ---

  void _editProfileName() {
    _showStyledEditDialog(
      title: 'Name',
      initialValue: _userName,
      onSave: (newValue) async { 
        await _callAPIs("userName", newValue); 
        LocalDB.setUserName(newValue); 
        if (mounted) {
          setState(() => _userName = newValue);
        }
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
      onSave: (newValue) async { 
        final finalValue = '${newValue.trim()} kg';
        await _callAPIs("currentWeight", finalValue); 
        LocalDB.setCurrentWeight(finalValue);
        if (mounted) {
          setState(() => _currentWeight = finalValue);
        }
      },
    );
  }

  void _editStartWeight() {
    _showStyledEditDialog(
      title: 'Start Weight',
      initialValue: _stripUnit(_startWeight, 'kg'), 
      unitSuffix: ' kg', 
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      onSave: (newValue) async { 
        final finalValue = '${newValue.trim()} kg';
        await _callAPIs("startWeight", finalValue); // 👈 API call for Start Weight
        LocalDB.setStartWeight(finalValue); // 👈 LocalDB update for Start Weight
        if (mounted) {
          setState(() => _startWeight = finalValue);
        }
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
      onSave: (newValue) async { 
        final finalValue = '${newValue.trim()} kg';
        await _callAPIs("targetWeight", finalValue); 
        LocalDB.setTargetWeight(finalValue);
        if (mounted) {
          setState(() => _targetWeight = finalValue);
        }
      },
    );
  }

  void _editHeight() {
    _showStyledEditDialog(
      title: 'Height',
      initialValue: _stripUnit(_height, 'ft'), 
      unitSuffix: ' ft', 
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onSave: (newValue) async { 
        final finalValue = '${newValue.trim()} ft';
        await _callAPIs("height", finalValue); 
        LocalDB.setHeight(finalValue);
        if (mounted) {
          setState(() => _height = finalValue);
        }
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
      onSave: (newValue) async { 
        final finalValue = '${newValue.trim()} mL';
        final apiValue = newValue.trim(); // Send only the number to the API
        
        await _callAPIs("waterGoal", apiValue); 
        LocalDB.setWaterGoal(int.tryParse(apiValue) ?? 0);
        if (mounted) {
          setState(() => _waterGoal = finalValue);
        }
      },
    );
  }

  // Health Conditions handler, calls the specialized dialog
  void _editHealthConditions() async {
    final updatedConcerns = await _showHealthConditionsDialog(context, _healthConcerns);

    if (updatedConcerns != null && mounted) {
      // API call is handled inside the dialog. Update local state on success.
      setState(() {
        _healthConcerns = updatedConcerns;
      });
    }
  }


  // Modal Bottom Sheet Dialog for selecting Health Conditions
  Future<Map<String, bool>?> _showHealthConditionsDialog(
      BuildContext context, Map<String, bool> initialConcerns) async {
    
    // Create a mutable copy of the concerns map for the dialog state
    Map<String, bool> tempConcerns = {};
    for (var condition in _kAvailableHealthConcerns) {
      tempConcerns[condition] = initialConcerns[condition] ?? false;
    }

    final _formKey = GlobalKey<FormState>();

    // Returns the updated map on save, or null on cancel
    return await showModalBottomSheet<Map<String, bool>?>(
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    'Health Concerns',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select all conditions that apply to you.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 24),

                  // Status Messages
                  if (errorMessage != null)
                    _StatusMessage(
                      message: errorMessage!,
                      icon: Icons.error_outline,
                      color: Colors.red.shade100,
                      textColor: Colors.red.shade700,
                    ),
                  if (errorMessage != null) const SizedBox(height: 16),
                  
                  // Checkbox List (Scrollable)
                  SizedBox(
                    height: math.min(300, MediaQuery.of(context).size.height * 0.4), 
                    child: SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: _kAvailableHealthConcerns.map((condition) {
                            final isExclusive = condition == "I don't have any";
                            
                            return CheckboxListTile(
                              title: Text(condition, style: const TextStyle(fontSize: 15)),
                              value: tempConcerns[condition] ?? false,
                              onChanged: isLoading ? null : (bool? newValue) {
                                setInnerState(() {
                                  final isSelected = newValue ?? false;
                                  tempConcerns[condition] = isSelected;

                                  // Exclusive selection logic
                                  if (isExclusive && isSelected) {
                                    for (var key in tempConcerns.keys) {
                                      if (key != condition) {
                                        tempConcerns[key] = false;
                                      }
                                    }
                                  } else if (isSelected && !isExclusive) {
                                    tempConcerns["I don't have any"] = false;
                                  }
                                  
                                  // Fallback: if nothing is selected, select "I don't have any"
                                  final hasSelection = tempConcerns.entries.any((e) => e.key != "I don't have any" && e.value == true);
                                  if (!hasSelection) {
                                    tempConcerns["I don't have any"] = true;
                                  }
                                });
                              },
                              activeColor: Theme.of(context).colorScheme.primary,
                              controlAffinity: ListTileControlAffinity.leading,
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isLoading
                              ? null
                              : () => Navigator.of(innerDialogContext).pop(null), // Return null on cancel
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () async {
                                  if (!_formKey.currentState!.validate()) return;
                                  
                                  setInnerState(() {
                                    isLoading = true;
                                    errorMessage = null;
                                  });

                                  try {
                                    // API Call: Send the full updated map to the backend
                                    await _callHealthConcernsAPI(tempConcerns);
                                    
                                    // Success: return the full map to the parent state
                                    setInnerState(() => isLoading = false);
                                    if (mounted) Navigator.of(innerDialogContext).pop(tempConcerns);
                                    
                                  } catch (e) {
                                    final errorMsg = e.toString().replaceFirst("Exception: ", "");
                                    setInnerState(() {
                                      errorMessage = errorMsg;
                                      isLoading = false;
                                    });
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
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
            );
          },
        );
      },
    );
  }


  // Modal Bottom Sheet Dialog for updating Email (multi-step OTP process)
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
                      // Header and Subtitle (dynamically updated)
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
                      
                      // Status Messages
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
                            if (value == null || value.isEmpty || !value.contains('@')) {
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

                      // Action Buttons
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
                                      if (mounted) setState(() => _userEmail = newEmail);
                                      LocalDB.setUserEmail(newEmail);
                                    });

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

  // Modal Bottom Sheet Dialog for changing the user's password
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
                      // Header
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
                      
                      // Status Messages
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
                      
                      // Action Buttons
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


  // General Modal Bottom Sheet for confirmation actions (Logout, Delete)
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
                  // Icon and Header
                  Icon(
                    confirmColor == Colors.red.shade700 ? Icons.warning_amber_rounded : Icons.help_outline,
                    size: 40,
                    color: confirmColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: confirmColor == Colors.red.shade700 ? confirmColor : Theme.of(context).colorScheme.primary,
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

                  // Error Message
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

                  // Action Buttons
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
      confirmColor: Theme.of(context).colorScheme.primary,
      onConfirm: () async {
        await _authService.logout();
        MyApp.restartApp(context); // Optional app restart utility
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
      },
    );
  }
  
  // Handles the account deletion process
  Future<void> _handleAccountDeletion() async {
    try {
      await _authService.deleteAccount();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Account deleted successfully.'),
              backgroundColor: Colors.green),
        );
        MyApp.restartApp(context);
      }
    } catch (e) {
      // Re-throw the exception so the confirmation dialog can display the error
      throw Exception(e.toString().replaceFirst("Exception: ", ""));
    }
  }
}

// ----------------------------------------------------------------------
// 🎨 HELPER WIDGETS
// ----------------------------------------------------------------------

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

/// A custom card with a semi-transparent, blurred background effect.
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

/// A consistently styled divider line.
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

/// A simple animated gradient background for visual flair.
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