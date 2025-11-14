// lib/services/food_log_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fyp/services/config_service.dart'; // Your config service
import 'package:fyp/services/auth_service.dart'; // Your auth service

class FoodLogService {
  final AuthService _authService = AuthService();

  Future<bool> logFood({
    required String mealType,
    required String productName,
    required Map<String, dynamic> nutrients,
    String? imageUrl, // Optional
    required DateTime date,
  }) async {
    final token = await _authService.getToken();
    if (token == null) {
      print('No token found');
      return false;
    }
 
    final url = Uri.parse('$baseURL/api/foodlog');
    
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'mealType': mealType,
          'product_name': productName,
          'nutrients': nutrients,
          'image_url': imageUrl,
          'date': date.toIso8601String(), // Send date to backend
        }),
      );

      if (response.statusCode == 201) {
        print('Food logged successfully');
        return true;
      } else {
        print('Failed to log food: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error logging food: $e');
      return false;
    }
  }
}