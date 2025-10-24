// lib/services/progress_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fyp/LocalDB.dart';
import 'package:fyp/services/config_service.dart';
import 'package:fyp/models/progress_data.dart'; // Import the new model file

class RealProgressService {
  
  /// --- ⚠️ PLACEHOLDER: NEEDS REAL DATA ---
  /// You must replace this with your actual Google Fit/Health package code.
  Future<Map<String, dynamic>> _getStepDataFromPhone() async {
    // TODO: REPLACE THIS MOCK DATA WITH YOUR GOOGLE FIT/HEALTH IMPLEMENTATION
    await Future.delayed(const Duration(milliseconds: 200)); // Simulates a small delay
    return {
      'stepsToday': 6845, // Replace with real data
      'weeklySteps': [8200, 9500, 7100, 11050, 6500, 12000, 6845], // Replace with real data
    };
  }
  
  /// Fetches all data for the progress hub screen.
  Future<ProgressData> fetchData() async {
    try {
      final authToken = await LocalDB.getAuthToken();
      if (authToken == null) throw Exception('Auth token not found');

      final url = Uri.parse('$baseURL/api/progress/my-hub');
      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $authToken',
      };

      // 1. Get step data from the phone first
      final stepData = await _getStepDataFromPhone();

      // 2. Send step data to the backend
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(stepData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // 3. Parse all data using the factory constructor
        return ProgressData.fromJson(data);
      } else {
        throw Exception('Failed to load progress data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in fetchData: $e');
      throw Exception('Failed to fetch progress data. Please try again.');
    }
  }

  /// Logs a new weight entry
  Future<void> logWeight(double weight) async {
    try {
      final authToken = await LocalDB.getAuthToken();
      if (authToken == null) throw Exception('Auth token not found');

      final url = Uri.parse('$baseURL/api/progress/log-weight');
      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $authToken',
      };
      final body = jsonEncode({'weight': weight});

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode != 201) {
        throw Exception('Failed to log weight: ${response.statusCode}');
      }
      // Success
    } catch (e) {
      print('Error in logWeight: $e');
      throw Exception('Failed to log weight.');
    }
  }
}