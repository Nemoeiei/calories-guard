import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/constants.dart';

class AuthService {
  // ใช้ค่าเดียวกับ AppConstants เพื่อแก้ไข URL ที่เดียว
  final String baseUrl = AppConstants.baseUrl;
  final SupabaseClient _supabase = Supabase.instance.client;

  // ฟังก์ชันสมัครสมาชิก
  Future<Map<String, dynamic>> register(
      String username, String email, String password) async {
    final url = Uri.parse('$baseUrl/register');

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
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Registration failed'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // ฟังก์ชันเข้าสู่ระบบ
  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/login');

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
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Login failed'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // ฟังก์ชันยืนยันอีเมล
  Future<Map<String, dynamic>> verifyEmail(String email, String code) async {
    final url = Uri.parse('$baseUrl/verify-email');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'code': code,
        }),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Verification failed'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // ฟังก์ชันขอส่งรหัสยืนยันอีเมลใหม่
  Future<Map<String, dynamic>> resendEmailVerification(String email) async {
    final url = Uri.parse('$baseUrl/resend-verification-email');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': jsonDecode(response.body)['message']
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Resend failed'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> requestPasswordReset(
      String email, String birthDate) async {
    final url = Uri.parse('$baseUrl/password-reset/request');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'birth_date': birthDate}),
      );
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': jsonDecode(response.body)['message']
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Request failed'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> verifyResetCode(
      String email, String code, String birthDate) async {
    final url = Uri.parse('$baseUrl/password-reset/verify');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body:
            jsonEncode({'email': email, 'code': code, 'birth_date': birthDate}),
      );
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': jsonDecode(response.body)['message']
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Verify failed'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> confirmResetPassword(
      String email, String code, String birthDate, String newPassword) async {
    final url = Uri.parse('$baseUrl/password-reset/confirm');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'code': code,
          'birth_date': birthDate,
          'new_password': newPassword,
        }),
      );
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': jsonDecode(response.body)['message']
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Reset failed'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  /// Social login (Google / Facebook) — finds or auto-creates the user in our backend.
  Future<Map<String, dynamic>> socialLogin({
    required String email,
    required String name,
    required String uid,
    required String provider,
  }) async {
    final url = Uri.parse('$baseUrl/social-login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'name': name,
          'uid': uid,
          'provider': provider,
        }),
      );
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Social login failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> oauthLogin(String accessToken) async {
    final url = Uri.parse('$baseUrl/oauth-login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'access_token': accessToken}),
      );
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['detail'] ?? 'OAuth login failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> signInWithGoogleViaSupabase() async {
    try {
      final serverClientId = AppConstants.googleWebClientId.trim();
      if (serverClientId.isEmpty) {
        return {
          'success': false,
          'message': 'Missing GOOGLE_WEB_CLIENT_ID for Google Sign-In',
        };
      }

      final googleSignIn = GoogleSignIn(serverClientId: serverClientId);
      await googleSignIn.signOut();

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return {
          'success': false,
          'message': 'Google Sign-In cancelled',
        };
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null || accessToken == null) {
        return {
          'success': false,
          'message': 'Google token is missing. Check Google OAuth client configuration.',
        };
      }

      await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      final sessionToken = _supabase.auth.currentSession?.accessToken;
      if (sessionToken == null || sessionToken.isEmpty) {
        return {
          'success': false,
          'message': 'Supabase session was not created',
        };
      }

      return oauthLogin(sessionToken);
    } on AuthException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': 'Google Sign-In failed: $e'};
    }
  }

  Future<bool> updateProfile(int userId, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/users/$userId');

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}
