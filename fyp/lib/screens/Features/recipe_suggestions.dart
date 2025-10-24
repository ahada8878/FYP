import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/config_service.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import '../camera_screen.dart';
import 'dart:async'; // For Completer
import 'recipe_detail_screen.dart';
import 'dart:ui'; // Already here, but needed for the background

// --- CONFIGURATION CONSTANTS (ADD THESE) ---
// NOTE: For a real app, use a proper environment variable solution
const String _spoonacularApiKey = '3ae6af7175864f2b96f71cf261f1e16a'; // Replace with your actual key if needed
// The base URL for the ingredient detection service remains local
// const String baseURL = '$baseURL'; // <-- IMPORTANT: Use your PC's IP address

// --- DATA MODELS ---
class DetectedIngredient {
  final String name;
  final List<double> box; // [x_min, y_min, x_max, y_max]
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
    // Spoonacular IDs are often integers, but using double for safety with JSON parsing
    return Recipe(
      id: (json['id'] as num).toDouble(),
      title: json['title'],
      imageUrl: json['image'],
      usedIngredientCount: json['usedIngredientCount'] ?? 0,
      missedIngredientCount: json['missedIngredientCount'] ?? 0,
    );
  }
}

// --- STATE MANAGEMENT ---
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

  // NOTE: Server IP moved to constant above for clarity
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
// recipe_suggestions.dart (inside _detectIngredients)

// ...
      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        // The response is now the direct JSON from the detection script.
        final result = json.decode(respStr);

        final List<dynamic> detections = result['detections'];
        final Map<String, dynamic> dims = result['image_dimensions']; // <-- Use Map<String, dynamic> for type safety

        setState(() {
          _detectedIngredients = detections.map((d) {
            // ✅ FIX: Manually map the list to ensure all values are doubles
            final boxList = (d['box'] as List)
                .map((coord) => (coord as num).toDouble())
                .toList();

            return DetectedIngredient(
              name: d['name'],
              box: boxList, // Use the new, safe list
            );
          }).toList();

          _finalIngredients = _detectedIngredients.map((e) => e.name).toSet().toList(); 

          _imageDimensions = ImageDimensions(
            width: (dims['width'] as num).toDouble(),
            height: (dims['height'] as num).toDouble()
          );

          _currentState = ScreenState.review;
        });
      } else {
        final respStr = await response.stream.bytesToString();
        final errorJson = json.decode(respStr);
        throw Exception('Detection failed: ${errorJson['message'] ?? response.reasonPhrase}');
      }
    } catch (e) {
      setState(() { _errorMessage = e is Exception ? e.toString() : 'An unexpected error occurred: $e'; _currentState = ScreenState.error; });
    }
  }

  // MODIFIED: Find recipes by calling Spoonacular directly
  Future<void> _findRecipes() async {
    setState(() => _currentState = ScreenState.loading);
    try {
      if (_finalIngredients.isEmpty) {
        throw Exception('No ingredients selected to find recipes.');
      }

      final ingredientsString = _finalIngredients.join(',');
      final uri = Uri.https(
        'api.spoonacular.com',
        '/recipes/findByIngredients',
        {
          'ingredients': ingredientsString,
          'number': '10', // Get up to 10 recipes
          'ranking': '1', // Minimize missing ingredients
          'apiKey': _spoonacularApiKey,
        }
      );

      var response = await http.get(uri);

      if(response.statusCode == 200) {
        // Spoonacular returns an array of recipes directly
        final List<dynamic> recipeData = json.decode(response.body);
        setState(() {
          _recipes = recipeData.map((data) => Recipe.fromJson(data)).toList();
          _currentState = ScreenState.success;
        });
      } else {
        // Attempt to parse Spoonacular's error message if available
        final errorJson = json.decode(response.body);
        final errorMessage = errorJson['message'] ?? 'Failed to find recipes with status: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e is Exception ? 'Recipe Search Error: ${e.toString()}' : 'An unexpected error occurred: $e';
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
      // MODIFIED: Make scaffold and appbar transparent
        backgroundColor: Color(0xffa8edea),
      appBar: AppBar(
        title: const Text('Recipe Suggestions'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_currentState != ScreenState.initial)
            IconButton(icon: const Icon(Icons.refresh), onPressed: _resetScreen)
        ],
      ),
      // MODIFIED: Use a Stack to layer the background behind the content
      body: Stack(
        children: [
          const _LivingAnimatedBackground(),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentState) {
      case ScreenState.review: return _buildReviewUI();
      case ScreenState.success: return _buildResultsUI();
      case ScreenState.loading: return const Center(child: CircularProgressIndicator());
      case ScreenState.error: return _buildErrorUI();
      case ScreenState.initial:
      return _buildInitialUI();
    }
  }

  Widget _buildReviewUI() {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("We found these ingredients...", style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            if (_imagePath != null && _imageDimensions != null)
              BoundingBoxImage(
                imagePath: _imagePath!,
                ingredients: _detectedIngredients,
                originalImageDims: _imageDimensions!,
              ),
            const SizedBox(height: 24),
            Text("Confirm or add more:", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: _finalIngredients.map((ingredient) => Chip(
                label: Text(ingredient),
                onDeleted: () => setState(() => _finalIngredients.remove(ingredient)),
              )).toList(),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _ingredientTextController,
                  decoration: const InputDecoration(
                    labelText: 'Add an ingredient',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                icon: const Icon(Icons.add),
                onPressed: _addIngredient,
              )
            ]),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.search),
                label: const Text('Find Recipes'),
                onPressed: _findRecipes,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
              ),
            )
          ],
        ),
      );
  }

  Widget _buildInitialUI() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/animation/cooking_animation.json', // Add a Lottie file to your assets
            width: 300,
            height: 300,
          ),
          const SizedBox(height: 30),
          const Text(
            'Ready to Cook?',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            'Take a picture of your ingredients and get instant recipe ideas!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            icon: const Icon(Icons.camera_alt),
            label: const Text('Start Cooking...'),
            onPressed: _startCooking,
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
          Text(_errorMessage, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _resetScreen,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsUI() {
    if (_recipes.isEmpty) {
      return const Center(child: Text('No recipes found for the detected ingredients.'));
    }
    return ListView.builder(
      itemCount: _recipes.length,
      itemBuilder: (context, index) {
        final recipe = _recipes[index];
        return RecipeCard(recipe: recipe);
      },
    );
  }
}

// --- CUSTOM WIDGET FOR IMAGE WITH BOUNDING BOXES (REMAINS UNCHANGED) ---
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
        // Calculate scaling factors to draw boxes on the displayed image
        final double scaleX = constraints.maxWidth / originalImageDims.width;
        final double scaleY = (constraints.maxWidth / originalImageDims.width) * originalImageDims.height > 400
                            ? 400 / originalImageDims.height
                            : scaleX;

        // Limiting the height of the image container for better layout
        final double containerHeight = originalImageDims.height * scaleY;

        return ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
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
                        border: Border.all(color: Colors.redAccent, width: 2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Container(
                          color: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Text(
                            ing.name,
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
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

// A dedicated widget for displaying a single recipe (REMAINS UNCHANGED)
class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  const RecipeCard({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // Navigate to the detail screen when tapped
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailScreen(recipeId: recipe.id.toInt()),
          ),
        );
      },
      child: Card(
      margin: const EdgeInsets.all(10.0),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(15),
              topRight: Radius.circular(15),
            ),
            child: Image.network(
              recipe.imageUrl,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                return progress == null ? child : const Center(child: CircularProgressIndicator());
              },
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.broken_image, size: 100, color: Colors.grey);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 18),
                      const SizedBox(width: 4),
                      Text('${recipe.usedIngredientCount} ingredients you have'),
                      const Spacer(),
                      const Icon(Icons.remove_circle, color: Colors.red, size: 18),
                      const SizedBox(width: 4),
                      Text('${recipe.missedIngredientCount} missing'),
                    ],
                  ),
                ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

// NEW: The animated background widget
class _LivingAnimatedBackground extends StatefulWidget {
  const _LivingAnimatedBackground();
  @override
  State<_LivingAnimatedBackground> createState() =>
      _LivingAnimatedBackgroundState();
}

class _LivingAnimatedBackgroundState extends State<_LivingAnimatedBackground>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
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
    final colors = [
      Color.lerp(
          const Color(0xffa8edea), const Color(0xfffed6e3), _controller.value)!,
      Color.lerp(
          const Color(0xfffed6e3), const Color(0xffa8edea), _controller.value)!,
    ];
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors))),
    );
  }
}