import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_details.dart';
import 'config_service.dart';

class UserDetailsService {
  static const String baseUrl = 'http://$apiIpAddress:5000/api';

  static Future<UserDetails?> fetchUserDetails(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/user-details/$id'));
    if (response.statusCode == 200) {
      return UserDetails.fromJson(json.decode(response.body));
    } else {
      return null;
    }
  }

  static Future<dynamic> postUserDetails(UserDetails profile) async {
  final response = await http.post(
    Uri.parse("http://$apiIpAddress:5000/api/user-details"), // FIXED
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(profile.toJson()),
  );

  if (response.statusCode == 200 || response.statusCode == 201) {
    return jsonDecode(response.body);
  } else {
    throw Exception("Failed to save details: ${response.body}");
  }
}

}
