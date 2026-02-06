import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/constants.dart';

class MealService {
  static const String baseUrl = AppConstants.baseUrl;

  // บันทึกมื้ออาหาร
  // Endpoint: POST /meals/log
  Future<bool> logMeal(String token, Map<String, dynamic> mealData) async {
    final url = Uri.parse('$baseUrl/meals/log');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(mealData),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Log Meal Failed: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error logging meal: $e');
      return false;
    }
  }

  // ดึงสรุปรายวัน
  // Endpoint: GET /meals/summary/{date_str}
  Future<Map<String, dynamic>?> getDailySummary(String token, String dateStr) async {
    final url = Uri.parse('$baseUrl/meals/summary/$dateStr');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Backend return DailySummaryResponse (with total_calories_intake, etc.)
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        print('Get Summary Failed: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching summary: $e');
      return null;
    }
  }

  // ดึงรายการมื้ออาหารของวัน (เพื่อใช้หา ID สำหรับลบ)
  // Endpoint: GET /meals/by-date?date_str=...
  Future<List<dynamic>?> getMealsByDate(String token, String dateStr) async {
    final url = Uri.parse('$baseUrl/meals/by-date?date_str=$dateStr');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        print('Get Meals Failed: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching meals: $e');
      return null;
    }
  }

  // ลบมื้ออาหารตาม ID
  // Endpoint: DELETE /meals/{meal_id}
  Future<bool> deleteMeal(String token, int mealId) async {
    final url = Uri.parse('$baseUrl/meals/$mealId');
    try {
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Delete Meal Failed: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error deleting meal: $e');
      return false;
    }
  }

  // Helper: ลบมื้ออาหารตามประเภท (เช่น ลบมื้อเช้าทั้งหมดของวันนี้)
  // เนื่องจาก AppHomeScreen ส่งมาแค่ String mealType ('breakfast')
  // เราต้องไปหา ID ของมื้อนั้นก่อน
  Future<bool> deleteMealByType(String token, String dateStr, String mealType) async {
    try {
      // 1. ดึงรายการมื้ออาหารทั้งหมดของวัน
      final meals = await getMealsByDate(token, dateStr);
      if (meals == null || meals.isEmpty) return false;

      // 2. หา Meal ที่ตรงกับ Type (Backend เก็บเป็น: breakfast, lunch, dinner, snack)
      // เช็คว่าใน List มีอันไหน match กับ mealType ไหม
      // หมายเหตุ: mealType จาก Frontend อาจจะเป็น 'breakfast', 'lunch' ตรงๆ
      
      // หาทุก meal ที่เป็น type นี้ (ปกติวันนึงควรมี type ละ 1 meal แต่กันพลาด)
      final matchedMeals = meals.where((m) => m['meal_type'] == mealType).toList();

      if (matchedMeals.isEmpty) return false;

      // 3. ลบทุกอันที่เจอ
      bool allSuccess = true;
      for (var m in matchedMeals) {
        int id = m['meal_id'];
        bool success = await deleteMeal(token, id);
        if (!success) allSuccess = false;
      }

      return allSuccess;
    } catch (e) {
      print('Error deleting meal by type: $e');
      return false;
    }
  }
}
