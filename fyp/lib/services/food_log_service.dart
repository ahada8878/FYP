// lib/services/food_log_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fyp/services/config_service.dart'; // Your config service
import 'package:fyp/services/auth_service.dart'; // Your auth service
import 'package:intl/intl.dart'; // For date formatting
import 'package:fyp/models/food_log.dart'; // Import the FoodLog model


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


/// Fetches all food logs for a given date and returns the summed totals
  /// for key nutrients.
  Future<Map<String, double>> getDailyNutrientTotals(DateTime date) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('No authentication token found.');
    }
  // Format the date to 'YYYY-MM-DD' to match the API route
    final String formattedDate = DateFormat('yyyy-MM-dd').format(date);
    final url = Uri.parse('$baseURL/api/foodlog/$formattedDate');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        
        // Assuming the backend returns { "success": true, "data": [ ...logs ] }
        // or just [ ...logs ]
        // Let's check for a 'data' key first.
        final List<dynamic> logs = (body is Map && body.containsKey('data')) ? body['data'] : body;

        // Aggregate the totals
        Map<String, double> totals = {
          'calories': 0.0,
          'protein': 0.0,
          'fat': 0.0,
          'carbohydrates': 0.0,
        };

        for (var log in logs) {
          if (log['nutrients'] != null) {
            totals['calories'] = (totals['calories'] ?? 0) + (log['nutrients']['calories'] ?? 0.0);
            totals['protein'] = (totals['protein'] ?? 0) + (log['nutrients']['protein'] ?? 0.0);
            totals['fat'] = (totals['fat'] ?? 0) + (log['nutrients']['fat'] ?? 0.0);
            totals['carbohydrates'] = (totals['carbohydrates'] ?? 0) + (log['nutrients']['carbohydrates'] ?? 0.0);
          }
        }
        
        print('Fetched daily totals: $totals');
        return totals;

      } else {
        print('Failed to fetch food logs: ${response.body}');
        throw Exception('Failed to load food logs.');
      }
    } catch (e) {
      print('Error in getDailyNutrientTotals: $e');
      throw Exception('Error fetching food logs: $e');
    }
  }

  // --- NEW METHOD ---
  /// Fetches all food logs for a given date.
  Future<List<FoodLog>> getFoodLogsForDate(DateTime date) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('No authentication token found.');
    }

    // Format the date to 'YYYY-MM-DD' to match the API route
    final String formattedDate = DateFormat('yyyy-MM-dd').format(date);
    final url = Uri.parse('$baseURL/api/foodlog/$formattedDate');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-R',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        // Check for the 'data' key as returned by your controller
        if (body is Map && body.containsKey('data') && body['data'] is List) {
          // Use the FoodLog.fromJsonList factory to parse the list
          return FoodLog.fromJsonList(body['data'] as List);
        } else {
          // Fallback if the structure is different (e.g., just the list)
          return FoodLog.fromJsonList(body as List);
        }
      } else {
        print('Failed to fetch food logs: ${response.body}');
        throw Exception('Failed to load food logs.');
      }
    } catch (e) {
      print('Error in getFoodLogsForDate: $e');
      throw Exception('Error fetching food logs: $e');
    }
  }
}