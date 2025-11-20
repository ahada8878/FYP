import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import 'package:fyp/services/config_service.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:ui';
import 'package:fyp/services/auth_service.dart';

// --- 🎨 COLOR PALETTE ---
const Color safeGreen = Color(0xFF2E7D32);
const Color calorieOrange = Color(0xFFFF6D00);
const Color factoryBlue = Color(0xFF0288D1);
const Color darkText = Color(0xFF2D3436);
const Color greyText = Color(0xFF636E72);
const Color lightBg = Color(0xFFFAFAFA);

final AuthService _authService = AuthService();

// --- DATA MODELS ---
enum ProductType { restaurant, factory }

class Product {
  final String name;
  final String brand;
  final int? calories;
  final String databaseSource;
  final String? imageUrl;
  final ProductType type;
  final String? linkUrl;
  final int? itemId;

  Product({
    required this.name,
    required this.brand,
    this.calories,
    required this.databaseSource,
    this.imageUrl,
    required this.type,
    this.linkUrl,
    this.itemId,
  });

  factory Product.fromOpenFoodFactsJson(Map<String, dynamic> json) {
    int? cal;
    final nutrients = json['nutrients'];
    if (nutrients != null && nutrients['calories_kcal_100g'] != null) {
      cal = (nutrients['calories_kcal_100g'] as num?)?.round();
    }

    return Product(
      name: json['product_name'] ?? 'Unknown Product',
      brand: json['brands'] ?? 'Unknown Brand',
      calories: cal,
      databaseSource: 'OpenFoodFacts',
      imageUrl: json['image_url'],
      type: ProductType.factory,
    );
  }

  factory Product.fromSpoonacularJson(Map<String, dynamic> json) {
    return Product(
      name: json['title'] ?? 'Unknown Item',
      brand: json['restaurantChain'] ?? 'Spoonacular',
      calories: json['calories'],
      databaseSource: 'Spoonacular',
      imageUrl: json['image'],
      type: ProductType.restaurant,
      linkUrl: null,
      itemId: json['id'],
    );
  }

  factory Product.fromSpoonacularDetailedJson(Map<String, dynamic> json, Product originalProduct) {
    final nutrition = json['nutrition']?['nutrients'];
    int? calories;
    if (nutrition != null) {
      final caloriesData = nutrition.firstWhere(
        (nutrient) => nutrient['name'] == 'Calories',
        orElse: () => null,
      );
      if (caloriesData != null) {
        calories = (caloriesData['amount'] as num?)?.round();
      }
    }
    return Product(
      name: originalProduct.name,
      brand: originalProduct.brand,
      calories: originalProduct.calories ?? calories,
      databaseSource: originalProduct.databaseSource,
      imageUrl: originalProduct.imageUrl,
      type: originalProduct.type,
      linkUrl: originalProduct.linkUrl,
      itemId: originalProduct.itemId,
    );
  }
}

enum ScreenState { initial, loading, success, error }

class CravingsPage extends StatelessWidget {
  const CravingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SearchScreen(title: 'Cravings Search');
  }
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required this.title});
  final String title;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const String _spoonacularApiKey = '3ae6af7175864f2b96f71cf261f1e16a';
  static const String _spoonacularBaseUrl = 'https://api.spoonacular.com';
  static const String _serverBaseUrl = '$baseURL';

  ScreenState _currentState = ScreenState.initial;
  
  List<Product> _restaurantProducts = [];
  List<Product> _factoryProducts = [];
  
  bool _isLoadingRestaurant = false;
  bool _isLoadingFactory = false;
  
  Map<String, dynamic> _healthConcerns = {};
  Map<String, dynamic> _restrictions = {};
  bool _isProfileLoading = true;
  String? _profileErrorMessage;

  final TextEditingController _searchController = TextEditingController();
  final PageController _restaurantPageController = PageController(viewportFraction: 0.85);
  final ScrollController _scrollController = ScrollController();

  int _currentRestaurantPage = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _restaurantPageController.addListener(() {
      if (_restaurantPageController.page != null) {
        int next = _restaurantPageController.page!.round();
        if (_currentRestaurantPage != next) {
          setState(() => _currentRestaurantPage = next);
        }
      }
    });
  }

  // --- DATA FETCHING ---

  Future<void> _fetchUserProfile() async {
    final token = await _authService.getToken();
    if (token == null) {
      setState(() {
        _profileErrorMessage = 'User not authenticated.';
        _isProfileLoading = false;
        _currentState = ScreenState.error;
      });
      return;
    }

    final url = Uri.parse('$_serverBaseUrl/api/user-details/my-profile');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _healthConcerns = Map<String, dynamic>.from(responseData['healthConcerns'] ?? {});
            _restrictions = Map<String, dynamic>.from(responseData['restrictions'] ?? {});
            _isProfileLoading = false;
            _profileErrorMessage = null;
            if(_currentState == ScreenState.error || _currentState == ScreenState.initial) {
                 _currentState = ScreenState.initial;
            }
          });
        }
      } else {
         if (mounted) setState(() => _isProfileLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isProfileLoading = false);
    }
  }

  Future<void> _fetchRestaurantProducts(String query) async {
    if (query.isEmpty) return;
    try {
      final searchUri = Uri.parse(
          '$_spoonacularBaseUrl/food/menuItems/search?query=$query&number=15&apiKey=$_spoonacularApiKey');
      final searchResponse = await http.get(searchUri).timeout(const Duration(seconds: 40));

      if (searchResponse.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(searchResponse.body);
        final List<dynamic> productsJson = data['menuItems'] ?? [];

        List<Product> tempProducts = productsJson
            .where((json) => json['title'] != null && json['id'] != null)
            .map((json) => Product.fromSpoonacularJson(json))
            .toList();

        List<Future<Product>> detailFutures = tempProducts.map((product) async {
          if (product.itemId == null) return product;
          final detailUri = Uri.parse('$_spoonacularBaseUrl/food/menuItems/${product.itemId}?apiKey=$_spoonacularApiKey');
          try {
            final detailResponse = await http.get(detailUri).timeout(const Duration(seconds: 5));
            if (detailResponse.statusCode == 200) {
              final Map<String, dynamic> detailData = jsonDecode(detailResponse.body);
              return Product.fromSpoonacularDetailedJson(detailData, product);
            }
            return product;
          } catch (_) {
            return product;
          }
        }).toList();

        final results = await Future.wait(detailFutures);
        if(mounted) {
            setState(() {
                _restaurantProducts = results; 
            });
        }
      }
    } catch (e) {
       print("Restaurant Fetch Error: $e");
    } finally {
      if(mounted) {
          setState(() {
            _isLoadingRestaurant = false;
          });
          _checkSearchComplete();
      }
    }
  }

  Future<void> _fetchFactoryProducts(String query) async {
    if (query.isEmpty) return;

    final token = await _authService.getToken();
    if (token == null) { 
        setState(() => _isLoadingFactory = false); 
        return; 
    }

    try {
      final url = Uri.parse('$_serverBaseUrl/api/food/products');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'productName': query}),
      ).timeout(const Duration(seconds: 150));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true && data.containsKey('products')) {
          final List<dynamic> productsJson = data['products'];
           if(mounted) {
            setState(() {
                _factoryProducts = productsJson
                    .map((json) => Product.fromOpenFoodFactsJson(json))
                    .where((p) => p.imageUrl != null && p.imageUrl!.isNotEmpty)
                    .toList();
            });
           }
        }
      }
    } catch (e) {
        print("Factory Fetch Error: $e");
    } finally {
      if(mounted) {
        setState(() {
            _isLoadingFactory = false;
        });
        _checkSearchComplete();
      }
    }
  }

  void _checkSearchComplete() {
    if (!_isLoadingRestaurant && !_isLoadingFactory) {
      if (_restaurantProducts.isEmpty && _factoryProducts.isEmpty) {
        setState(() {
          _currentState = ScreenState.error;
        });
      } else {
         setState(() {
          _currentState = ScreenState.success;
        });
      }
    }
  }

  void _searchProducts(String query) {
    FocusScope.of(context).unfocus();
    final lowerCaseQuery = query.toLowerCase().trim();
    if (lowerCaseQuery.isEmpty) {
      _resetScreen();
      return;
    }
    
    setState(() {
         _currentState = ScreenState.success; 
         _restaurantProducts.clear();
         _factoryProducts.clear();
         _isLoadingRestaurant = true;
         _isLoadingFactory = true;
    });
    
    _fetchRestaurantProducts(lowerCaseQuery);
    _fetchFactoryProducts(lowerCaseQuery);
  }

  void _resetScreen() {
    setState(() {
      _searchController.clear();
      _restaurantProducts = [];
      _factoryProducts = [];
      _isLoadingRestaurant = false;
      _isLoadingFactory = false;
      _currentState = ScreenState.initial;
      _profileErrorMessage = null;
    });
  }

  // --- UI COMPONENTS ---

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8))
        ],
      ),
      child: TextField(
        controller: _searchController,
        onSubmitted: _searchProducts,
        textInputAction: TextInputAction.search,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: darkText),
        decoration: InputDecoration(
          hintText: 'What are you craving today?',
          hintStyle: const TextStyle(color: greyText, fontSize: 15),
          prefixIcon: const Icon(Icons.search_rounded, color: safeGreen),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    _resetScreen();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        
        children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: darkText.withOpacity(0.05), shape: BoxShape.circle),
              child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    title, 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.primary, letterSpacing: -0.5)
                ),
                Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: greyText, fontWeight: FontWeight.w500)
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSectionLoading() {
    return Padding(
      padding: const EdgeInsets.all(30.0),
      child: Center(
        child: Column(
          children: [
             CircularProgressIndicator(strokeWidth: 2.5, color: Theme.of(context).colorScheme.primary),
             const SizedBox(height: 15),
             const Text("Hunting for food...", style: TextStyle(color: greyText, fontSize: 13, fontWeight: FontWeight.w600))
          ],
        ),
      ),
    );
  }

  Widget _buildSuccess() {
    return SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 80, top: 10),
        physics: const BouncingScrollPhysics(),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                _buildSearchBar(),
                const SizedBox(height: 10),

                // --- RESTAURANT SECTION ---
                if (_isLoadingRestaurant || _restaurantProducts.isNotEmpty) ...[
                  _buildSectionHeader("Restaurant Plates", "Curated menu items nearby", Icons.restaurant_rounded),
                  
                  if (_isLoadingRestaurant) 
                     _buildSectionLoading()
                  else
                      SizedBox(
                          height: 400,
                          child: PageView.builder(
                              controller: _restaurantPageController,
                              itemCount: _restaurantProducts.length,
                              physics: const BouncingScrollPhysics(),
                              itemBuilder: (context, index) => RestaurantProductCard(
                                  product: _restaurantProducts[index],
                                  pageController: _restaurantPageController,
                                  index: index,
                              ),
                          ),
                      ),
                  const SizedBox(height: 20),
                ],

                // --- FACTORY SECTION ---
                if (_isLoadingFactory || _factoryProducts.isNotEmpty) ...[
                  const Divider(height: 40, thickness: 1, indent: 20, endIndent: 20, color: Color(0xFFEEEEEE)),
                  _buildSectionHeader("Packaged Goods", "Scan results from database", Icons.inventory_2_rounded),
                  
                  if (_isLoadingFactory)
                      _buildSectionLoading()
                  else
                      ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _factoryProducts.length,
                          separatorBuilder: (c, i) => const SizedBox(height: 16),
                          itemBuilder: (context, index) => FactoryProductListTile(product: _factoryProducts[index]),
                      ),
                ],
                
                // Empty State Handle
                if (!_isLoadingRestaurant && !_isLoadingFactory && _restaurantProducts.isEmpty && _factoryProducts.isEmpty)
                   const Padding(
                     padding: EdgeInsets.only(top: 50),
                     child: Center(child: Text("No cravings found yet.", style: TextStyle(color: Colors.grey))),
                   )
            ],
        ),
    );
  }

  Widget _buildInitial() {
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
                child: Lottie.asset('assets/animation/food_animation.json', width: 200, height: 200)
            ),
            const SizedBox(height: 30),
            Text(
                "What are you craving?", 
                style: TextStyle(
                    fontSize: 26, 
                    fontWeight: FontWeight.w900, 
                    color: Theme.of(context).colorScheme.primary
                )
            ),
            const SizedBox(height: 10),
            const Padding(
                padding: EdgeInsets.symmetric(horizontal: 50), 
                child: Text(
                    "Search for restaurant dishes or packaged goods compatible with your health profile.", 
                    textAlign: TextAlign.center, 
                    style: TextStyle(fontSize: 15, color: greyText, height: 1.5)
                )
            ),
            const SizedBox(height: 30),
            _buildSearchBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
     return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Icon(Icons.search_off_rounded, size: 80, color: Theme.of(context).colorScheme.primary,),
            const SizedBox(height: 20),
            const Text(
              "No Cravings Found",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: darkText),
            ),
            const SizedBox(height: 10),
            Text(
              _profileErrorMessage ?? "We couldn't find any matches for '${_searchController.text}'. Try a different keyword.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: greyText, fontSize: 15, height: 1.4),
            ),
            const SizedBox(height: 40),
            InkWell(
              onTap: () { HapticFeedback.lightImpact(); _resetScreen(); },
              borderRadius: BorderRadius.circular(50),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 15),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary, 
                  borderRadius: BorderRadius.circular(50), 
                  boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 5))]
                ),
                child: const Text("TRY AGAIN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      // FIXED: AppBar now shows title "Cravings" in ALL states (including Initial)
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Always show title centered
        title:  Text("Cravings", style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 22)),
        centerTitle: true, 
        leading: IconButton(
            icon:  Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).colorScheme.primary,), 
            onPressed: () {
              if (_currentState == ScreenState.initial) {
                Navigator.pop(context); // Go back to Home
              } else {
                _resetScreen(); // Go back to Initial Search
              }
            }
        ),
      ),
      body: Stack(
        children: [
            const _LivingAnimatedBackground(),
            Container(color: Colors.white.withOpacity(0.3)),
            SafeArea(
                bottom: false,
                child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: _currentState == ScreenState.initial 
                        ? _buildInitial()
                        : _currentState == ScreenState.error 
                            ? _buildError() 
                            : _buildSuccess(),
                )
            )
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _restaurantPageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

// --- 🎨 WIDGETS ---

// 1. 3D Pop Tile for Packaged Goods (Non-Clickable, No Overflow)
class FactoryProductListTile extends StatelessWidget {
  final Product product;
  const FactoryProductListTile({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 125, 
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: factoryBlue.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(color: factoryBlue.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 6)),
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
              width: 100,
              height: double.infinity, 
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
              ),
              child: product.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(product.imageUrl!, fit: BoxFit.cover)
                    )
                  : const Icon(Icons.inventory_2_outlined, color: Colors.grey)
          ),
          
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.brand.toUpperCase(),
                        maxLines: 1,
                        style:  TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: darkText, height: 1.2),
                      ),
                    ],
                  ),
                  
                  Row(
                      children: [
                          if(product.calories != null)
                          Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: calorieOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                              child: Row(
                                  children: [
                                      const Icon(Icons.local_fire_department_rounded, size: 14, color: calorieOrange),
                                      const SizedBox(width: 4),
                                      Text("${product.calories} kcal", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: calorieOrange)),
                                  ],
                              ),
                          ),
                      ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 2. Immersive Glass Card for Restaurants (Non-Clickable)
class RestaurantProductCard extends StatelessWidget {
  final Product product;
  final PageController pageController;
  final int index;

  const RestaurantProductCard({
    super.key,
    required this.product,
    required this.pageController,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pageController,
      builder: (context, child) {
        double scale = 1.0;
        if (pageController.position.hasContentDimensions) {
          double page = pageController.page ?? pageController.initialPage.toDouble();
          double distance = (index - page).abs();
          scale = (1.0 - (distance * 0.08)).clamp(0.9, 1.0);
        }

        return Transform.scale(
          scale: scale,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(35),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 25, offset: const Offset(0, 10)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(35),
              child: Stack(
                fit: StackFit.expand,
                children: [
                   product.imageUrl != null && product.imageUrl!.isNotEmpty
                        ? Image.network(product.imageUrl!, fit: BoxFit.cover)
                        : Container(
                            color: const Color(0xFF2D3436), 
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.restaurant_menu_rounded, size: 60, color: Colors.white.withOpacity(0.2)),
                                  const SizedBox(height: 10),
                                  Text("No Image Available", style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12))
                                ],
                              ),
                            )
                          ),
                   
                   Container(
                       decoration: BoxDecoration(
                           gradient: LinearGradient(
                               begin: Alignment.topCenter,
                               end: Alignment.bottomCenter,
                               colors: [
                                 Colors.transparent,
                                 Colors.black.withOpacity(0.1),
                                 Colors.black.withOpacity(0.9) 
                               ],
                               stops: const [0.4, 0.6, 1.0]
                           )
                       )
                   ),

                   Positioned(
                     top: 20,
                     right: 20,
                     child: Container(
                       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                       decoration: BoxDecoration(
                         color: Colors.white,
                         borderRadius: BorderRadius.circular(20),
                         boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5)]
                       ),
                       child: Row(
                         children: [
                           const Icon(Icons.whatshot, color: Colors.orange, size: 16),
                           const SizedBox(width: 4),
                           Text(
                             product.calories != null ? "${product.calories}" : "Tasty", 
                             style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)
                           ),
                         ],
                       ),
                     ),
                   ),

                   Positioned(
                       bottom: 0, left: 0, right: 0,
                       child: ClipRRect(
                         child: BackdropFilter(
                           filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                           child: Container(
                               padding: const EdgeInsets.all(24),
                               decoration: BoxDecoration(
                                   color: Colors.white.withOpacity(0.1),
                                   border: Border(top: BorderSide(color: Colors.white.withOpacity(0.2)))
                               ),
                               child: Column(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   mainAxisSize: MainAxisSize.min,
                                   children: [
                                       Container(
                                           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                           decoration: BoxDecoration(color: safeGreen, borderRadius: BorderRadius.circular(6)),
                                           child: Text(
                                              (product.brand.isNotEmpty ? product.brand : "Restaurant").toUpperCase(), 
                                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)
                                           )
                                       ),
                                       const SizedBox(height: 10),
                                       Text(
                                          product.name, 
                                          maxLines: 2, 
                                          overflow: TextOverflow.ellipsis, 
                                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, height: 1.1)
                                       ),
                                       const SizedBox(height: 15),
                                       
                                       Container(
                                           padding: const EdgeInsets.symmetric(vertical: 12),
                                           width: double.infinity,
                                           decoration: BoxDecoration(
                                             color: Colors.white.withOpacity(0.15),
                                             borderRadius: BorderRadius.circular(12),
                                             border: Border.all(color: Colors.white.withOpacity(0.3))
                                           ),
                                           alignment: Alignment.center,
                                           child: const Row(
                                             mainAxisAlignment: MainAxisAlignment.center,
                                             children: [
                                               Icon(Icons.thumb_up_rounded, color: Colors.white, size: 16),
                                               SizedBox(width: 8),
                                               Text("Recommended Choice", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                             ],
                                           ),
                                       )
                                   ],
                               ),
                           ),
                         ),
                       ),
                   )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

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