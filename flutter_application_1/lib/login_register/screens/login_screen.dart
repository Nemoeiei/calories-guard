import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/user_data_provider.dart';
import '../../services/auth_service.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';
import '../../widget/bottom_bar.dart'; // หน้าหลักของ User ทั่วไป
import '/screens/admin/admin_dashboard_screen.dart'; // ✅ อย่าลืม Import ไฟล์หน้า Admin ของคุณ (เช็ค Path ให้ถูกนะ)

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ฟังก์ชันล็อกอินและตรวจสอบ Role
  void _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอก Email และ Password')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // 1. เรียก API ล็อกอิน
    final result = await _authService.login(
        _emailController.text, _passwordController.text);

    setState(() => _isLoading = false);

    if (result['success']) {
      // ✅ ล็อกอินสำเร็จ: ดึงข้อมูลจาก API
      final data = result['data'];
      final int userId = data['user_id'];

      // 🔥 จุดสำคัญ: ดึง role_id มาตรวจสอบ (ถ้าไม่มี ส่งเป็น 2 คือ User ธรรมดา)
      final int roleId = data['role_id'] ?? 2;

      // 2. บันทึกข้อมูลลง Provider
      ref.read(userDataProvider.notifier).setUserId(userId);
      ref.read(userDataProvider.notifier).setLoginInfo(
            _emailController.text,
            _passwordController.text,
          );

      // รอสักครู่เพื่อให้ Provider อัปเดต state เสร็จสมบูรณ์
      await Future.delayed(const Duration(milliseconds: 100));

      if (mounted) {
        // 🔥 3. สร้างทางแยก (Router Logic)
        if (roleId == 1) {
          // ถ้าเป็น Admin (1) -> ไปหน้า Admin Dashboard
          print("User is Admin: Redirecting to Admin Dashboard");
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (context) => const AdminDashboardScreen()),
            (route) => false,
          );
        } else {
          // ถ้าเป็น User ทั่วไป (2) -> ไปหน้า Main Screen ปกติ
          print("User is Normal Member: Redirecting to Home");
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
            (route) => false,
          );
        }
      }
    } else {
      // ❌ ล็อกอินไม่สำเร็จ
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(result['message'] ?? 'อีเมลหรือรหัสผ่านไม่ถูกต้อง'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EFCF), // พื้นหลังสีเขียวอ่อน
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 65),
            child: Column(
              children: [
                const SizedBox(height: 60),
                const Text(
                  'ลงชื่อเข้าสู่ระบบ',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 32,
                      fontWeight: FontWeight.w400,
                      color: Colors.black),
                ),
                const SizedBox(height: 40),

                // Profile Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: Color(0xFFD9D9D9)),
                  child: const Center(
                      child: Icon(Icons.person,
                          size: 85, color: Color(0xFF959595))),
                ),
                const SizedBox(height: 40),

                // Email Input
                _buildTextField(
                    _emailController, 'Email', Icons.email_outlined, false),
                const SizedBox(height: 19),

                // Password Input
                _buildTextField(
                    _passwordController, 'Password', Icons.lock_outlined, true),

                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 9),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const ForgotPasswordScreen()),
                        );
                      }, // ใส่ Logic ลืมรหัสผ่านตรงนี้
                      child: Text('ลืมรหัสผ่าน?',
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: Colors.black.withOpacity(0.5))),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Login Button
                GestureDetector(
                  onTap: _isLoading
                      ? null
                      : _handleLogin, // เรียกใช้ฟังก์ชัน _handleLogin
                  child: Container(
                    width: 259,
                    height: 54,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4C6414),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 4,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: Center(
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text('เข้าสู่ระบบ',
                              style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Divider Or
                Row(
                  children: [
                    Expanded(
                        child: Container(
                            height: 1, color: const Color(0xFF979797))),
                    const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('or',
                            style: TextStyle(
                                fontSize: 20, color: Color(0xFF979797)))),
                    Expanded(
                        child: Container(
                            height: 1, color: const Color(0xFF979797))),
                  ],
                ),

                const SizedBox(height: 28),

                // Social Login Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSocialButton(Icons.facebook, Colors.blue),
                    const SizedBox(width: 20),
                    _buildSocialButton(Icons.g_mobiledata, Colors.red,
                        size: 35),
                  ],
                ),

                const SizedBox(height: 13),

                // Register Button
                GestureDetector(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const RegisterScreen())),
                  child: Container(
                    width: 259,
                    height: 54,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF4D4D),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 4,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: const Center(
                      child: Text('สร้างบัญชีใหม่',
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    ),
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget ย่อยสำหรับ Input Field
  Widget _buildTextField(TextEditingController controller, String hint,
      IconData icon, bool isPassword) {
    return Container(
      width: 259,
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 4,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.black.withOpacity(0.6), size: 24),
          const SizedBox(width: 17),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: isPassword,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    color: Colors.black.withOpacity(0.5)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget ย่อยสำหรับ Social Button
  Widget _buildSocialButton(IconData icon, Color color, {double size = 24}) {
    return Container(
      width: 40,
      height: 40,
      decoration:
          const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
      child: Icon(icon, color: color, size: size),
    );
  }
}
