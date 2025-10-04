import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:lottie/lottie.dart';
import 'package:fyp/screens/camera_screen.dart'; 

// A data model for our recipe
class Recipe {
  final int id;
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
      id: json['id'],
      title: json['title'],
      imageUrl: json['image'],
      usedIngredientCount: json['usedIngredientCount'] ?? 0,
      missedIngredientCount: json['missedIngredientCount'] ?? 0,
    );
  }
}

// Enum to manage the screen's state
enum ScreenState { initial, loading, success, error }

class RecipeSuggestion extends StatefulWidget {
  const RecipeSuggestion({super.key});

  @override
  State<RecipeSuggestion> createState() => _RecipeSuggestionState();
}

class _RecipeSuggestionState extends State<RecipeSuggestion> {
  ScreenState _currentState = ScreenState.initial;
  List<Recipe> _recipes = [];
  String _errorMessage = '';

  // --- Core Logic ---
  Future<void> _getRecipesFromImage(String imagePath) async {
    setState(() {
      _currentState = ScreenState.loading;
    });

    try {
      // Replace with your actual server IP/domain
      var uri = Uri.parse('http://192.168.1.10:5000/api/generate-recipe'); // <-- IMPORTANT: Use your PC's IP address
      var request = http.MultipartRequest('POST', uri);
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imagePath,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      var response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final decodedResponse = json.decode(responseBody);
        
        if(decodedResponse['success'] == true) {
            final List<dynamic> recipeData = decodedResponse['data'];
            setState(() {
              _recipes = recipeData.map((data) => Recipe.fromJson(data)).toList();
              _currentState = ScreenState.success;
            });
        } else {
             throw Exception(decodedResponse['message'] ?? 'Failed to get recipes');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
        _currentState = ScreenState.error;
      });
    }
  }

  void _startCooking() async {
    // Navigate to the camera screen and wait for a result
    final imagePath = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (context) => const CameraScreen()),
    );

    if (imagePath != null && imagePath.isNotEmpty) {
      _getRecipesFromImage(imagePath);
    }
  }

  void _resetScreen() {
      setState(() {
          _currentState = ScreenState.initial;
          _recipes = [];
          _errorMessage = '';
      });
  }


  // --- UI Building ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe Suggestions'),
        actions: [
            if (_currentState != ScreenState.initial)
            IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _resetScreen,
            )
        ],
      ),
      body: Center(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    switch (_currentState) {
      case ScreenState.loading:
        return _buildLoadingUI();
      case ScreenState.success:
        return _buildResultsUI();
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

  Widget _buildLoadingUI() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 20),
        Text(
          'Finding delicious recipes...',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      ],
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

// A dedicated widget for displaying a single recipe
class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  const RecipeCard({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Card(
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
    );
  }
}