import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config_service.dart';

class AuthService {
  // The base URL for your authentication endpoints.
  static const String baseUrl = 'http://$apiIpAddress:5000/api/auth';

  // Keys for storing user data securely on the device.
  static const String _tokenKey = 'auth_token';
  static const String _userEmailKey = 'user_email';
  static const String _userIdKey = 'user_id';

  /// Authenticates a user and saves their session token.
  Future<String?> login(String email, String password) async {
    final loginUrl = Uri.parse('$baseUrl/login');

    if (kDebugMode) {
      print('--- ATTEMPTING TO LOG IN ---');
      print('Target URL: $loginUrl');
      print('---------------------------');
    }

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

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await _saveAuthData(
          responseData['token'],
          responseData['email'],
          responseData['user'], // The server sends the user ID in the 'user' field
        );
        return responseData['token'];
      } else {
        throw Exception(responseData['message'] ?? 'Invalid credentials');
      }
    } on SocketException {
      throw Exception('Network Error: Could not connect to the server.');
    } on FormatException {
      throw Exception('The server returned an invalid response. Please check the server logs.');
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Registers a new user on the server.
  Future<dynamic> register(String email, String password, BuildContext context) async {
    final registerUrl = Uri.parse('$baseUrl/register');

    if (kDebugMode) {
      print('--- ATTEMPTING TO REGISTER ---');
      print('Target URL: $registerUrl');
      print('-----------------------------');
    }
    
    try {
      final response = await http.post(
        registerUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

       if (kDebugMode) {
        print('--- REGISTER RESPONSE ---');
        print('Status Code: ${response.statusCode}');
        print('Response Body: ${response.body}');
        print('-------------------------');
      }

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
    } on SocketException {
      throw Exception('Network Error: Could not connect to the server.');
    } on FormatException {
       throw Exception('The server returned an invalid response. Check the server logs.');
    } catch (e) {
      throw Exception('Failed to register: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  /// Sends an authenticated request to the server to delete the user's account.
  Future<void> deleteAccount() async {
    final deleteUrl = Uri.parse('$baseUrl/delete');
    
    if (kDebugMode) {
      print('--- ATTEMPTING TO DELETE ACCOUNT ---');
      print('Target URL: $deleteUrl');
      print('---------------------------------');
    }

    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('Not authenticated. Cannot delete account.');
      }

      final response = await http.delete(
        deleteUrl,
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token, // Send the token to authenticate the request
        },
      );

      if (kDebugMode) {
        print('--- DELETE ACCOUNT RESPONSE ---');
        print('Status Code: ${response.statusCode}');
        print('Response Body: ${response.body}');
        print('-----------------------------');
      }

      if (response.statusCode == 200) {
        // If deletion is successful on the server, log the user out locally.
        await logout();
      } else {
        final responseData = jsonDecode(response.body);
        throw Exception(responseData['message'] ?? 'Failed to delete account.');
      }
    } on SocketException {
      throw Exception('Network Error: Could not connect to the server.');
    } on FormatException {
       throw Exception('The server returned an invalid response during account deletion.');
    } catch (e) {
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

  /// Checks if a user is currently logged in by looking for a token.
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }
}