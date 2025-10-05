import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../app_config.dart'; // Import the config file for IP and port

class AuthService {
  static const String baseUrl = 'http://$apiIpAddress:5000/api/auth';
  // static const String baseUrl = 'http://localhost:5000/api/auth'; // For iOS simulator

  // Shared Preferences Keys
  static const String _tokenKey = 'auth_token';
  static const String _userEmailKey = 'user_email';
  static const String _userId = 'user_id';

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
        await _saveAuthData(data['token'], email, data['user']);
        return data['token'];
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Invalid credentials');
      }
    } catch (e) {
      throw Exception('Failed to login: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

Future<dynamic> register(String email, String password,BuildContext context) async { 
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
     

    final responseBody = jsonDecode(response.body);
    
    if (response.statusCode == 200 || response.statusCode == 201) {
       
      // Success case
      final data = responseBody;
      
      
      // Ensure required fields are present
      if (data['token'] == null) {
        throw Exception('Registration successful but token is missing');
      }
      
     
      
      // Save auth data with userId if available
      await _saveAuthData(
        data['token'] as String,
        data['email'] as String ,
        data['userId'] as String,
      );
      
      
      return data;
    } else {
      // Error case - handle different error formats
      final errorMessage = responseBody['message'] ?? 
                          responseBody['error'] ?? 
                          'Registration failed with status code ${response.statusCode}';
      throw Exception(errorMessage);
    }
  } on http.ClientException catch (e) {
    throw Exception('Network error: ${e.message}');
  } on FormatException catch (e) {
    throw Exception('Invalid response format: ${e.message}');
  } catch (e) {
    throw Exception('Failed to register: ${e.toString().replaceAll('Exception: ', '')}');
  }
}

  Future<void> _saveAuthData(String token, String email, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userEmailKey, email);
    await prefs.setString(_userId, userId);
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