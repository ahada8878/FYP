// lib/models/food_log.dart

import 'dart:convert';

class FoodLog {
  final String id;
  final String user;
  final DateTime date;
  final String mealType;
  final String productName;
  final String? brands;
  final String? imageUrl;
  final Nutrients nutrients;

  FoodLog({
    required this.id,
    required this.user,
    required this.date,
    required this.mealType,
    required this.productName,
    this.brands,
    this.imageUrl,
    required this.nutrients,
  });

  factory FoodLog.fromJson(Map<String, dynamic> json) {
    return FoodLog(
      // Use '_id' from MongoDB
      id: json['_id'] as String, 
      user: json['user'] as String,
      date: DateTime.parse(json['date'] as String),
      mealType: json['mealType'] as String,
      productName: json['product_name'] as String,
      brands: json['brands'] as String?,
      imageUrl: json['image_url'] as String?,
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
    required this.carbohydrates,
  });

  factory Nutrients.fromJson(Map<String, dynamic> json) {
    return Nutrients(
      calories: (json['calories'] ?? 0).toDouble(),
      protein: (json['protein'] ?? 0).toDouble(),
      fat: (json['fat'] ?? 0).toDouble(),
      carbohydrates: (json['carbohydrates'] ?? 0).toDouble(),
    );
  }
}