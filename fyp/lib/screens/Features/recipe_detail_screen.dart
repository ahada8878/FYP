import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart' as http;

// --- CONFIGURATION CONSTANT ---
// For a real app, manage your API keys more securely
const String _spoonacularApiKey = '3ae6af7175864f2b96f71cf261f1e16a';

// --- DATA MODELS FOR RECIPE DETAILS ---
class RecipeDetail {
  final String title;
  final String imageUrl;
  final String summary;
  final String instructions;
  final int readyInMinutes;
  final int servings;
  final List<Ingredient> extendedIngredients;

  RecipeDetail({
    required this.title,
    required this.imageUrl,
    required this.summary,
    required this.instructions,
    required this.readyInMinutes,
    required this.servings,
    required this.extendedIngredients,
  });

  factory RecipeDetail.fromJson(Map<String, dynamic> json) {
    var ingredientsFromJson = json['extendedIngredients'] as List;
    List<Ingredient> ingredientList =
        ingredientsFromJson.map((i) => Ingredient.fromJson(i)).toList();

    return RecipeDetail(
      title: json['title'],
      imageUrl: json['image'],
      summary: json['summary'] ?? 'No summary available.',
      instructions: json['instructions'] ?? 'No instructions available.',
      readyInMinutes: json['readyInMinutes'],
      servings: json['servings'],
      extendedIngredients: ingredientList,
    );
  }
}

class Ingredient {
  final String original; // e.g., "1 cup of sugar"
  Ingredient({required this.original});
  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(original: json['original']);
  }
}

// --- RECIPE DETAIL SCREEN WIDGET ---
class RecipeDetailScreen extends StatefulWidget {
  final int recipeId;
  const RecipeDetailScreen({super.key, required this.recipeId});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  RecipeDetail? _recipeDetail;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchRecipeDetails();
  }

  Future<void> _fetchRecipeDetails() async {
    try {
      final uri = Uri.https(
        'api.spoonacular.com',
        '/recipes/${widget.recipeId}/information',
        {'apiKey': _spoonacularApiKey},
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        setState(() {
          _recipeDetail = RecipeDetail.fromJson(json.decode(response.body));
          _isLoading = false;
        });
      } else {
        final errorJson = json.decode(response.body);
        throw Exception(errorJson['message'] ?? 'Failed to load recipe details.');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_recipeDetail?.title ?? 'Loading...'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Error: $_errorMessage'),
        ),
      );
    }
    if (_recipeDetail == null) {
      return const Center(child: Text('Recipe not found.'));
    }

    final recipe = _recipeDetail!;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Image.network(
            recipe.imageUrl,
            fit: BoxFit.cover,
            height: 250,
            // Error and loading builders for the image
            loadingBuilder: (context, child, progress) {
              return progress == null
                  ? child
                  : const SizedBox(
                      height: 250,
                      child: Center(child: CircularProgressIndicator()));
            },
            errorBuilder: (context, error, stackTrace) {
              return const SizedBox(
                  height: 250,
                  child: Icon(Icons.broken_image, size: 100, color: Colors.grey));
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(recipe.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildInfoChip(Icons.timer_outlined, '${recipe.readyInMinutes} min'),
                    _buildInfoChip(Icons.people_outline, '${recipe.servings} servings'),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSectionTitle('Summary'),
                // Use Html widget to render summary with formatting
                Html(data: recipe.summary),
                const SizedBox(height: 16),
                _buildSectionTitle('Ingredients'),
                // Display the list of ingredients
                for (var ingredient in recipe.extendedIngredients)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text('• ${ingredient.original}'),
                  ),
                const SizedBox(height: 16),
                _buildSectionTitle('Instructions'),
                // Use Html widget to render instructions with formatting (e.g., lists)
                Html(data: recipe.instructions),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for section titles
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
  
  // Helper widget for the info chips (time, servings)
  Widget _buildInfoChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 20),
      label: Text(label),
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
    );
  }
}