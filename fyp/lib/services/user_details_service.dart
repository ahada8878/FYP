import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_details.dart';

class UserDetailsService {
  static const String baseUrl = 'http://192.168.18.39:5000/api';

  static Future<UserDetails?> fetchUserDetails(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/user-details/$id'));
    if (response.statusCode == 200) {
      return UserDetails.fromJson(json.decode(response.body));
    } else {
      return null;
    }
  }

  static Future<bool> postUserDetails(UserDetails userDetails) async {
    final response = await http.post(
      Uri.parse('$baseUrl/user-details'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(userDetails.toJson()),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }
}
