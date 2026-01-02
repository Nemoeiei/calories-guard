import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/user_data_provider.dart';

// ✅ 1. Import ไฟล์ที่จำเป็น (แก้ path ให้ตรงกับเครื่องคุณนะ)
import 'register_screen.dart'; // หน้าสมัครสมาชิก
import '../../widget/bottom_bar.dart'; // หน้าหลัก (ที่มี Bottom Bar)
import '../../services/auth_service.dart'; // Service ที่ใช้คุยกับ Python

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  // ✅ 2. เพิ่มตัวแปร Service และ Loading
  final AuthService _authService = AuthService();
  bool _isLoading = false; // เอาไว้โชว์วงกลมหมุนๆ ตอนกดปุ่ม

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ✅ 3. ฟังก์ชันล็อกอิน (เชื่อม Database)
  void _handleLogin() async {
    // ตรวจสอบว่ากรอกครบไหม
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอก Email และ Password')),
      );
      return;
    }

    // เริ่มโหลด (แสดงวงกลมหมุน)
    setState(() => _isLoading = true);

    // 1. เรียก API ล็อกอิน
    final result = await _authService.login(
      _emailController.text, 
      _passwordController.text
    );

    setState(() => _isLoading = false);

    if (result['success']) {
      // ✅ จุดที่ต้องแก้คือตรงนี้!
      
      // 1. ดึง ID ออกมาจากผลลัพธ์
      final int userId = result['data']['user_id']; 
      
      // 2. สั่ง Provider ให้จำ ID "เดี๋ยวนั้นเลย" (สำคัญมาก)
      ref.read(userDataProvider.notifier).setUserId(userId);
      
      // 3. จำข้อมูลอื่นๆ ด้วย
      ref.read(userDataProvider.notifier).setLoginInfo(
        _emailController.text, 
        _passwordController.text,
      );

      // 4. รอแป๊บนึงเพื่อให้แน่ใจว่า Provider อัปเดตค่าเสร็จแล้ว (Optional แต่ช่วยได้)
      await Future.delayed(const Duration(milliseconds: 100));

      // 5. ค่อยเปลี่ยนหน้า
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()), // ไปหน้า Main
          (route) => false,
        );
      }
    } else {
      // --- ล็อกอินล้มเหลว ---
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'เข้าสู่ระบบไม่สำเร็จ'), 
            backgroundColor: Colors.red
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFFE8EFCF),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 65),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 62),
                  const Center(
                    child: Text(
                      'ลงชื่อเข้าสู่ระบบ',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 32,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),
                  
                  // ... (ส่วนรูปโปรไฟล์เหมือนเดิม) ...
                  Center(
                    child: Container(
                      width: 120, height: 120,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFD9D9D9),
                      ),
                      child: const Center(
                        child: Icon(Icons.person, size: 85, color: Color(0xFF959595)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),

                  // ... (Email Input เหมือนเดิม) ...
                  Container(
                    width: 259, height: 54,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 4, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.email_outlined, color: Colors.black.withOpacity(0.6), size: 24),
                        const SizedBox(width: 17),
                        Expanded(
                          child: TextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              hintText: 'Email',
                              hintStyle: TextStyle(fontFamily: 'Inter', fontSize: 20, color: Colors.black.withOpacity(0.5)),
                              border: InputBorder.none, contentPadding: EdgeInsets.zero, isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 19),

                  // ... (Password Input เหมือนเดิม) ...
                  Container(
                    width: 259, height: 54,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 4, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lock_outlined, color: Colors.black.withOpacity(0.6), size: 24),
                        const SizedBox(width: 17),
                        Expanded(
                          child: TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              hintText: 'Password',
                              hintStyle: TextStyle(fontFamily: 'Inter', fontSize: 20, color: Colors.black.withOpacity(0.5)),
                              border: InputBorder.none, contentPadding: EdgeInsets.zero, isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 9),
                  // ... (Forgot Password Link เหมือนเดิม) ...
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {},
                      child: Padding(
                        padding: const EdgeInsets.only(right: 0),
                        child: Text(
                          'ลืมรหัสผ่าน?',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Colors.black.withOpacity(0.5)),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),

                  // --- Login Button (แก้ไขให้เรียกใช้ _handleLogin) ---
                  GestureDetector(
                    onTap: _isLoading ? null : _handleLogin, // ✅ ถ้าโหลดอยู่ ห้ามกดซ้ำ
                    child: Container(
                      width: 259, height: 54,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4C6414),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 4, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Center(
                        // ✅ ถ้าโหลดอยู่ ให้โชว์วงกลมหมุนๆ แทนตัวหนังสือ
                        child: _isLoading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'เข้าสู่ระบบ',
                              style: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),
                  // ... (Or Divider เหมือนเดิม) ...
                  SizedBox(
                    width: 274,
                    child: Row(
                      children: [
                        Expanded(child: Container(height: 1, color: const Color(0xFF979797))),
                        const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('or', style: TextStyle(fontSize: 20, color: Color(0xFF979797)))),
                        Expanded(child: Container(height: 1, color: const Color(0xFF979797))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ... (Facebook/Google เหมือนเดิม) ...
                  
                  const SizedBox(height: 13),

                  // --- Create Account Button (แก้ไขให้ไปหน้า Register) ---
                  GestureDetector(
                    onTap: () {
                      // ✅ สั่งให้ไปหน้าสมัครสมาชิก
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterScreen()),
                      );
                    },
                    child: Container(
                      width: 259, height: 54,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4D4D),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 4, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'สร้างบัญชีใหม่',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}