// You need to create a service to handle this
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'config_service.dart';

class ActivityService {
  final String baseUrl = 'http://$apiIpAddress:5000/api';

  Future<void> logActivity({
    required String activityType,
    required int duration,
    required double caloriesBurned,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token'); // Assuming you store a JWT

    final response = await http.post(
      Uri.parse('$baseUrl/activities'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'activityType': activityType,
        'duration': duration,
        'caloriesBurned': caloriesBurned,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to log activity');
    }
  }
}