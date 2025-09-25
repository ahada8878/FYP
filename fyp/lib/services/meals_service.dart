import 'dart:convert';
import 'package:http/http.dart' as http;

class MealsService {
  final String baseUrl = 'http://192.168.18.39:5000/api';

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