// recipe_detail_screen.dart

import 'dart:convert'; // FIX: Changed '.' to ':'
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // FIX: Added missing import
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui';
import 'dart:math' as math;

// --- CONFIGURATION CONSTANT ---
const String _spoonacularApiKey = '5b037f88b6e34ea8b8b88179916ed15a';

// --- DATA MODELS ---
class RecipeDetail {
  final String title;
  final String imageUrl;
  final String summary;
  final String instructions;
  final int readyInMinutes;
  final int servings;
  final List<Ingredient> extendedIngredients;

  RecipeDetail({
    required this.title, required this.imageUrl, required this.summary,
    required this.instructions, required this.readyInMinutes, required this.servings,
    required this.extendedIngredients,
  });

  factory RecipeDetail.fromJson(Map<String, dynamic> json) {
    var ingredientsFromJson = json['extendedIngredients'] as List;
    List<Ingredient> ingredientList = ingredientsFromJson.map((i) => Ingredient.fromJson(i)).toList();
    return RecipeDetail(
      title: json['title'] ?? 'Untitled Recipe',
      imageUrl: json['image'] ?? '',
      summary: json['summary'] ?? 'No summary available.',
      instructions: json['instructions'] ?? 'No instructions available.',
      readyInMinutes: json['readyInMinutes'] ?? 0,
      servings: json['servings'] ?? 0,
      extendedIngredients: ingredientList,
    );
  }
}

class Ingredient {
  final String name;
  final String original;
  final String imageUrl;

  Ingredient({required this.name, required this.original, required this.imageUrl});
  
  factory Ingredient.fromJson(Map<String, dynamic> json) {
    final imageName = json['image'] as String? ?? '';
    return Ingredient(
      name: json['name'] ?? '',
      original: json['original'] ?? '',
      imageUrl: 'https://spoonacular.com/cdn/ingredients_500x500/$imageName',
    );
  }
}

// --- REDESIGNED RECIPE DETAIL SCREEN ---
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
      final uri = Uri.https('api.spoonacular.com', '/recipes/${widget.recipeId}/information', {'apiKey': _spoonacularApiKey});
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
        _errorMessage = e.toString().replaceFirst("Exception: ", "");
        _isLoading = false;
      });
    }
  }
  
  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text('Error: $_errorMessage')));
    }
    if (_recipeDetail == null) {
      return const Center(child: Text('Recipe not found.'));
    }

    final recipe = _recipeDetail!;
    final strippedInstructions = recipe.instructions.replaceAll(RegExp(r'<[^>]*>'), ' ');
    final instructionsList = strippedInstructions.split(RegExp(r'\.\s+')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _CreativeMagazineHeaderDelegate(
          imageUrl: recipe.imageUrl,
          mealTitle: recipe.title,
          servings: recipe.servings.toString(),
          readyInMinutes: recipe.readyInMinutes.toString(),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildCreativeSectionHeader(context, title: 'Summary', icon: Icons.description_rounded),
              _ExpandableSummaryCard(htmlData: recipe.summary),
              const SizedBox(height: 24),
              _buildCreativeSectionHeader(context, title: 'Ingredients', icon: Icons.shopping_basket_rounded),
              _buildIngredientsSection(recipe.extendedIngredients),
              const SizedBox(height: 24),
              _buildCreativeSectionHeader(context, title: 'Instructions', icon: Icons.local_dining_rounded),
              _buildInstructionsSection(instructionsList),
            ]),
          ),
        ),
      ],
    );
  }
  
  Widget _buildCreativeSectionHeader(BuildContext context, {required String title, required IconData icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey[800])),
        ],
      ),
    );
  }

  Widget _buildIngredientsSection(List<Ingredient> ingredients) {
    return Column(
      children: ingredients.asMap().entries.map((entry) {
        return _InteractiveIngredientTile(
          key: ValueKey(entry.key),
          ingredient: entry.value,
          capitalize: _capitalize,
        );
      }).toList(),
    );
  }

   Widget _buildInstructionsSection(List<String> instructions) {
    final displayInstructions = instructions.isNotEmpty ? instructions : ['No instructions available.'];
    return _InteractiveCard(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: displayInstructions.asMap().entries.map((entry) => _InstructionStep(index: entry.key, instruction: entry.value, isLast: entry.key == displayInstructions.length - 1)).toList(),
      ),
    );
  }
}

class _ExpandableSummaryCard extends StatefulWidget {
  final String htmlData;
  const _ExpandableSummaryCard({required this.htmlData});

  @override
  State<_ExpandableSummaryCard> createState() => _ExpandableSummaryCardState();
}

class _ExpandableSummaryCardState extends State<_ExpandableSummaryCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return _InteractiveCard(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: AnimatedSize(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRect(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: _isExpanded ? double.infinity : 60,
                  ),
                  child: Html(
                    data: widget.htmlData,
                    style: {
                      "body": Style(
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero, // FIX: Use HtmlPaddings
                        fontSize: FontSize(15.0),
                        color: Colors.black.withAlpha(179), // FIX: Use withAlpha
                      ),
                      "b": Style(fontWeight: FontWeight.bold),
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    _isExpanded ? 'Show Less' : 'Read More...',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: primaryColor,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreativeMagazineHeaderDelegate extends SliverPersistentHeader {
  final String imageUrl, mealTitle, servings, readyInMinutes;
  _CreativeMagazineHeaderDelegate({
    required this.imageUrl, required this.mealTitle,
    required this.servings, required this.readyInMinutes,
  }) : super(pinned: true, delegate: _HeaderDelegate(
    imageUrl: imageUrl, mealTitle: mealTitle,
    servings: servings, readyInMinutes: readyInMinutes,
    minExtent: kToolbarHeight + 40, maxExtent: 400,
  ));
}

class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  final String imageUrl, mealTitle, servings, readyInMinutes;
  @override
  final double minExtent;
  @override
  final double maxExtent;
  _HeaderDelegate({
    required this.imageUrl, required this.mealTitle,
    required this.servings, required this.readyInMinutes,
    required this.minExtent, required this.maxExtent,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final progress = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final primaryColor = Theme.of(context).colorScheme.primary;
    final blurredImageOpacity = 1.0 - progress * 2;
    final titleCardTop = lerpDouble(200, 0, progress)!;
    final titleCardHorizontalPadding = lerpDouble(24, 60, progress)!;
    final titleFontSize = lerpDouble(36, 20, progress)!;
    final mainImageScale = lerpDouble(1.0, 0.0, progress)!;
    final mainImageTop = lerpDouble(100, 0, progress)!;
    final statsOpacity = (1.0 - progress * 1.5).clamp(0.0, 1.0);
    final collapsedTitleOpacity = (progress - 0.5) * 2;

    return Stack(fit: StackFit.expand, children: [
      Opacity(opacity: blurredImageOpacity.clamp(0.0, 1.0), child: imageUrl.isNotEmpty ? CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover) : Container(color: Colors.grey)),
      ClipRRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(color: Colors.black.withAlpha(51)))),
      Positioned(top: mainImageTop, left: 0, right: 0, child: Transform.scale(scale: mainImageScale, child: Container(height: 200, margin: const EdgeInsets.symmetric(horizontal: 60), decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withAlpha(77), blurRadius: 20, spreadRadius: 5)], image: imageUrl.isNotEmpty ? DecorationImage(image: CachedNetworkImageProvider(imageUrl), fit: BoxFit.cover) : null, color: Colors.grey)))),
      Positioned(top: titleCardTop, left: 0, right: 0, child: Padding(padding: EdgeInsets.symmetric(horizontal: titleCardHorizontalPadding), child: Column(children: [
        _GlassCard(child: Text(mealTitle, textAlign: TextAlign.center, style: TextStyle(fontSize: titleFontSize, fontWeight: FontWeight.w900, color: Colors.white, height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis)),
        const SizedBox(height: 16),
        Opacity(opacity: statsOpacity, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _StatChip(icon: Icons.access_time_filled_rounded, label: '$readyInMinutes min'),
          _StatChip(icon: Icons.groups_2_rounded, label: '$servings servings'),
        ]))
      ]))),
      Container(height: minExtent, color: primaryColor.withAlpha((255 * progress).round()), child: SafeArea(child: Opacity(opacity: collapsedTitleOpacity.clamp(0.0, 1.0), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 24.0), child: Align(alignment: Alignment.center, child: Text(mealTitle, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)))))),
    ]);
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => true;
}

class _InteractiveIngredientTile extends StatefulWidget {
  final Ingredient ingredient;
  final String Function(String) capitalize;

  const _InteractiveIngredientTile({
    super.key,
    required this.ingredient,
    required this.capitalize,
  });

  @override
  State<_InteractiveIngredientTile> createState() => _InteractiveIngredientTileState();
}

class _InteractiveIngredientTileState extends State<_InteractiveIngredientTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() { _isExpanded = !_isExpanded; });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            height: _isExpanded ? 120 : 60,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withAlpha(26), blurRadius: 10, offset: const Offset(0, 4))]),
            child: Stack(fit: StackFit.expand, children: [
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _isExpanded ? 0.0 : 1.0,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(decoration: BoxDecoration(color: Colors.white.withAlpha(166), border: Border.all(color: Colors.white.withAlpha(51)))),
                ),
              ),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 500),
                opacity: _isExpanded ? 1.0 : 0.0,
                child: CachedNetworkImage(imageUrl: widget.ingredient.imageUrl, fit: BoxFit.cover, errorWidget: (context, url, error) => Container(color: Colors.grey.shade200)),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                decoration: BoxDecoration(color: _isExpanded ? primaryColor.withAlpha(179) : Colors.white.withOpacity(0.65)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 300),
                            style: TextStyle(color: _isExpanded ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
                            child: Text(widget.capitalize(widget.ingredient.name)),
                          ),
                           AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 300),
                            style: TextStyle(color: _isExpanded ? Colors.white70 : Colors.grey.shade600, fontSize: 14),
                            child: Text(widget.ingredient.original),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _InstructionStep extends StatelessWidget {
  final int index;
  final String instruction;
  final bool isLast;

  const _InstructionStep({required this.index, required this.instruction, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              CircleAvatar(radius: 14, backgroundColor: Colors.orange.withAlpha(51), child: Text('${index + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade800))),
              if (!isLast) Expanded(child: Container(width: 2, color: Colors.orange.withAlpha(51))),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(child: Padding(padding: EdgeInsets.only(bottom: isLast ? 0 : 24), child: Text(instruction, style: TextStyle(color: Colors.grey[800], fontSize: 15, height: 1.5)))),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(color: Colors.white.withAlpha(26), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withAlpha(51))),
          child: child,
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _InteractiveCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  const _InteractiveCard({required this.child, this.onTap, this.padding = EdgeInsets.zero});
  @override
  State<_InteractiveCard> createState() => _InteractiveCardState();
}

class _InteractiveCardState extends State<_InteractiveCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(18), blurRadius: 15, spreadRadius: -5, offset: const Offset(0, 5))],
          ),
          child: ClipRRect(
             borderRadius: BorderRadius.circular(24.0),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: widget.padding,
                decoration: BoxDecoration(color: Colors.white.withAlpha(166), border: Border.all(color: Colors.white.withAlpha(77))),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}