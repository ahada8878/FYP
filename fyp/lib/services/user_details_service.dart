import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_details.dart';
import 'config_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserDetailsService {
  static const String baseUrl = 'http://$apiIpAddress:5000/api';

  // No changes needed for this function
  static Future<UserDetails?> fetchUserDetails(String id) async {
    // ...
  }

  // ✅ 2. RENAME AND REWRITE this function completely
  static Future<dynamic> saveMyProfile(UserDetails profile) async {
    // A. Get the token from device storage
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token'); // Use the correct key

    if (token == null) {
      throw Exception('Authentication token not found. Please log in again.');
    }

    // B. Use the correct URL for the logged-in user's profile
    final url = Uri.parse("$baseUrl/user-details/my-profile");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        // C. Add the authentication token to the header
        "x-auth-token": token,
      },
      body: jsonEncode(profile.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to save details: ${response.body}");
    }
  }
}