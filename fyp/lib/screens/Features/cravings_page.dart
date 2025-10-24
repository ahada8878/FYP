import 'package:flutter/material.dart';
import 'package:fyp/services/config_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:ui';
import 'dart:math';
import 'package:fyp/services/auth_service.dart';
import 'package:fyp/screens/camera_screen.dart'; // Assuming camera_screen.dart is in this path


// Assumes apiIpAddress is available from config_service.dart
final AuthService _authService = AuthService();

// Formal Color Palette (unchanged, aligned with RecipeSuggestion)
const MaterialColor primaryAppColor = MaterialColor(0xFF37474F, <int, Color>{
  50: Color(0xFFECEFF1),
  100: Color(0xFFCFD8DC),
  200: Color(0xFFB0BEC5),
  300: Color(0xFF90A4AE),
  400: Color(0xFF78909C),
  500: Color(0xFF607D8B),
  600: Color(0xFF546E7A),
  700: Color(0xFF455A64),
  800: Color(0xFF37474F), // Primary
  900: Color(0xFF263238),
});
const Color secondaryAccentColor = Color(0xFF00838F);
const Color calorieGreen = Color(0xFF388E3C);
const Color factoryBlue = Color(0xFF0288D1);
const Color backgroundGray = Color(0xFFF5F7F8);

// Enum and Product Data Model (unchanged)
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

// State Management
enum ScreenState { initial, loading, success, error }

// Main Application Widget
class CravingsPage extends StatelessWidget {
  const CravingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SearchScreen(title: 'Cravings Search');
  }
}

// Home Page Widget (SearchScreen)
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required this.title});
  final String title;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const String _spoonacularApiKey = '3ae6af7175864f2b96f71cf261f1e16a';
  static const String _spoonacularBaseUrl = 'https://api.spoonacular.com';
  static const String _serverBaseUrl = 'http://$apiIpAddress:5000';

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

  // Fetch User Profile Data (unchanged)
  Future<void> _fetchUserProfile() async {
    final token = await _authService.getToken();
    if (token == null) {
      setState(() {
        _profileErrorMessage = 'User not authenticated. Please log in.';
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
      ).timeout(const Duration(seconds: 100));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        setState(() {
          _healthConcerns = Map<String, dynamic>.from(responseData['healthConcerns'] ?? {});
          _restrictions = Map<String, dynamic>.from(responseData['restrictions'] ?? {});
          _isProfileLoading = false;
          _profileErrorMessage = null;
          _currentState = ScreenState.initial;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          _profileErrorMessage = 'Profile setup incomplete.';
          _isProfileLoading = false;
          _currentState = ScreenState.error;
        });
      } else if (response.statusCode == 401) {
        setState(() {
          _profileErrorMessage = 'Session expired. Please log in again.';
          _isProfileLoading = false;
          _currentState = ScreenState.error;
        });
      } else {
        final errorBody = jsonDecode(response.body);
        setState(() {
          _profileErrorMessage = errorBody['message'] ?? 'Failed to load profile data (Code: ${response.statusCode})';
          _isProfileLoading = false;
          _currentState = ScreenState.error;
        });
      }
    } on TimeoutException {
      setState(() {
        _profileErrorMessage = 'Profile loading timed out.';
        _isProfileLoading = false;
        _currentState = ScreenState.error;
      });
    } catch (e) {
      setState(() {
        _profileErrorMessage = 'Network Error: Could not connect to the server.';
        _isProfileLoading = false;
        _currentState = ScreenState.error;
      });
    }
  }

  // API Fetch Logic
  Future<void> _fetchRestaurantProducts(String query) async {
    if (query.isEmpty) {
      setState(() {
        _restaurantProducts = [];
        _isLoadingRestaurant = false;
      });
      return;
    }

    setState(() => _isLoadingRestaurant = true);

    try {
      final searchUri = Uri.parse(
          '$_spoonacularBaseUrl/food/menuItems/search?query=$query&number=25&apiKey=$_spoonacularApiKey');
      final searchResponse = await http.get(searchUri).timeout(const Duration(seconds: 100));

      if (searchResponse.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(searchResponse.body);
        final List<dynamic> productsJson = data['menuItems'] ?? [];

        List<Product> tempProducts = productsJson
            .where((json) => json['title'] != null && json['id'] != null)
            .map((json) => Product.fromSpoonacularJson(json))
            .toList();

        List<Future<Product>> detailFutures = tempProducts.map((product) async {
          if (product.itemId == null) return product;
          final detailUri =
              Uri.parse('$_spoonacularBaseUrl/food/menuItems/${product.itemId}?apiKey=$_spoonacularApiKey');
          try {
            final detailResponse = await http.get(detailUri).timeout(const Duration(seconds: 100));
            if (detailResponse.statusCode == 200) {
              final Map<String, dynamic> detailData = jsonDecode(detailResponse.body);
              return Product.fromSpoonacularDetailedJson(detailData, product);
            }
            return product;
          } catch (_) {
            return product;
          }
        }).toList();

        _restaurantProducts = await Future.wait(detailFutures);
        _restaurantProducts =
            _restaurantProducts.where((p) => p.imageUrl != null && p.imageUrl!.isNotEmpty).toList();
      } else {
        _restaurantProducts = [];
      }
    } on TimeoutException {
      _restaurantProducts = [];
    } catch (_) {
      _restaurantProducts = [];
    } finally {
      setState(() {
        _isLoadingRestaurant = false;
        _currentState = _updateScreenState();
      });
    }
  }

  Future<void> _fetchFactoryProducts(String query) async {
    if (query.isEmpty) {
      setState(() {
        _factoryProducts = [];
        _isLoadingFactory = false;
      });
      return;
    }

    setState(() => _isLoadingFactory = true);

    final token = await _authService.getToken();
    if (token == null) {
      setState(() {
        _factoryProducts = [];
        _isLoadingFactory = false;
        _currentState = ScreenState.error;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication error. Please log in again.')),
        );
      });
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
      ).timeout(const Duration(seconds: 100));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true && data.containsKey('products')) {
          final List<dynamic> productsJson = data['products'];
          _factoryProducts = productsJson
              .map((json) => Product.fromOpenFoodFactsJson(json))
              .toList();
          _factoryProducts = _factoryProducts
              .where((p) => p.imageUrl != null && p.imageUrl!.isNotEmpty)
              .toList();
        } else {
          _factoryProducts = [];
        }
      } else {
        _factoryProducts = [];
      }
    } on TimeoutException {
      _factoryProducts = [];
    } catch (e) {
      _factoryProducts = [];
    } finally {
      setState(() {
        _isLoadingFactory = false;
        _currentState = _updateScreenState();
      });
    }
  }

  // Update Screen State
  ScreenState _updateScreenState() {
    if (_isProfileLoading || _isLoadingRestaurant || _isLoadingFactory) {
      return ScreenState.loading;
    }
    if (_profileErrorMessage != null) {
      return ScreenState.error;
    }
    if (_searchController.text.isNotEmpty &&
        _restaurantProducts.isEmpty &&
        _factoryProducts.isEmpty &&
        !_isLoadingRestaurant &&
        !_isLoadingFactory) {
      return ScreenState.error;
    }
    if (_restaurantProducts.isNotEmpty || _factoryProducts.isNotEmpty) {
      return ScreenState.success;
    }
    return ScreenState.initial;
  }

  void _searchProducts(String query) async {
    final lowerCaseQuery = query.toLowerCase().trim();
    if (lowerCaseQuery.isEmpty) {
      setState(() {
        _restaurantProducts = [];
        _factoryProducts = [];
        _isLoadingRestaurant = false;
        _isLoadingFactory = false;
        _currentState = ScreenState.initial;
      });
      return;
    }
    setState(() => _currentState = ScreenState.loading);
    await Future.wait([_fetchRestaurantProducts(lowerCaseQuery), _fetchFactoryProducts(lowerCaseQuery)]);
  }

  void _resetScreen() {
    setState(() {
      _searchController.clear();
      _restaurantProducts = [];
      _factoryProducts = [];
      _isLoadingRestaurant = false;
      _isLoadingFactory = false;
      _currentState = ScreenState.initial;
    });
  }

  // UI Builders
  Widget _buildBody() {
    switch (_currentState) {
      case ScreenState.initial:
        return _buildInitialUI();
      case ScreenState.loading:
        return _buildLoadingUI();
      case ScreenState.success:
        return _buildSuccessUI();
      case ScreenState.error:
        return _buildErrorUI();
    }
  }

  Widget _buildInitialUI() {
    // MODIFIED: Wrapped in Center
    return Center(
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            24.0,
            24.0,
            24.0,
            24.0 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _searchController,
                onSubmitted: _searchProducts,
                onChanged: (text) {
                  if (text.isEmpty) _searchProducts('');
                },
                decoration: InputDecoration(
                  hintText: 'Crave something specific...',
                  prefixIcon: Icon(Icons.search, color: primaryAppColor.shade800),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey[400]),
                          onPressed: () {
                            _searchController.clear();
                            _searchProducts('');
                            FocusScope.of(context).unfocus();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide(color: primaryAppColor.shade600),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide(color: primaryAppColor.shade600),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide(color: secondaryAccentColor, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const SizedBox(height: 10),
              Text(
                'Search for restaurant dishes or packaged goods tailored to your health profile.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                  maxWidth: MediaQuery.of(context).size.width * 0.8,
                ),
                child: Lottie.asset(
                  'assets/animation/food_animation.json',
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingUI() {
    String loadingText = 'Loading results...';
    if (_isLoadingRestaurant && _isLoadingFactory) {
      loadingText = 'Searching restaurant menus and packaged goods...';
    } else if (_isLoadingRestaurant) {
      loadingText = 'Checking restaurant menus on Spoonacular...';
    } else if (_isLoadingFactory) {
      loadingText = 'Analyzing products based on your health profile...';
    }
    // MODIFIED: Wrapped in Center
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: secondaryAccentColor),
            const SizedBox(height: 20),
            Text(
              loadingText,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorUI() {
    String errorMessage = _profileErrorMessage ?? 'No items matched your craving. Try a different dish or snack!';
    // MODIFIED: Wrapped in Center
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 20),
            const Text('Oops!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(errorMessage, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _resetScreen,
              style: ElevatedButton.styleFrom(
                backgroundColor: secondaryAccentColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessUI() {
    final hasRestaurantResults = _restaurantProducts.isNotEmpty;
    final hasFactoryResults = _factoryProducts.isNotEmpty;
    final primaryColor = Theme.of(context).primaryColor;
    final accentColor = Theme.of(context).colorScheme.secondary;

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            onSubmitted: _searchProducts,
            onChanged: (text) {
              if (text.isEmpty) _searchProducts('');
            },
            decoration: InputDecoration(
              hintText: 'Crave something specific...',
              prefixIcon: Icon(Icons.search, color: primaryAppColor.shade800),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey[400]),
                      onPressed: () {
                        _searchController.clear();
                        _searchProducts('');
                        FocusScope.of(context).unfocus();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.0),
                borderSide: BorderSide(color: primaryAppColor.shade600),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.0),
                borderSide: BorderSide(color: primaryAppColor.shade600),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.0),
                borderSide: BorderSide(color: secondaryAccentColor, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (hasRestaurantResults) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: primaryAppColor.shade50.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
                border: Border(
                  bottom: BorderSide(color: secondaryAccentColor, width: 2),
                ),
              ),
              child: Text(
                'Restaurant Plates',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: primaryColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 400,
              child: PageView.builder(
                controller: _restaurantPageController,
                itemCount: _restaurantProducts.length,
                itemBuilder: (context, index) {
                  return RestaurantProductCard(
                    product: _restaurantProducts[index],
                    pageController: _restaurantPageController,
                    index: index,
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
          if (hasFactoryResults) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: primaryAppColor.shade50.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
                border: Border(
                  bottom: BorderSide(color: secondaryAccentColor, width: 2),
                ),
              ),
              child: Text(
                'Packaged Goods',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: primaryColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _factoryProducts.length,
              itemBuilder: (context, index) => FactoryProductListTile(product: _factoryProducts[index]),
            ),
            const SizedBox(height: 50),
          ],
        ],
      ),
    );
  }

  // Main Build Method
  @override
  Widget build(BuildContext context) {
    debugPrint('Current state: $_currentState'); // Debug state
    return Scaffold(
        backgroundColor: Color(0xffa8edea),
      appBar: AppBar(
        iconTheme: IconThemeData(color: primaryAppColor.shade800), // MODIFIED for visibility
        leading: _currentState == ScreenState.initial
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
              )
            : null,
        title: Text(
          'Cravings Search',
          style: TextStyle(color: primaryAppColor.shade900), // MODIFIED for visibility
        ),
        actions: [
          if (_currentState != ScreenState.initial)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetScreen,
            ),
        ],
        backgroundColor: Colors.transparent, // MODIFIED
        elevation: 0, // MODIFIED
        centerTitle: true,
      ),
      body: Stack( // MODIFIED
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

  @override
  void dispose() {
    _searchController.dispose();
    _restaurantPageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

// Widgets
class _ErrorMessageBox extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color color;

  const _ErrorMessageBox({required this.message, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(10.0),
      color: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final IconData icon;

  const _InfoPill({required this.text, required this.backgroundColor, required this.textColor, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withOpacity(0.1), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class FactoryProductListTile extends StatelessWidget {
  final Product product;
  const FactoryProductListTile({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final imageUrl = product.imageUrl;
    Widget imageWidget = imageUrl != null
        ? Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: primaryAppColor.shade50,
              child: Center(
                child: Icon(Icons.inventory_2_outlined, size: 30, color: factoryBlue.withOpacity(0.5)),
              ),
            ),
          )
        : Container(
            color: primaryAppColor.shade50,
            child: Center(
              child: Icon(Icons.inventory_2_outlined, size: 30, color: factoryBlue.withOpacity(0.5)),
            ),
          );

    return Container(
      margin: const EdgeInsets.only(bottom: 15.0),
      height: 110,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Viewing factory product: ${product.name}')),
          );
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: 90, child: imageWidget),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          child: Text(
                            product.databaseSource.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              color: factoryBlue,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (product.calories != null)
                          _InfoPill(
                            text: '${product.calories} KCAL',
                            backgroundColor: calorieGreen.withOpacity(0.1),
                            textColor: calorieGreen,
                            icon: Icons.flash_on,
                          ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          product.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: primaryColor,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          product.brand,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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
}

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

  void _launchURL(String? url) async {
    if (url == null) return;
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final accentColor = Theme.of(context).colorScheme.secondary;

    return AnimatedBuilder(
      animation: pageController,
      builder: (context, child) {
        double scale = 1.0;
        if (pageController.position.hasContentDimensions) {
          double page = pageController.page ?? pageController.initialPage.toDouble();
          double distance = (index - page).abs();
          scale = (1.0 - (distance * 0.15)).clamp(0.8, 1.0);
        }

        return Align(
          alignment: Alignment.topCenter,
          child: Transform.scale(
            scale: scale,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 15.0),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 4,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          product.imageUrl != null && product.imageUrl!.isNotEmpty
                              ? Image.network(
                                  product.imageUrl!,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      color: primaryAppColor.shade50,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                              : null,
                                          color: accentColor,
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    color: primaryAppColor.shade50,
                                    child: Center(
                                      child: Icon(Icons.broken_image_outlined, size: 50, color: primaryColor.withOpacity(0.5)),
                                    ),
                                  ),
                                )
                              : Container(
                                  color: primaryAppColor.shade50,
                                  child: Center(
                                    child: Icon(Icons.no_photography_outlined, size: 50, color: primaryColor.withOpacity(0.5)),
                                  ),
                                ),
                          if (product.calories != null)
                            Positioned(
                              top: 15,
                              right: 15,
                              child: _InfoPill(
                                text: '${product.calories} CAL',
                                backgroundColor: calorieGreen,
                                textColor: Colors.white,
                                icon: Icons.local_fire_department,
                              ),
                            ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            child: Container(
                              padding: const EdgeInsets.only(left: 15, right: 20, top: 5, bottom: 5),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.9),
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(20),
                                ),
                              ),
                              child: Text(
                                product.databaseSource.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 6,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.brand,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: accentColor,
                                    letterSpacing: 0.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  product.name,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: primaryColor,
                                    height: 1.2,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Simulating order for ${product.name}')),
                                  );
                                },
                                icon: const Icon(Icons.food_bank),
                                label: const Text(
                                  'Find Order/Recipe',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accentColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  elevation: 5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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