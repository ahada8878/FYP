// lib/models/food_log.dart (Assuming this structure based on backend)

class FoodLog {
  final String id;
  final String mealType;
  final String productName;
  final Nutrients nutrients;
  final String? imageUrl;
  final String? brands;

  FoodLog({
    required this.id, 
    required this.mealType, 
    required this.productName, 
    required this.nutrients, 
    this.imageUrl, 
    this.brands
  });
  
  // Factory constructor for parsing JSON from your backend
  factory FoodLog.fromJson(Map<String, dynamic> json) {
    return FoodLog(
      id: json['_id'] as String? ?? json['id'] as String,
      mealType: json['mealType'] as String,
      productName: json['product_name'] as String,
      imageUrl: json['image_url'] as String?,
      brands: json['brands'] as String?,
      nutrients: Nutrients.fromJson(json['nutrients'] as Map<String, dynamic>),
    );
  }

  static List<FoodLog> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => FoodLog.fromJson(json as Map<String, dynamic>)).toList();
  }
}

class Nutrients {
  final double calories;
  final double protein;
  final double fat;
  final double carbohydrates;

  Nutrients({
    required this.calories, 
    required this.protein, 
    required this.fat, 
    required this.carbohydrates
  });
  
  // Factory constructor for parsing JSON
  factory Nutrients.fromJson(Map<String, dynamic> json) {
    return Nutrients(
      calories: (json['calories'] as num? ?? 0).toDouble(),
      protein: (json['protein'] as num? ?? 0).toDouble(),
      fat: (json['fat'] as num? ?? 0).toDouble(),
      carbohydrates: (json['carbohydrates'] as num? ?? 0).toDouble(),
    );
  }
}