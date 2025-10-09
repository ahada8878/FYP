import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config_service.dart'; // Assumed to contain apiIpAddress

// NOTE ON SECURITY: shared_preferences is NOT secure for storing JWTs. 
// This is used here for compatibility with your existing code structure,
// but should be replaced by flutter_secure_storage in a production app.

class AuthService {
  // =========================================================
  // ✅ FIX 1: Implementation of the Singleton Pattern
  // This ensures all parts of the app use the same, correct instance.
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal(); // Private constructor
  // =========================================================

  // The base URL for your authentication endpoints.
  static const String baseUrl = 'http://$apiIpAddress:5000/api/auth';

  // Keys for storing user data locally.
  static const String _tokenKey = 'auth_token';
  static const String _userEmailKey = 'user_email';
  static const String _userIdKey = 'user_id';

  /// Authenticates a user and saves their session token.
  Future<String?> login(String email, String password) async {
    final loginUrl = Uri.parse('$baseUrl/login');

    if (kDebugMode) {
      print('--- ATTEMPTING TO LOG IN ---');
    }

    try {
      final response = await http.post(
        loginUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // The server sends the user ID in the 'user' field in login
        await _saveAuthData(
          responseData['token'],
          responseData['email'],
          responseData['user'], 
        );
        return responseData['token'];
      } else {
        throw Exception(responseData['message'] ?? 'Invalid credentials');
      }
    } catch (e) {
        if (e is SocketException) throw Exception('Network Error: Could not connect to the server.');
        throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Registers a new user on the server.
  Future<dynamic> register(String email, String password, BuildContext context) async {
    final registerUrl = Uri.parse('$baseUrl/register');
    
    if (kDebugMode) {
      print('--- ATTEMPTING TO REGISTER ---');
    }
    
    try {
      final response = await http.post(
        registerUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (responseData['token'] == null) {
          throw Exception('Registration successful but token is missing');
        }
        await _saveAuthData(
          responseData['token'],
          responseData['email'],
          responseData['userId'],
        );
        return responseData;
      } else {
        throw Exception(responseData['message'] ?? 'Registration failed');
      }
    } catch (e) {
        if (e is SocketException) throw Exception('Network Error: Could not connect to the server.');
        throw Exception('Failed to register: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  /// Sends an authenticated request to the server to delete the user's account.
  Future<void> deleteAccount() async {
    final deleteUrl = Uri.parse('$baseUrl/delete');
    
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('Not authenticated. Cannot delete account.');
      }

      final response = await http.delete(
        deleteUrl,
        headers: {
          'Content-Type': 'application/json',
          // CRITICAL FIX: Use the standard Bearer token header for consistency
          'Authorization': 'Bearer $token', 
        },
      );

      if (response.statusCode == 200) {
        await logout();
      } else {
        final responseData = jsonDecode(response.body);
        throw Exception(responseData['message'] ?? 'Failed to delete account.');
      }
    } catch (e) {
      if (e is SocketException) throw Exception('Network Error: Could not connect to the server.');
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Clears all stored user session data from the device.
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// Saves user token, email, and ID to the device's local storage.
  Future<void> _saveAuthData(String token, String email, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userEmailKey, email);
    await prefs.setString(_userIdKey, userId);
  }

  /// Retrieves the user's authentication token from local storage.
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Retrieves the user's ID from local storage.
  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  /// Checks if a user is currently logged in by looking for a token.
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }
}