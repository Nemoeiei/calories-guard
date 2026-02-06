import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/constants.dart'; // ✅ Import Constants

class AuthService {
  // ✅ ใช้ Base URL กลางจาก Constants
  static const String baseUrl = AppConstants.baseUrl;

  // ฟังก์ชันสมัครสมาชิก
  Future<Map<String, dynamic>> register(String username, String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/register'); // ✅ เพิ่ม /auth prefix
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        final errorData = jsonDecode(response.body);
        return {'success': false, 'message': errorData['detail'] ?? 'Registration failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // ฟังก์ชันเข้าสู่ระบบ
  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/login'); // ✅ เพิ่ม /auth prefix

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        final errorData = jsonDecode(response.body);
        return {'success': false, 'message': errorData['detail'] ?? 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // ดึงข้อมูลโปรไฟล์ผู้ใช้
  // Endpoint: GET /users/profile
  Future<Map<String, dynamic>?> getUserProfile(String token) async {
    final url = Uri.parse('$baseUrl/users/profile');
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
        print('Get Profile Failed: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getting profile: $e');
      return null;
    }
  }

  // ✅ แก้ไข: รับ Token มาด้วย + แก้ URL ให้ถูก (users/profile)
  Future<bool> updateProfile(String token, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/users/profile'); // ✅ API ที่ถูกต้อง

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // ✅ ส่ง Token
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        return true; 
      } else {
        print('Update failed: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Connection error: $e');
      return false;
    }
  }
}
