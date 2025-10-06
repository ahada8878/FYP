import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../app_config.dart';

class AuthService {
  static const String baseUrl = 'http://$apiIpAddress:5000/api/auth';
  // static const String baseUrl = 'http://localhost:5000/api/auth'; // For iOS simulator

  // ... (keys and other functions remain the same)
  static const String _tokenKey = 'auth_token';
  static const String _userEmailKey = 'user_email';
  static const String _userId = 'user_id';


  Future<String?> login(String email, String password) async {
    final loginUrl = Uri.parse('$baseUrl/login');

    // ✅ --- NEW DEBUGGING ---
    // This will print the exact address your app is trying to reach.
    if (kDebugMode) {
      print('--- ATTEMPTING TO LOG IN ---');
      print('Target URL: $loginUrl');
      print('---------------------------');
    }
    // -------------------------

    try {
      final response = await http.post(
        loginUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (kDebugMode) {
        print('--- LOGIN RESPONSE ---');
        print('Status Code: ${response.statusCode}');
        print('Response Body: ${response.body}');
        print('----------------------');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveAuthData(data['token'], email, data['user']);
        return data['token'];
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Invalid credentials');
      }
    } on SocketException {
      throw Exception('Network Error: Please check your connection and the IP address in app_config.dart.');
    } on FormatException {
       throw Exception('The server returned an invalid response. Check the server logs.');
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }
  
  // ... (The rest of your AuthService file remains the same)
  Future<dynamic> register(String email, String password, BuildContext context) async { /* ... */ return null; }
  Future<void> deleteAccount() async { /* ... */ }
  Future<void> _saveAuthData(String token, String email, String userId) async { /* ... */ }
  Future<String?> getToken() async { /* ... */ return null; }
  Future<void> logout() async { /* ... */ }
}

