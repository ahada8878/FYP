// lib/utils/food_parser.dart
class FoodParser {
  static Map<String, dynamic> parsePredictionString(String prediction) {
    try {
      final parts = prediction.split(':');
      if (parts.length < 2) {
        throw Exception('Invalid format: Expected "Food: nutrients"');
      }
      
      final String productName = parts[0].trim();
      final nutrientString = parts.sublist(1).join(':').trim();

      final nutrients = <String, double>{};
      final nutrientParts = nutrientString.split(',');

      if (nutrientParts.isEmpty) {
         throw Exception('Invalid format: No nutrient data found');
      }

      for (var part in nutrientParts) {
        final keyValue = part.trim().split(' ');
        if (keyValue.length < 2) continue;

        final key = keyValue[0].trim().replaceAll(':', '');
        final value = double.tryParse(keyValue[1].replaceAll('g', '')) ?? 0.0;
        
        if (key == 'calories') {
          nutrients['calories'] = value;
        } else if (key == 'protein') {
          nutrients['protein'] = value;
        } else if (key == 'fat') {
          nutrients['fat'] = value;
        } else if (key == 'carbohydrates') {
          nutrients['carbohydrates'] = value;
        }
      }

      return {
        'product_name': productName,
        'nutrients': nutrients,
      };
    } catch (e) {
      print('Error parsing prediction string: $e');
      // Return a default error structure
      return {
        'product_name': 'Parse Error',
        'nutrients': {
          'calories': 0.0,
          'protein': 0.0,
          'fat': 0.0,
          'carbohydrates': 0.0,
        },
      };
    }
  }
}