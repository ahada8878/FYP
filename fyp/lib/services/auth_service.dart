import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config_service.dart';
import 'package:fyp/Loginpage.dart'; // New
import 'package:fyp/main.dart'; // New

class AuthService {
  // The base URL for your authentication endpoints.
  static const String baseUrl = '$baseURL/api/auth';

  // Keys for storing user data securely on the device.
  static const String _tokenKey = 'auth_token';
  static const String _userEmailKey = 'user_email';
  static const String _userIdKey = 'user_id';

// =========================================================================
// REGISTRATION & LOGIN METHODS (Unchanged)
// =========================================================================

  Future<void> sendOtp(String email, String password) async {
    final sendOtpUrl = Uri.parse('$baseUrl/send-otp');
    
    
    if (kDebugMode) {
      print('--- ATTEMPTING TO SEND OTP ---');
    }
    
    try {
      final response = await http.post(
        sendOtpUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      final responseData = jsonDecode(response.body);

      if (response.statusCode != 200) {
        throw Exception(responseData['message'] ?? 'Failed to send verification code.');
      }
      // Success is implied by status 200, no return data needed
    } on SocketException {
      throw Exception('Network Error: Could not connect to the server.');
    } on FormatException {
       throw Exception('The server returned an invalid response. Check the server logs.');
    } catch (e) {
      // Re-throw the clean error message
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }


  /// STEP 2: Verifies the OTP and completes the registration, returning the token/user data.
  Future<Map<String, dynamic>> verifyOtp(String email, String password, String otp) async {
    final verifyOtpUrl = Uri.parse('$baseUrl/verify-otp');
    
    if (kDebugMode) {
      print('--- ATTEMPTING TO VERIFY OTP ---');
    }
    
    try {
      final response = await http.post(
        verifyOtpUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password, 'otp': otp}),
      );
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Verification successful, save the token and user data
        if (responseData['token'] == null) {
          throw Exception('Verification successful but token is missing');
        }
        await _saveAuthData(
          responseData['token'],
          responseData['email'],
          responseData['userId'],
        );
        return responseData;
      } else {
        throw Exception(responseData['message'] ?? 'Verification failed or OTP is incorrect.');
      }
    } on SocketException {
      throw Exception('Network Error: Could not connect to the server.');
    } on FormatException {
       throw Exception('The server returned an invalid response. Check the server logs.');
    } catch (e) {
      // Re-throw the clean error message
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

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

      if (kDebugMode) {
        print('--- LOGIN RESPONSE ---');
        print('Status Code: ${response.statusCode}');
        print('Response Body: ${response.body}');
        print('----------------------');
      }

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // The server sends the user ID in the 'user' field in login
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
  
  // NOTE: The separate register method seems redundant with sendOtp/verifyOtp but is kept here
  // for completeness. If you use sendOtp/verifyOtp, you likely won't need this register() method.
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
    } on SocketException {
      throw Exception('Network Error: Could not connect to the server.');
    } on FormatException {
       throw Exception('The server returned an invalid response. Check the server logs.');
    } catch (e) {
      throw Exception('Failed to register: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }


// =========================================================================
// EMAIL UPDATE METHODS (Unchanged)
// =========================================================================

  /// STEP 1: Sends an authenticated request to send OTP to the new email.
  Future<void> sendUpdateOtp(String newEmail) async {
    final sendUpdateUrl = Uri.parse('$baseUrl/send-update-otp');
    
    if (kDebugMode) {
      print('--- ATTEMPTING TO SEND UPDATE OTP ---');
    }
    
    try {
      final token = await getToken();
      if (token == null) throw Exception('Authentication required.');

      final response = await http.post(
        sendUpdateUrl,
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token, // Authenticate the request
        },
        body: jsonEncode({'newEmail': newEmail}),
      );
      final responseData = jsonDecode(response.body);

      if (response.statusCode != 200) {
        throw Exception(responseData['message'] ?? 'Failed to send verification code for email update.');
      }
    } on SocketException {
      throw Exception('Network Error: Could not connect to the server.');
    } on FormatException {
       throw Exception('The server returned an invalid response. Check the server logs.');
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// STEP 2: Verifies the OTP and commits the email change on the server.
  Future<Map<String, dynamic>> verifyUpdateEmail(String otp, String newEmail) async {
    final verifyUpdateUrl = Uri.parse('$baseUrl/verify-update-email');
    
    if (kDebugMode) {
      print('--- ATTEMPTING TO VERIFY EMAIL UPDATE OTP ---');
    }
    
    try {
      final token = await getToken();
      if (token == null) throw Exception('Authentication required.');

      final response = await http.post(
        verifyUpdateUrl,
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token, // Authenticate the request
        },
        body: jsonEncode({'otp': otp, 'newEmail': newEmail}),
      );
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Success: Update the locally stored email address
        final newEmail = responseData['newEmail'];
        if (newEmail != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_userEmailKey, newEmail);
        }
        return responseData;
      } else {
        throw Exception(responseData['message'] ?? 'Email update verification failed.');
      }
    } on SocketException {
      throw Exception('Network Error: Could not connect to the server.');
    } on FormatException {
       throw Exception('The server returned an invalid response. Check the server logs.');
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Sends an authenticated request to change the current user's password.
  Future<void> changePassword(String oldPassword, String newPassword) async {
    final changePasswordUrl = Uri.parse('$baseUrl/change-password');
    final token = await getToken();

    if (token == null) {
      throw Exception('Not authenticated. Please log in.');
    }

    if (kDebugMode) {
      print('--- ATTEMPTING TO CHANGE PASSWORD ---');
    }

    try {
      final response = await http.post(
        changePasswordUrl,
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token, // Consistent authentication header
        },
        body: jsonEncode({
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        }),
      );

      if (kDebugMode) {
        print('--- CHANGE PASSWORD RESPONSE ---');
        print('Status Code: ${response.statusCode}');
        print('Response Body: ${response.body}');
        print('------------------------------');
      }

      if (response.statusCode == 200) {
        // Success
        return;
      } else {
        final responseData = jsonDecode(response.body);
        throw Exception(responseData['message'] ?? 'Failed to change password.');
      }
    } on SocketException {
      throw Exception('Network Error: Could not connect to the server.');
    } on FormatException {
       throw Exception('The server returned an invalid response during password change.');
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

// =========================================================================
// PASSWORD RESET METHODS (Updated)
// =========================================================================

  Future<void> sendPasswordResetOtp(String email) async {
    // Matches server route: POST /forgot-password
    final url = Uri.parse('$baseUrl/forgot-password');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode != 200) {
        throw Exception(responseData['message'] ?? 'Failed to send reset code.');
      }
    } on SocketException {
      throw Exception('Network Error: Could not connect to the server.');
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// NOTE: This method is commented out because the server's POST /reset-password route 
  /// now handles both OTP verification and password change in a single request.
  // Future<void> verifyPasswordResetOtp(String email, String otp) async {
  //   // Note: The backend would typically return a temporary token here.
  //   final url = Uri.parse('$baseUrl/verify-otp'); 

  //   try {
  //     final response = await http.post(
  //       url,
  //       headers: {'Content-Type': 'application/json'},
  //       body: jsonEncode({'email': email, 'otp': otp}),
  //     );

  //     final responseData = jsonDecode(response.body);

  //     if (response.statusCode != 200) {
  //       throw Exception(responseData['message'] ?? 'Invalid or expired code.');
  //     }
  //   } on SocketException {
  //     throw Exception('Network Error: Could not connect to the server.');
  //   } catch (e) {
  //     throw Exception(e.toString().replaceAll('Exception: ', ''));
  //   }
  // }
  
  /// Performs the final password reset using the email, OTP, and the new password.
  /// **UPDATED to include 'otp' in the request body.**
  Future<void> resetPassword(String email, String otp, String newPassword) async {
    // Matches server route: POST /reset-password
    final url = Uri.parse('$baseUrl/reset-password');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email, 
          'otp': otp, // Now includes the OTP
          'newPassword': newPassword
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode != 200) {
        throw Exception(responseData['message'] ?? 'Failed to reset password.');
      }
    } on SocketException {
      throw Exception('Network Error: Could not connect to the server.');
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

// =========================================================================
// USER DETAILS METHOD (Unchanged)
// =========================================================================

  /// Fetches the authenticated user's details (e.g., email, ID, profile data).
  Future<Map<String, dynamic>> fetchUserDetails() async {
    // Matches new server route: GET /me
    final url = Uri.parse('$baseUrl/me');

    if (kDebugMode) {
      print('--- ATTEMPTING TO FETCH USER DETAILS (GET /me) ---');
    }

    try {
      final token = await getToken();
      if (token == null) throw Exception('Authentication required.');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token, // Authenticate the request
        },
      );

      if (kDebugMode) {
        print('--- GET /me RESPONSE ---');
        print('Status Code: ${response.statusCode}');
        print('Response Body: ${response.body}');
        print('------------------------');
      }

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseData;
      } else {
        throw Exception(responseData['message'] ?? 'Failed to fetch user details.');
      }
    } on SocketException {
      throw Exception('Network Error: Could not connect to the server.');
    } on FormatException {
      throw Exception('The server returned an invalid response. Check the server logs.');
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> verifyPasswordResetOtp(String email, String otp) async {
  // TODO: Replace this with your actual API call.
  // Example: final response = await http.post(Uri.parse('$baseUrl/forgot-password/verify-otp'), body: {'email': email, 'otp': otp});

  if (otp.length != 6) {
    throw Exception("Invalid code format.");
  }
  
  // Simulate an invalid OTP check
  if (otp == '000000') {
    throw Exception("The verification code is incorrect.");
  }

  // Simulate API delay
  await Future.delayed(const Duration(seconds: 1));

  // For now, assume success for the UI logic to proceed to Step 3
  print('OTP verified for $email');
}


// =========================================================================
// ACCOUNT MANAGEMENT & STORAGE METHODS (Unchanged)
// =========================================================================

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

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userEmailKey);
    print("🔒 Token cleared due to 401 error or logout.");

    // Use the global navigator key to navigate to LoginPage
    // and remove all other screens from the stack
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState!.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const CreativeLoginPage()),
        (Route<dynamic> route) => false, // Remove all previous routes
      );
    }
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