import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService {
  static const String baseUrl = 'http://192.168.100.110:5000/api/auth';
  // static const String baseUrl = 'http://localhost:5000/api/auth'; // For iOS simulator

  // Shared Preferences Keys
  static const String _tokenKey = 'auth_token';
  static const String _userEmailKey = 'user_email';

  Future<String?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveAuthData(data['token'], email);
        return data['token'];
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Invalid credentials');
      }
    } catch (e) {
      throw Exception('Failed to login: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  Future<String?> register(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        await _saveAuthData(data['token'], email);
        return data['token'];
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Registration failed');
      }
    } catch (e) {
      throw Exception('Failed to register: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  Future<void> _saveAuthData(String token, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userEmailKey, email);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<String?> getLoggedInEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userEmailKey);
  }

  // Add this method to your User model or keep it here
  Map<String, dynamic> userToJson(User user) {
    return {
      'email': user.email,
      'password': user.password,
    };
  }
}