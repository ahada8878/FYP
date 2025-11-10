import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:fyp/services/auth_service.dart'; // Import your AuthService

/// A custom http.Client that automatically adds the auth token to headers
/// and handles 401 Unauthorized errors by logging the user out.
class CustomHttpClient extends http.BaseClient {
  final http.Client _inner = http.Client();
  final AuthService _authService = AuthService(); // Instance of your AuthService

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // 1. Get the token
    final String? token = await _authService.getToken();

    // 2. Add the token to the request header if it exists
    if (token != null) {
      // Your backend authMiddleware.js looks for 'x-auth-token'
      request.headers['x-auth-token'] = token;
    }

    // 3. Send the request
    final http.StreamedResponse response;
    try {
      response = await _inner.send(request);
    } catch (e) {
      // Handle network errors, etc.
      if (kDebugMode) {
        print('HTTP Client Error: $e');
      }
      rethrow;
    }

    // 4. Check for 401 Unauthorized
    if (response.statusCode == 401) {
      if (kDebugMode) {
        print('🚨 401 Unauthorized detected. Logging out...');
      }
      
      // 5. Call your existing logout method
      // We don't need to 'await' this, as it will handle navigation.
      // We use a try-catch in case it's already logging out.
      try {
        _authService.logout();
      } catch (e) {
        if (kDebugMode) {
          print('Error during 401 logout: $e');
        }
      }
      
      // Stop further processing by throwing an exception.
      // The UI will be navigated to the LoginPage.
      throw Exception('Unauthorized (401): Session expired.');
    }

    return response;
  }
}