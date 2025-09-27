import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
 
class ApiService {
  static const String _baseUrl = 'http://192.168.18.47:5000/api/predict';

  static Future<String> uploadImage(File image) async {
    var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/predict'));
    
    request.files.add(await http.MultipartFile. fromPath(
      'image',
      image.path,
      contentType: MediaType('image', 'jpeg'),
    ));

    var response = await request.send();
    if (response.statusCode == 200) {
      return await response.stream.bytesToString();
    } else {
      throw Exception('Failed to get prediction');
    }
  }
}