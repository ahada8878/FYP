import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../../services/config_service.dart';

// --- API Configuration ---
// IMPORTANT: Use 10.0.2.2 for Android Emulator, or your actual local IP for a physical device.
const String apiUrl = "http://$apiIpAddress:3000/upload";

// --- Formal Color Palette: Dark Gray and Teal ---
const MaterialColor primaryAppColor = MaterialColor(0xFF37474F, <int, Color>{
  50: Color(0xFFECEFF1),
  100: Color(0xFFCFD8DC),
  200: Color(0xFFB0BEC5),
  300: Color(0xFF90A4AE),
  400: Color(0xFF78909C),
  500: Color(0xFF607D8B),
  600: Color(0xFF546E7A),
  700: Color(0xFF455A64),
  800: Color(0xFF37474F), // Deep Formal Gray/Blue (Primary)
  900: Color(0xFF263238), // Darkest Gray/Blue
});

// Teal for secondary accent
const Color secondaryAccentColor = Color(0xFF00838F);
// Colors for status chips
const Color safeGreen = Color(0xFF388E3C);
const Color riskyRed = Color(0xFFD32F2F);

// ----------------------------------------------------------------------

// The original 'LabelScannerPage' is now a stateful widget that holds the scanner logic.
class LabelScannerPage extends StatefulWidget {
  const LabelScannerPage({super.key});

  @override
  State<LabelScannerPage> createState() => _LabelScannerPageState();
}

class _LabelScannerPageState extends State<LabelScannerPage> {
  File? _image;
  Map<String, dynamic>? _results;
  bool _isLoading = false;
  String? _errorMessage;
  bool _showResults = false;

  final ImagePicker _picker = ImagePicker();

  // --- Utility: Text Formatting ---
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
    return (brand is String && brand.isNotEmpty)
        ? _capitalizeText(brand)
        : 'N/A';
  }
  // -------------------------------------

  // --- Utility: Safety Status Check ---
  Map<String, dynamic> _getOverallSafetyStatus(List<dynamic> safetyStatuses) {
    if (safetyStatuses.isEmpty) {
      return {'is_safe': false, 'emoji': '❓', 'text': 'NO DATA'};
    }

    final bool isOverallSafe =
        safetyStatuses.every((s) => s['is_safe'] == true);

    return {
      'is_safe': isOverallSafe,
      'emoji': isOverallSafe ? '✅' : '❌',
      'text': isOverallSafe ? 'SAFE' : 'RISKY',
    };
  }
  // -------------------------------------

  // 1. Image Picking Function
  Future<void> _pickImage() async {
    // Clear previous results and start loading
    setState(() {
      _showResults = false;
      _results = null;
      _errorMessage = null;
    });

    final Color primary = Theme.of(context).primaryColor;

    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.photo_library, color: primary),
                title: const Text('Photo Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: Icon(Icons.camera_alt, color: primary),
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
      });
      _uploadImage(_image!);
    }
  }

  // 2. Image Upload and API Call
  Future<void> _uploadImage(File imageFile) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;

        if (jsonResponse.containsKey('error')) {
          _errorMessage = jsonResponse['error'] as String;
          _results = null;
        } else {
          _results = jsonResponse;
        }
      } else {
        _errorMessage =
            "Server error: Status ${response.statusCode}. Details: ${response.body}";
        _results = null;
      }
    } catch (e) {
      _errorMessage =
          "Network error or failed to connect to server. Check IP and port. Details: $e";
      _results = null;
    } finally {
      setState(() {
        _isLoading = false;
        if (_results != null && _errorMessage == null) {
          _showResults = true;
        }
      });
    }
  }

  // 3. Helper to build a visually distinct settings chip (Kept for completeness)
  Widget _buildSettingsChip(String label, String type) {
    final bool isCondition = type == 'Condition';
    final Color color =
        isCondition ? primaryAppColor.shade600 : secondaryAccentColor;
    final IconData icon =
        isCondition ? Icons.favorite_border : Icons.restaurant_menu;

    return Chip(
      avatar: Icon(icon, color: Colors.white, size: 16),
      label: Text(
        label,
        style: const TextStyle(
            fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
      ),
      backgroundColor: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    );
  }

  // 4. UI Component for Product Card
  Widget _buildProductCard(Map<String, dynamic> productData,
      {bool isAlternative = false}) {
    final List<dynamic> safetyStatuses = productData['safety_statuses'] ?? [];
    final Map<String, dynamic> overallStatus =
        _getOverallSafetyStatus(safetyStatuses);
    final bool isSafe = overallStatus['is_safe'];

    // Use defined formal colors
    const Color safeColor = safeGreen;
    const Color riskColor = riskyRed;

    final Color cardColor =
        isSafe ? primaryAppColor.shade50 : Colors.red.shade50;
    final Color statusColor = isSafe ? safeColor : riskColor;
    final String statusText =
        "${overallStatus['emoji']} OVERALL ${overallStatus['text']}";
    final String imageUrl = productData['image_url'] ??
        'https://via.placeholder.com/100?text=No+Image';
    final Map<String, dynamic> nutrients = productData['nutrients'] ?? {};

    final List<MapEntry<String, dynamic>> validNutrients =
        nutrients.entries.where((e) => e.value != null).toList();

    return Card(
      color: cardColor,
      elevation: isAlternative ? 2 : 6,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
            color: statusColor.withOpacity(isAlternative ? 0.3 : 1.0),
            width: isAlternative ? 1 : 3),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Product Image and Name ---
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
                      // Formatted Name
                      Text(
                        _getFormattedName(productData),
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: isAlternative ? 16 : 20,
                            color: Colors.black87),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Formatted Brand
                      Text('Brand: ${_getFormattedBrand(productData)}',
                          style: const TextStyle(
                              fontSize: 14, color: Colors.grey)),
                      const SizedBox(height: 8),
                      // Overall Safety Status Tag
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

            // --- Individual Safety Statuses (Conditions & Preferences) ---
            const Text('Personalized Safety Checks:',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.black)),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: safetyStatuses.map((status) {
                  final bool statusIsSafe = status['is_safe'] ?? false;
                  final Color chipColor = statusIsSafe ? safeGreen : riskyRed;
                  final String chipLabel = '${status['name']}';

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

            // --- Nutrient Snapshot ---
            if (validNutrients.isNotEmpty) ...[
              const SizedBox(height: 15),
              const Text('Nutrient Snapshot (per 100g):',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.black)),
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
              const Text('Nutrient Snapshot: N/A',
                  style: TextStyle(
                      fontStyle: FontStyle.italic, color: Colors.grey)),
            ],
          ],
        ),
      ),
    );
  }

  // 5. Build Results Display
  Widget _buildResultsDisplay() {
    final product = _results!['product'] as Map<String, dynamic>;
    final alternatives = _results!['alternatives'] as List<dynamic>;

    final List<dynamic> limitedAlternatives = alternatives.take(15).toList();

    return AnimatedOpacity(
      opacity: _showResults ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Scanned Product:',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87),
          ),
          const SizedBox(height: 10),
          _buildProductCard(product),

          const SizedBox(height: 20),

          const Row(
            children: [
              Icon(Icons.local_dining, color: Colors.black87, size: 24),
              SizedBox(width: 8),
              Text(
                'Better Alternatives:',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (limitedAlternatives.isEmpty)
            const Text('No alternatives found in the same category.',
                style:
                    TextStyle(fontStyle: FontStyle.italic, color: Colors.grey))
          else
            // Iterate over the limited list
            ...limitedAlternatives
                .map((alt) => _buildProductCard(alt as Map<String, dynamic>,
                    isAlternative: true))
                ,
        ],
      ),
    );
  }

  // 6. Scanner Content Builder (Initial/Error State)
  Widget _buildScannerContent(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;

    if (_results != null || _errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.only(
            top: 8.0), // Added slight top padding for breathing room
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    color: Colors.red.shade100,
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        '⚠️ Connection Error: $_errorMessage',
                        style: const TextStyle(
                            color: Colors.red, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            if (_results != null) _buildResultsDisplay(),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // --- Creative Circular Scanner Button (Initial Screen) ---
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: _isLoading ? 250 : 120,
            height: 120,
            decoration: BoxDecoration(
              color: primaryAppColor, // Deep Gray/Blue
              borderRadius: BorderRadius.circular(_isLoading ? 60 : 60),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.6),
                  blurRadius: 15,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: InkWell(
              onTap: _isLoading ? null : _pickImage,
              borderRadius: BorderRadius.circular(60),
              child: Center(
                child: _isLoading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Scanning...',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      )
                    : const Icon(Icons.camera_alt_rounded,
                        color: Colors.white, size: 50),
              ),
            ),
          ),
          // --- End Creative Button ---

          const SizedBox(height: 30),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              'Tap the lens icon to scan a product barcode or nutrition label for an instant safety check.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // 7. Helper: Build the Floating Camera Button 
  Widget _buildFloatingCamera() {
    final Color buttonColor = Theme.of(context).colorScheme.secondary;

    return Transform.translate(
      offset: const Offset(0.0, -20.0),
      child: FittedBox(
        child: Container(
          // Set the explicit size of the Container
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: buttonColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.8), // White shadow color
                spreadRadius: 3,
                blurRadius: 10,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: _isLoading ? null : _pickImage,
            elevation: 0,
            shape: const CircleBorder(),
            backgroundColor: primaryAppColor,
            // Set the icon size relative to the button size (optional)
            child: const Icon(
              Icons.camera_alt_rounded,
              color: Colors.white,
              size: 30, // Increased icon size slightly for the larger button
            ),
          ),
        ),
      ),
    );
  }

  // 8. Main Widget Build Method
  @override
  Widget build(BuildContext context) {
    final bool showResultsOrError = _results != null || _errorMessage != null;
    final Color primaryColor = primaryAppColor.shade800; // Use defined color

    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Scanner'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),

      // 1. Use the Scaffold's FAB for guaranteed drawing priority (z-index)
      floatingActionButton: showResultsOrError ? _buildFloatingCamera() : null,

      // 2. Use a custom location to make it appear near the AppBar
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndTop,

      // 3. Body now contains only the content
      body: SingleChildScrollView(
        // Use a fixed padding at the top of the ScrollView to account for the FAB location
        padding: const EdgeInsets.only(
            left: 16.0, right: 16.0, bottom: 16.0, top: 16.0),
        child: showResultsOrError
            ? _buildScannerContent(context)
            : SizedBox(
                // Recalculate height needed for centering the main prompt
                height: MediaQuery.of(context).size.height -
                    kToolbarHeight -
                    MediaQuery.of(context).padding.top -
                    32,
                child: _buildScannerContent(context),
              ),
      ),
    );
  }
}