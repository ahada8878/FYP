import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fyp/services/config_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'dart:convert';
import 'dart:ui'; // Needed for Color.lerp
import '../../services/config_service.dart';
 
// Configuration constant
const String apiUrl = "$baseURL/upload";

// Formal Color Palette (unchanged from original, aligned with RecipeSuggestion)
const MaterialColor primaryAppColor = MaterialColor(0xFF37474F, <int, Color>{
  50: Color(0xFFECEFF1),
  100: Color(0xFFCFD8DC),
  200: Color(0xFFAAB8C0),
  300: Color(0xFF839AA8),
  400: Color(0xFF678190),
  500: Color(0xFF4F6E7F),
  600: Color(0xFF476677),
  700: Color(0xFF3E5C6B),
  800: Color(0xFF37474F), // Primary
  900: Color(0xFF263238),
});
const Color secondaryAccentColor = Color(0xFF00838F);
const Color safeGreen = Color(0xFF388E3C);
const Color riskyRed = Color(0xFFD32F2F);

// Authentication Service (unchanged)
class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }
}

// State Management
enum ScreenState { initial, loading, results, error }

class LabelScannerPage extends StatefulWidget {
  const LabelScannerPage({super.key});

  @override
  State<LabelScannerPage> createState() => _LabelScannerPageState();
}

// TickerProviderStateMixin is now removed from here, as the background manages its own
class _LabelScannerPageState extends State<LabelScannerPage> { 
  ScreenState _currentState = ScreenState.initial;
  File? _image;
  Map<String, dynamic>? _results;
  String? _errorMessage;
  String? _userToken;
  String? _userId;
  final ImagePicker _picker = ImagePicker();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _fetchToken();
  }

  // Dispose is cleaner as the AnimationController is no longer here
  // @override
  // void dispose() {
  //   super.dispose();
  // }


  Future<void> _fetchToken() async {
    final token = await _authService.getToken();
    final userId = await _authService.getUserId();
    setState(() {
      _userToken = token;
      _userId = userId;
      if (_userToken == null || _userId == null) {
        _errorMessage = "Authentication required. Please log in.";
        _currentState = ScreenState.error;
      }
    });
  }

  // Utility: Text Formatting (unchanged)
  String _capitalizeText(String text) {
    if (text.isEmpty) return 'N/A';
    return text.split(' ').map((word) {
      if (word.isEmpty) return '';
      return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
    }).join(' ');
  }

  String _getFormattedName(Map<String, dynamic> data) {
    final name = data['name'];
    return (name is String && name.isNotEmpty)
        ? _capitalizeText(name)
        : 'Product Name N/A';
  }

  String _getFormattedBrand(Map<String, dynamic> data) {
    final brand = data['brand'];
    return (brand is String && brand.isNotEmpty) ? _capitalizeText(brand) : 'N/A';
  }

  // Logic Fix: Use failure_count for reliable overall status
  Map<String, dynamic> _getOverallSafetyStatus(Map<String, dynamic> productData) {
    final List<dynamic> safetyStatuses = productData['safety_statuses'] ?? [];
    // Prioritize failure_count from the Python script for the main product
    final int failureCount = productData['failure_count'] ?? (
      // Fallback for alternatives or if field is missing: count fails manually
      safetyStatuses.where((s) => s['is_safe'] == false).length
    );

    if (safetyStatuses.isEmpty) {
      return {'is_safe': false, 'emoji': '❓', 'text': 'NO DATA'};
    }
    
    final bool isOverallSafe = (failureCount == 0);
    
    return {
      'is_safe': isOverallSafe,
      'emoji': isOverallSafe ? '✅' : '❌',
      'text': isOverallSafe ? 'SAFE' : 'RISKY',
    };
  }

  // Image Picking (unchanged)
  Future<void> _pickImage() async {
    if (_userToken == null || _userId == null) {
      setState(() {
        _errorMessage = "Cannot scan. Authentication token or user ID is missing. Please log in.";
        _currentState = ScreenState.error;
      });
      return;
    }

    setState(() {
      _currentState = ScreenState.initial;
      _results = null;
      _errorMessage = null;
    });

    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.photo_library, color: primaryAppColor),
                title: const Text('Photo Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: Icon(Icons.camera_alt, color: primaryAppColor),
                title: const Text('Take a Photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return;
    final XFile? pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _currentState = ScreenState.loading;
      });
      _uploadImage(_image!);
    }
  }

  // Image Upload and API Call (unchanged)
  Future<void> _uploadImage(File imageFile) async {
    if (_userToken == null || _userId == null) {
      setState(() {
        _currentState = ScreenState.error;
        _errorMessage = "Missing authorization or user ID.";
      });
      return;
    }

    final String token = _userToken!;
    final String userId = _userId!;

    final Map<String, String> headers = {
      'Authorization': 'Bearer $token',
    };

    try {
      final request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.headers.addAll(headers);
      request.fields['user_id'] = userId;
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
        if (jsonResponse.containsKey('error')) {
          setState(() {
            _errorMessage = jsonResponse['error'] as String;
            _results = null;
            _currentState = ScreenState.error;
          });
        } else {
          setState(() {
            _results = jsonResponse;
            _currentState = ScreenState.results;
          });
        }
      } else if (response.statusCode == 401) {
        setState(() {
          _errorMessage = "Authentication failed. Token is invalid or expired. Please log in.";
          _results = null;
          _currentState = ScreenState.error;
        });
      } else {
        final jsonResponse = jsonDecode(response.body);
        final String serverMessage = jsonResponse['message'] ?? 'Failed to process image due to server error.';
        
        setState(() {
          _errorMessage = "Server error: Status ${response.statusCode}. $serverMessage";
          _results = null;
          _currentState = ScreenState.error;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Network error or failed to connect to server. Details: $e";
        _results = null;
        _currentState = ScreenState.error;
      });
    }
  }

  // Reset Screen (unchanged)
  void _resetScreen() {
    setState(() {
      _currentState = ScreenState.initial;
      _image = null;
      _results = null;
      _errorMessage = null;
    });
  }

  // Product Card Builder (Card color is plain white/default)
  Widget _buildProductCard(Map<String, dynamic> productData, {bool isAlternative = false}) {
    final List<dynamic> safetyStatuses = productData['safety_statuses'] ?? [];
    // Use the whole map in _getOverallSafetyStatus to access failure_count
    final Map<String, dynamic> overallStatus = _getOverallSafetyStatus(productData); 
    final bool isSafe = overallStatus['is_safe'];
    final Color safeColor = safeGreen;
    final Color riskColor = riskyRed;
    
    final Color statusColor = isSafe ? safeColor : riskColor;
    final Color cardColor = Colors.white; // Set card background to plain white
    
    final String statusText = "${overallStatus['emoji']} OVERALL ${overallStatus['text']}";
    final String imageUrl = productData['image_url'] ?? 'https://via.placeholder.com/100?text=No+Image';
    final Map<String, dynamic> nutrients = productData['nutrients'] ?? {};
    final List<MapEntry<String, dynamic>> validNutrients =
        nutrients.entries.where((e) => e.value != null).toList();

    return Card(
      color: cardColor, // Use the plain white card color
      elevation: isAlternative ? 2 : 6,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        // Border color retains the safety status
        side: BorderSide(
            color: statusColor.withOpacity(isAlternative ? 0.3 : 1.0),
            width: isAlternative ? 1 : 3),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image and Name
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    imageUrl,
                    width: isAlternative ? 60 : 80,
                    height: isAlternative ? 60 : 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.image_not_supported,
                        size: isAlternative ? 60 : 80,
                        color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getFormattedName(productData),
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: isAlternative ? 16 : 20,
                            color: Colors.black87),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text('Brand: ${_getFormattedBrand(productData)}',
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey[600])),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(25.0),
                        ),
                        child: Text(
                          statusText,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            // Individual Safety Statuses
            Text('Personalized Safety Checks:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold, color: Colors.black)),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: safetyStatuses.map((status) {
                  // Relies on the 'is_safe' flag added in the Python script
                  final bool statusIsSafe = status['is_safe'] ?? false; 
                  final Color chipColor = statusIsSafe ? safeGreen : riskyRed;
                  // Use the 'name' and 'status_detail' field from the Python output
                  final String chipLabel = '${status['name']} (${status['status_detail']})';

                  return Chip(
                    avatar: Icon(
                      statusIsSafe
                          ? Icons.check_circle_outline
                          : Icons.cancel_outlined,
                      color: chipColor,
                      size: 18,
                    ),
                    label: Text(
                      chipLabel,
                      style: TextStyle(
                          fontSize: 12,
                          color: chipColor,
                          fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: chipColor.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.all(4),
                  );
                }).toList(),
              ),
            ),

            // Nutrient Snapshot
            if (validNutrients.isNotEmpty) ...[
              const SizedBox(height: 15),
              Text('Nutrient Snapshot (per 100g):',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold, color: Colors.black)),
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Wrap(
                  spacing: 12.0,
                  runSpacing: 4.0,
                  children: validNutrients.map((entry) {
                    final key = entry.key
                        .replaceAll('_100g', '')
                        .replaceAll('_kcal', '')
                        .replaceAll('_', ' ');
                    final unit = entry.key.contains('kcal') ? 'kcal' : 'g';
                    final displayColor = primaryAppColor.shade600;

                    return Chip(
                      label: Text(
                        '${_capitalizeText(key)}: ${double.parse(entry.value.toString()).toStringAsFixed(1)}$unit',
                        style: TextStyle(
                            fontSize: 12,
                            color: displayColor,
                            fontWeight: FontWeight.w500),
                      ),
                      backgroundColor: displayColor.withOpacity(0.1),
                      padding: const EdgeInsets.all(4),
                    );
                  }).toList(),
                ),
              ),
            ] else ...[
              const SizedBox(height: 10),
              Text('Nutrient Snapshot: N/A',
                  style: TextStyle(
                      fontStyle: FontStyle.italic, color: Colors.grey[600])),
            ],
          ],
        ),
      ),
    );
  }

  // UI Builders (unchanged)
  Widget _buildBody() {
    switch (_currentState) {
      case ScreenState.results:
        return _buildResultsUI();
      case ScreenState.loading:
        return const Center(child: CircularProgressIndicator());
      case ScreenState.error:
        return _buildErrorUI();
      case ScreenState.initial:
      default:
        return _buildInitialUI();
    }
  }

  Widget _buildInitialUI() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/animation/qr_scanner.json',
            width: 300,
            height: 300,
          ),
          const SizedBox(height: 30),
          Text(
            'Ready to Scan?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            'Take a picture of a product barcode or nutrition label for an instant safety check.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            icon: const Icon(Icons.camera_alt),
            label: const Text('Start Scanning...'),
            onPressed: _pickImage,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorUI() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 60),
          const SizedBox(height: 20),
          const Text('Oops!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(_errorMessage ?? 'An unknown error occurred.', textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _resetScreen,
            style: ElevatedButton.styleFrom(
              backgroundColor: secondaryAccentColor,
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsUI() {
    final product = _results!['product'] as Map<String, dynamic>;
    final alternatives = _results!['alternatives'] as List<dynamic>;
    final limitedAlternatives = alternatives.take(15).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Scanned Product:',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          _buildProductCard(product),
          const SizedBox(height: 24),
          Text(
            'Better Alternatives:',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          if (limitedAlternatives.isEmpty)
            Text(
              'No alternatives found in the same category.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600], fontStyle: FontStyle.italic),
            )
          else
            ...limitedAlternatives.map((alt) => _buildProductCard(alt as Map<String, dynamic>, isAlternative: true)),
        ],
      ),
    );
  }

  // Main Build Method 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Restoring transparent background
      backgroundColor: Colors.transparent, 
      appBar: AppBar(
        title: const Text('Food Scanner'),
        centerTitle: true,
        // Restoring previous light color
        backgroundColor: const Color(0xffa8edea), 
        elevation: 0,
        actions: [
          if (_currentState != ScreenState.initial)
            IconButton(icon: const Icon(Icons.refresh), onPressed: _resetScreen)
        ],
      ),
      // Restoring Stack to layer the background behind the content
      body: Stack(
        children: [
          const _LivingAnimatedBackground(), // Layer 1: The animated background (no controller passed)
          AnimatedSwitcher( // Layer 2: The original page content
            duration: const Duration(milliseconds: 300),
            child: _buildBody(),
          ),
        ],
      ),
    );
  }
}

// CORRECTED: The animated background widget now manages its own state and ticker.
class _LivingAnimatedBackground extends StatefulWidget {
  const _LivingAnimatedBackground();
  
  // Creates the associated state object
  @override
  State<_LivingAnimatedBackground> createState() => _LivingAnimatedBackgroundState();
}

class _LivingAnimatedBackgroundState extends State<_LivingAnimatedBackground>
    with TickerProviderStateMixin { // The TickerProviderStateMixin is here now
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    // Animation controller is initialized here
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 40))
          ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // Interpolate between the two light colors based on the controller's value
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final colors = [
          Color.lerp(
              const Color(0xffa8edea), const Color(0xfffed6e3), _controller.value)!,
          Color.lerp(
              const Color(0xfffed6e3), const Color(0xffa8edea), _controller.value)!,
        ];
        return Container(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: colors)));
      },
    );
  }
}