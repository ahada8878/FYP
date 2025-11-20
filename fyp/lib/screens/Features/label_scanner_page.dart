import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fyp/services/config_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';

// Configuration
const String apiUrl = "$baseURL/upload";

// --- 🎨 COLOR PALETTE ---
const Color safeGreen = Color(0xFF2E7D32); 
const Color riskyRed = Color(0xFFD32F2F);   
const Color darkText = Color(0xFF2D3436);
const Color greyText = Color(0xFF636E72);
const Color lightBg = Color(0xFFFAFAFA);

// Auth Service
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

enum ScreenState { initial, loading, results, error }

class LabelScannerPage extends StatefulWidget {
  const LabelScannerPage({super.key});
  @override
  State<LabelScannerPage> createState() => _LabelScannerPageState();
}

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

  Future<void> _fetchToken() async {
    final token = await _authService.getToken();
    final userId = await _authService.getUserId();
    setState(() {
      _userToken = token;
      _userId = userId;
    });
  }

  // --- HELPERS ---
  String _capitalize(String text) {
    if (text.isEmpty) return 'N/A';
    return text.split(' ').map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}' : '').join(' ');
  }

  Map<String, dynamic> _getStatus(Map<String, dynamic> productData) {
    final List<dynamic> statuses = productData['safety_statuses'] ?? [];
    final int fails = productData['failure_count'] ?? (statuses.where((s) => s['is_safe'] == false).length);
    
    if (statuses.isEmpty) return {'is_safe': false, 'text': 'NO DATA', 'icon': Icons.help_outline, 'color': Colors.grey};

    bool isSafe = fails == 0;
    return {
      'is_safe': isSafe,
      'text': isSafe ? 'EXCELLENT' : 'ATTENTION',
      'subtext': isSafe ? 'Clean & Safe Product' : 'Additives / Allergens Detected',
      'icon': isSafe ? Icons.verified_user_rounded : Icons.warning_amber_rounded,
      'color': isSafe ? safeGreen : riskyRed,
    };
  }

  // --- ACTIONS ---
  Future<void> _pickImage() async {
    if (_userToken == null) return;
    final ImageSource? source = await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (c) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: const Icon(Icons.photo_library, color: Colors.teal), title: const Text('Gallery'), onTap: () => Navigator.pop(c, ImageSource.gallery)),
        ListTile(leading: const Icon(Icons.camera_alt, color: Colors.teal), title: const Text('Camera'), onTap: () => Navigator.pop(c, ImageSource.camera)),
      ])),
    );
    if (source == null) return;
    final XFile? picked = await _picker.pickImage(source: source);
    if (picked != null) {
      setState(() { _image = File(picked.path); _currentState = ScreenState.loading; });
      _uploadImage(_image!);
    }
  }

  Future<void> _uploadImage(File f) async {
    try {
      final req = http.MultipartRequest('POST', Uri.parse(apiUrl));
      req.headers['Authorization'] = 'Bearer $_userToken';
      req.fields['user_id'] = _userId!;
      req.files.add(await http.MultipartFile.fromPath('image', f.path));
      final res = await http.Response.fromStream(await req.send());
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['error'] != null) {
          setState(() { _errorMessage = data['error']; _currentState = ScreenState.error; });
        } else {
          setState(() { _results = data; _currentState = ScreenState.results; });
        }
      } else {
        setState(() { _errorMessage = "Server Error: ${res.statusCode}"; _currentState = ScreenState.error; });
      }
    } catch (e) {
      setState(() { _errorMessage = "Network Error"; _currentState = ScreenState.error; });
    }
  }

  void _reset() => setState(() { _currentState = ScreenState.initial; _image = null; _results = null; });

  // --- 🎨 UI BUILDERS ---

  // 1. THE HEADER
  Widget _buildHeaderResult(Map<String, dynamic> product, Map<String, dynamic> status) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Background Image Container
        Container(
          width: double.infinity,
          height: 320,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 10))],
            image: DecorationImage(
              image: const CachedNetworkImageProvider("https://images.pexels.com/photos/15182665/pexels-photo-15182665.jpeg"),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.2), BlendMode.darken),
            ),
          ),
          // --- BLUR EFFECT STARTS HERE ---
          child: ClipRRect(
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(
                color: Colors.transparent,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (status['color'] as Color).withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: status['color'], width: 2),
                      ),
                      child: Icon(status['icon'], size: 40, color: status['color']),
                    ),
                    const SizedBox(height: 12),
                    Text(status['text'], style: TextStyle(color: status['color'], fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 2)),
                    Text(status['subtext'], style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Floating Product Image
        Positioned(
          bottom: -50,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 25, offset: const Offset(0, 10))]
            ),
            child: CircleAvatar(
              radius: 65,
              backgroundColor: Colors.white,
              backgroundImage: NetworkImage(product['image_url'] ?? ''),
              onBackgroundImageError: (_, __) => const Icon(Icons.image_not_supported),
            ),
          ),
        )
      ],
    );
  }

  // 2. DASHBOARD
  Widget _buildNutrientDashboard(Map<String, dynamic>? nutrients) {
    if (nutrients == null) return const SizedBox();
    
    final items = [
      {'key': 'energy_kcal', 'label': 'Calories', 'unit': '', 'color': Colors.orange, 'icon': Icons.local_fire_department_rounded},
      {'key': 'proteins_100g', 'label': 'Protein', 'unit': 'g', 'color': Colors.blue, 'icon': Icons.fitness_center_rounded},
      {'key': 'carbohydrates_100g', 'label': 'Carbs', 'unit': 'g', 'color': Colors.amber, 'icon': Icons.grain_rounded},
      {'key': 'fat_100g', 'label': 'Fat', 'unit': 'g', 'color': Colors.redAccent, 'icon': Icons.water_drop_rounded},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 15),

          const Text("NUTRITION DASHBOARD", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black, letterSpacing: 1.2)),
          const SizedBox(height: 15),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 1.5),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final val = nutrients[item['key']] ?? '-';
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20), 
                  border: Border.all(color: Colors.grey.shade500),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item['icon'] as IconData, color: item['color'] as Color, size: 28),
                    const SizedBox(height: 8),
                    Text("${item['label']}", style: const TextStyle(fontSize: 12, color: greyText, fontWeight: FontWeight.w600)),
                    Text("$val${item['unit']}", style: const TextStyle(fontSize: 20, color: darkText, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 3. TIMELINE
  Widget _buildSafetyTimeline(List<dynamic>? checks) {
    if (checks == null || checks.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [

          const Text("INGREDIENT ANALYSIS", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black, letterSpacing: 1.2)),
          const SizedBox(height: 15),
          ListView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: checks.length,
            itemBuilder: (context, index) {
              final check = checks[index];
              final isSafe = check['is_safe'] == true;
              return IntrinsicHeight(
                child: Row(
                  children: [
                    Column(
                      children: [
                        Container(width: 1, height: 20, color: Colors.grey.shade500),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: isSafe ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE), shape: BoxShape.circle, border: Border.all(color: isSafe ? Colors.green : Colors.red, width: 2)),
                          child: Icon(isSafe ? Icons.check : Icons.priority_high, size: 14, color: isSafe ? Colors.green : Colors.red),
                        ),
                        Expanded(child: Container(width: 1, color: Colors.grey.shade500)),
                      ],
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white, 
                          borderRadius: BorderRadius.circular(15), 
                          border: Border.all(color: Colors.grey.shade500),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(check['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: darkText)),
                            const SizedBox(height: 4),
                            Text(check['status_detail'] ?? '', style: TextStyle(fontSize: 13, color: isSafe ? greyText : Colors.redAccent)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          )
        ],
      ),
    );
  }

  // 4. ALTERNATIVES
  Widget _buildAlternatives(List<dynamic> alts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text("BETTER CHOICES", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black, letterSpacing: 1.2)),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 20, right: 10),
            physics: const BouncingScrollPhysics(),
            itemCount: alts.length,
            itemBuilder: (context, index) {
              final alt = alts[index];
              return Container(
                width: 140,
                margin: const EdgeInsets.only(right: 15, bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white, 
                  borderRadius: BorderRadius.circular(20), 
                  border: Border.all(color: Colors.grey.shade400),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 3, offset: const Offset(0, 5))]
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Image.network(alt['image_url'] ?? '', fit: BoxFit.contain, errorBuilder: (c,e,s) => const Icon(Icons.broken_image, color: Colors.grey)),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: lightBg, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20))),
                      child: Column(
                        children: [
                          Text(_capitalize(alt['name'] ?? ''), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: darkText)),
                          const SizedBox(height: 4),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: const Text("Safe Swap", style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold))),
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- MAIN BUILDERS ---

  Widget _buildResults() {
    final product = _results!['product'];
    final alts = _results!['alternatives'];
    final status = _getStatus(product);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 50),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildHeaderResult(product, status),
          const SizedBox(height: 60), 
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              _capitalize(product['name'] ?? ''), 
              textAlign: TextAlign.center, 
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: darkText)
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              _capitalize(product['brand'] ?? ''), 
              textAlign: TextAlign.center, 
              style: const TextStyle(fontSize: 14, color: greyText, fontWeight: FontWeight.w600)
            ),
          ),

          const SizedBox(height: 30),
          _buildNutrientDashboard(product['nutrients']),
          const SizedBox(height: 40),
          _buildSafetyTimeline(product['safety_statuses']),
          const SizedBox(height: 40),
          if (alts.isNotEmpty) _buildAlternatives(alts),
        ],
      ),
    );
  }

  Widget _buildInitial() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 70,),
          Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color:  Colors.white.withOpacity(0.5), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 30)]), child: Lottie.asset('assets/animation/qr_scanner.json', width: 200, height: 200)),
          const SizedBox(height: 40),
           Text("Scan Product", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.primary,)),
          const SizedBox(height: 10),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 50), child: Text("Point your camera at a barcode or nutrition label for an instant health analysis.", textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: greyText))),
          const SizedBox(height: 40),
          InkWell(
            onTap: () { HapticFeedback.lightImpact(); _pickImage(); },
            borderRadius: BorderRadius.circular(50),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 18),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(50), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8))]),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.center_focus_weak, color: Colors.white), SizedBox(width: 10), Text("START SCAN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))]),
            ),
          )
        ],
      ),
    );
  }

  // --- MAIN BUILDERS (Error Screen Update) ---

Widget _buildError(BuildContext context) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Error Icon
          Icon(
            Icons.sentiment_dissatisfied_rounded,
            size: 76,
            color: Theme.of(context).colorScheme.primary,
          ),

          const SizedBox(height: 30),

          // Title
          Text(
            "Scan Failed",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: darkText,
            ),
          ),

          // Error Message
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Text(
              _errorMessage ??
                  "An unexpected error occurred while processing the image. Please try again.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: greyText,
                fontSize: 16,
                height: 1.4,
              ),
            ),
          ),

          const SizedBox(height: 30),

          // Try Again Button
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              _reset();
            },
            borderRadius: BorderRadius.circular(50),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 18),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "TRY AGAIN",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        // MODIFIED: Show title if Initial OR Error state
        title: (_currentState == ScreenState.initial || _currentState == ScreenState.error) 
            ? Text("Scanner", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary,)) 
            : null,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _currentState == ScreenState.results 
            ? IconButton(icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white,), onPressed: _reset) 
            : Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).colorScheme.primary,)
      ),  
      // Stack handles the background + content
      body: Stack(
        children: [
          const _LivingAnimatedBackground(), // The gradient
          Container(color: Colors.white.withOpacity(0.2)), // The tint you requested
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: _currentState == ScreenState.loading 
              ?  Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)) 
              : _currentState == ScreenState.results 
                  ? _buildResults() 
                  : _currentState == ScreenState.error 
                      ? _buildError(context) 
                      : _buildInitial()
          ),
        ],
      ),
    );
  }
}

// --- BACKGROUND ---
class _LivingAnimatedBackground extends StatefulWidget {
  const _LivingAnimatedBackground();
  @override
  State<_LivingAnimatedBackground> createState() => _LivingAnimatedBackgroundState();
}
class _LivingAnimatedBackgroundState extends State<_LivingAnimatedBackground> with TickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(seconds: 40))..repeat(reverse: true); }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: _c, builder: (ctx, _) => Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color.lerp(const Color(0xffa8edea), const Color(0xfffed6e3), _c.value)!, Color.lerp(const Color(0xfffed6e3), const Color(0xffa8edea), _c.value)!]))));
}