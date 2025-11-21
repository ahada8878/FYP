import 'dart:io';
import 'dart:convert';
import 'dart:ui'; // For BackdropFilter
import 'package:flutter/material.dart';
import '../../services/config_service.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import '../camera_screen.dart';
import 'dart:async'; 
import 'recipe_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

// --- 🎨 COLOR PALETTE ---
const Color safeGreen = Color(0xFF2E7D32);
const Color calorieOrange = Color(0xFFFF6D00);
const Color darkText = Color(0xFF2D3436);
const Color greyText = Color(0xFF636E72);

// --- CONFIGURATION ---
const String _spoonacularApiKey = '3ae6af7175864f2b96f71cf261f1e16a'; 

// --- DATA MODELS ---
class DetectedIngredient {
  final String name;
  final List<double> box; 
  DetectedIngredient({required this.name, required this.box});
}

class ImageDimensions {
  final double width;
  final double height;
  ImageDimensions({required this.width, required this.height});
}

class Recipe {
  final double id;
  final String title;
  final String imageUrl;
  final int usedIngredientCount;
  final int missedIngredientCount;

  Recipe({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.usedIngredientCount,
    required this.missedIngredientCount,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: (json['id'] as num).toDouble(),
      title: json['title'],
      imageUrl: json['image'] ?? '', 
      usedIngredientCount: json['usedIngredientCount'] ?? 0,
      missedIngredientCount: json['missedIngredientCount'] ?? 0,
    );
  }
}

enum ScreenState { initial, loading, review, success, error }

class RecipeSuggestion extends StatefulWidget {
  const RecipeSuggestion({super.key});
  @override
  State<RecipeSuggestion> createState() => _RecipeSuggestionState();
}

class _RecipeSuggestionState extends State<RecipeSuggestion> {
  ScreenState _currentState = ScreenState.initial;
  List<DetectedIngredient> _detectedIngredients = [];
  List<String> _finalIngredients = [];
  ImageDimensions? _imageDimensions;
  String? _imagePath;
  List<Recipe> _recipes = [];
  String _errorMessage = '';
  final _ingredientTextController = TextEditingController();

  final String _detectionServerUrl = '$baseURL/api/detect-ingredients';

  // --- API LOGIC ---
  Future<void> _detectIngredients(String imagePath) async {
    setState(() {
      _currentState = ScreenState.loading;
      _imagePath = imagePath;
    });

    try {
      var uri = Uri.parse(_detectionServerUrl);
      var request = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath('image', imagePath));
      var response = await request.send();

      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final result = json.decode(respStr);
        final List<dynamic> detections = result['detections'];
        final Map<String, dynamic> dims = result['image_dimensions'];

        setState(() {
          _detectedIngredients = detections.map((d) {
            final boxList = (d['box'] as List).map((coord) => (coord as num).toDouble()).toList();
            return DetectedIngredient(name: d['name'], box: boxList);
          }).toList();

          _finalIngredients = _detectedIngredients.map((e) => e.name).toSet().toList(); 

          _imageDimensions = ImageDimensions(
            width: (dims['width'] as num).toDouble(),
            height: (dims['height'] as num).toDouble()
          );

          _currentState = ScreenState.review;
        });
      } else {
        throw Exception('Detection failed: ${response.reasonPhrase}');
      }
    } catch (e) {
      setState(() { _errorMessage = 'AI Detection Failed. Please try again.'; _currentState = ScreenState.error; });
    }
  }

  Future<void> _findRecipes() async {
    setState(() => _currentState = ScreenState.loading);
    try {
      if (_finalIngredients.isEmpty) throw Exception('No ingredients selected.');

      final ingredientsString = _finalIngredients.join(',');
      final uri = Uri.https(
        'api.spoonacular.com',
        '/recipes/findByIngredients',
        {
          'ingredients': ingredientsString,
          'number': '10', 
          'ranking': '1',
          'apiKey': _spoonacularApiKey,
        }
      );

      var response = await http.get(uri);

      if(response.statusCode == 200) {
        final List<dynamic> recipeData = json.decode(response.body);
        setState(() {
          _recipes = recipeData.map((data) => Recipe.fromJson(data)).toList();
          _currentState = ScreenState.success;
        });
      } else {
        throw Exception('Recipe search failed. Status: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not fetch recipes. Check your internet.';
        _currentState = ScreenState.error;
      });
    }
  }

  // --- UI ACTIONS ---
  void _startCooking() async {
    final imagePath = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (context) => const CameraScreen()),
    );
    if (imagePath != null) _detectIngredients(imagePath);
  }

  void _addIngredient() {
    final text = _ingredientTextController.text.trim();
    if(text.isNotEmpty && !_finalIngredients.contains(text.toLowerCase())) {
        setState(() => _finalIngredients.add(text.toLowerCase()));
    }
    _ingredientTextController.clear();
    FocusScope.of(context).unfocus();
  }

  void _resetScreen() {
    setState(() {
      _currentState = ScreenState.initial;
      _detectedIngredients = [];
      _finalIngredients = [];
      _recipes = [];
      _imagePath = null;
    });
  }

  // --- WIDGET BUILDERS ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        // MODIFIED: Show Title on Initial, Error, Loading AND Review screens. Hide only on Success (Results).
        title: _currentState != ScreenState.success
            ?  Text('Chef Assistant', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary))
            : null,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon:  Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).colorScheme.primary),
          onPressed: _currentState == ScreenState.success ? _resetScreen : () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          const _LivingAnimatedBackground(),
          Container(color: Colors.white.withOpacity(0.3)), // White Tint
          SafeArea(
            bottom: false,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentState) {
      case ScreenState.initial: return _buildInitialUI();
      case ScreenState.loading: return _buildLoadingUI();
      case ScreenState.review: return _buildReviewUI();
      case ScreenState.success: return _buildResultsUI();
      case ScreenState.error: return _buildErrorUI();
    }
  }

  // 1. INITIAL STATE
  Widget _buildInitialUI() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
                padding: const EdgeInsets.all(20), 
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5), 
                    shape: BoxShape.circle, 
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 30)]
                ), 
                child: Lottie.asset('assets/animation/Prepare_Food.json', width: 220, height: 220)
            ),
            const SizedBox(height: 40),
            Text(
              'Ready to Cook?',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 50),
              child: Text(
                'Snap a photo of your ingredients and let AI create a recipe for you.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: greyText, height: 1.5),
              ),
            ),
            const SizedBox(height: 40),
            InkWell(
              onTap: _startCooking,
              borderRadius: BorderRadius.circular(50),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 18),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))]
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.camera_alt_rounded, color: Colors.white), 
                    SizedBox(width: 10), 
                    Text("SCAN INGREDIENTS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  // 2. LOADING STATE
  Widget _buildLoadingUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 20),
          const Text("Analyzing your pantry...", style: TextStyle(color: greyText, fontWeight: FontWeight.w600))
        ],
      ),
    );
  }

  // 3. ERROR STATE
  Widget _buildErrorUI() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 80, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 20),
            const Text("Something went wrong", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: darkText)),
            const SizedBox(height: 10),
            Text(_errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: greyText, fontSize: 15)),
            const SizedBox(height: 30),
            InkWell(
              onTap: _resetScreen,
              borderRadius: BorderRadius.circular(50),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary, 
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Text("TRY AGAIN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  // 4. REVIEW INGREDIENTS STATE (Fixed Center Alignment)
  Widget _buildReviewUI() {
    return SingleChildScrollView(
      // Padded to avoid AppBar overlap
      padding: const EdgeInsets.only(top: 30.0, left: 20.0, right: 20.0, bottom: 40.0),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- CENTERED HEADER START ---
           Center(
            child: Text(
              "Ingredients Detected", 
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.primary)
            ),
          ),
          const SizedBox(height: 5),
          const Center(
            child: Text(
              "Verify extracted items below", 
              textAlign: TextAlign.center,
              style: TextStyle(color: greyText)
            ),
          ),
          // --- CENTERED HEADER END ---

          const SizedBox(height: 20),
          
          // Image Viewer
          if (_imagePath != null && _imageDimensions != null)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))]
              ),
              child: BoundingBoxImage(
                imagePath: _imagePath!,
                ingredients: _detectedIngredients,
                originalImageDims: _imageDimensions!,
              ),
            ),
          
          const SizedBox(height: 30),
          
          // Ingredient Chips
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: _finalIngredients.map((ingredient) => Chip(
              label: Text(ingredient, style: const TextStyle(fontWeight: FontWeight.w600)),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.shade300)),
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: () => setState(() => _finalIngredients.remove(ingredient)),
            )).toList(),
          ),

          const SizedBox(height: 20),

          // Add Ingredient Field
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
            ),
            child: TextField(
              controller: _ingredientTextController,
              decoration: InputDecoration(
                hintText: 'Add missing ingredient...',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                suffixIcon: IconButton(
                  icon: Icon(Icons.add_circle, color: Theme.of(context).colorScheme.primary),
                  onPressed: _addIngredient,
                )
              ),
            ),
          ),

          const SizedBox(height: 30),

          // Find Recipes Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _findRecipes,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 5,
                shadowColor: Colors.black.withOpacity(0.3)
              ),
              child: const Text("FIND RECIPES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }

  // 5. RESULTS STATE
  Widget _buildResultsUI() {
    if (_recipes.isEmpty) {
      return const Center(child: Text('No recipes found for the detected ingredients.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 10, bottom: 40),
      physics: const BouncingScrollPhysics(),
      itemCount: _recipes.length,
      itemBuilder: (context, index) {
        final recipe = _recipes[index];
        return RecipeCard(recipe: recipe);
      },
    );
  }
}

// --- 🎨 CUSTOM WIDGETS ---

// 1. Bounding Box Image
class BoundingBoxImage extends StatelessWidget {
  final String imagePath;
  final List<DetectedIngredient> ingredients;
  final ImageDimensions originalImageDims;

  const BoundingBoxImage({
    super.key,
    required this.imagePath,
    required this.ingredients,
    required this.originalImageDims,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double scaleX = constraints.maxWidth / originalImageDims.width;
        final double scaleY = (constraints.maxWidth / originalImageDims.width) * originalImageDims.height > 400
                            ? 400 / originalImageDims.height
                            : scaleX;
        final double containerHeight = originalImageDims.height * scaleY;

        return ClipRRect(
          borderRadius: BorderRadius.circular(20.0),
          child: SizedBox(
            height: containerHeight,
            child: Stack(
              children: [
                Image.file(File(imagePath), fit: BoxFit.contain, width: double.infinity),
                ...ingredients.map((ing) {
                  return Positioned(
                    left: ing.box[0] * scaleX,
                    top: ing.box[1] * scaleY,
                    width: (ing.box[2] - ing.box[0]) * scaleX,
                    height: (ing.box[3] - ing.box[1]) * scaleY,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: safeGreen, width: 2),
                        borderRadius: BorderRadius.circular(4),
                        color: safeGreen.withOpacity(0.2)
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

// 2. Beautiful Glass Recipe Card
class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  const RecipeCard({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            // Full Background Image
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: recipe.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.grey.shade200),
                errorWidget: (context, url, error) => Container(color: Colors.grey.shade300, child: const Icon(Icons.restaurant, size: 50, color: Colors.grey)),
              ),
            ),
            
            // Gradient Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
            ),

            // Content
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      border: Border(top: BorderSide(color: Colors.white.withOpacity(0.2)))
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, height: 1.2),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _buildBadge(Icons.check_circle, "${recipe.usedIngredientCount} Used", safeGreen),
                            const SizedBox(width: 10),
                            _buildBadge(Icons.shopping_bag, "${recipe.missedIngredientCount} Missing", calorieOrange),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Ripple Effect for Click
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RecipeDetailScreen(recipeId: recipe.id.toInt()))),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// --- BACKGROUND ANIMATION ---
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