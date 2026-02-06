import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/constants.dart';

class FoodService {
  static const String baseUrl = AppConstants.baseUrl;

  // ดึงรายการอาหารทั้งหมด
  // Endpoint: GET /foods
  Future<List<dynamic>?> getAllFoods() async {
    final url = Uri.parse('$baseUrl/foods');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        print('Get Foods Failed: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching foods: $e');
      return null;
    }
  }

  // ค้นหาอาหาร
  // Endpoint: GET /foods/search?q=...
  Future<List<dynamic>?> searchFoods(String query) async {
    final url = Uri.parse('$baseUrl/foods/search?q=$query');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        print('Search Foods Failed: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error searching foods: $e');
      return null;
    }
  }
}
