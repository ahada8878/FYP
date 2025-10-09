import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config_service.dart'; // Import the config file for IP and port

class MealsService {
  final String baseUrl = 'http://$apiIpAddress:5000/api';

  MealsService();

  Future<List<dynamic>> fetchMeals() async {
    final response = await http.get(Uri.parse('$baseUrl/meals'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['meals'] ?? [];
    } else {
      throw Exception('Failed to load meals');
    }
  }
}