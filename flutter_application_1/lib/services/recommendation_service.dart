import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/constants.dart';

class RecommendationService {
  static const String baseUrl = AppConstants.baseUrl;

  // ดึงรายการแนะนำอาหาร
  // Endpoint: GET /recommendations/foods
  Future<List<Map<String, String>>?> getRecommendedFoods() async {
    final url = Uri.parse('$baseUrl/recommendations/foods');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        
        // แปลงเป็น List<Map<String, String>>
        return data.map((item) => {
          'name': item['name'].toString(),
          'cal': item['cal'].toString(),
          'image': item['image'].toString(),
        }).toList();
      } else {
        print('Get Rec Foods Failed: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching rec foods: $e');
      return null;
    }
  }

  // ดึงรายการแนะนำเครื่องดื่ม
  // Endpoint: GET /recommendations/drinks
  Future<List<Map<String, String>>?> getRecommendedDrinks() async {
    final url = Uri.parse('$baseUrl/recommendations/drinks');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        
        return data.map((item) => {
          'name': item['name'].toString(),
          'cal': item['cal'].toString(),
          'image': item['image'].toString(),
        }).toList();
      } else {
        print('Get Rec Drinks Failed: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching rec drinks: $e');
      return null;
    }
  }
}
