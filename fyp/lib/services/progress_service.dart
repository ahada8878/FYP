import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fyp/LocalDB.dart'; 
// Import the config service where MyConfigService.baseURL resides
import 'package:fyp/services/config_service.dart'; 
import 'package:fyp/models/progress_data.dart'; 
import 'package:fyp/services/auth_service.dart'; 
import 'package:fyp/services/health_service.dart';


// ⚡️ Assume MyConfigService has a static property named baseURL
// If MyConfigService is a class with a static const string, this works:


class RealProgressService {
  final AuthService _authService = AuthService();
  final HealthService _healthService = HealthService(); // 2. Initialize
  
  // NOTE: If MyConfigService.baseURL was an instance property, 
  // you would need to initialize MyConfigService here.
  
  /// --- ⚠️ PLACEHOLDER: NOT USED BY fetchData NOW ---
  Future<Map<String, dynamic>> _getStepDataFromPhone() async {
    await Future.delayed(const Duration(milliseconds: 200)); 
    return {
      'stepsToday': 6845,
      'weeklySteps': [8200, 9500, 7100, 11050, 6500, 12000, 6845],
    };
  }
  
  // ----------------------------------------------------------------------
  
  /// Fetches all data for the progress hub screen using the single GET route: /api/user/profile-summary
  Future<ProgressData> fetchData() async {
    // 3. Fetch Real Steps immediately
    int realSteps = 0;
    List<int> realWeeklySteps = [];
    try {
      realSteps = await _healthService.fetchTodaySteps();
      realWeeklySteps = await _healthService.fetchWeeklySteps();
    } catch (e) {
      print("Health Service Error: $e");
    }
    try {
      final authToken = await _authService.getToken();
      if (authToken == null) throw Exception('Auth token not found');

      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $authToken',
      };

      // 1. 🚀 Attempt fetch from server using the const _BASE_URL
      final fetchUrl = Uri.parse('$baseURL/api/user/profile-summary');
      final fetchResponse = await http.get(
        fetchUrl,
        headers: headers,
      );

      // 2. Handle successful response (200 OK)
      if (fetchResponse.statusCode == 200) {
        final data = jsonDecode(fetchResponse.body);
        
        if (data['success'] == true) {
            // Success: Save data and return it
            await ProgressData.saveToLocalDB(data);
            ProgressData progress = ProgressData.fromJson(data);
            // 4. OVERRIDE with Real Steps using copyWith
            return progress.copyWith(
              steps: realSteps,
              weeklyStepsData: realWeeklySteps.isNotEmpty ? realWeeklySteps : null
            );
        } else {
            // Server responded 200 but with an error message (success: false)
            print('Server success: false. Status: 200. Falling back to LocalDB.');
            return (await ProgressData.fromLocalDB()).copyWith(steps: realSteps);
        }
      } else {
        // Server returned non-200 status (e.g., 401, 500)
        print('Server status code ${fetchResponse.statusCode}. Falling back to LocalDB.');
        return (await ProgressData.fromLocalDB()).copyWith(steps: realSteps);
      }
    } catch (e) {
      // 4. 🚨 CRITICAL: Network/Auth error occurred, NOW use the fallback
      print('Network/Auth Error: $e. Attempting LocalDB fallback.');
      try {
        return (await ProgressData.fromLocalDB()).copyWith(steps: realSteps);
      } catch (localE) {
        print('LocalDB fallback failed: $localE');
        throw Exception('Failed to load progress data from server and local cache. Check your connection.');
      }
    }
  }

  /// Logs a new weight entry using a POST request
  Future<void> logWeight(double weight) async {
    try {
      final authToken = await _authService.getToken(); 
      if (authToken == null) throw Exception('Auth token not found');

      final url = Uri.parse('$baseURL/api/progress/log-weight');
      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $authToken',
      };
      final body = jsonEncode({'weight': weight});

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception('Failed to log weight: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in logWeight: $e');
      throw Exception('Failed to log weight.');
    }
  }
}