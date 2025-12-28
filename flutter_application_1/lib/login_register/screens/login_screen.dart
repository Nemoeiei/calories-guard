import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 1. Import Riverpod
import '../../providers/user_data_provider.dart'; // 2. Import Provider
import 'gender_selection_screen.dart';

// 3. เปลี่ยนเป็น ConsumerStatefulWidget
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFFE8EFCF), // 👈 พื้นหลังสีที่ต้องการ
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 65),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 62),
                  
                  // Title
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
                  
                  // Profile Image
                  Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFD9D9D9),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.person,
                          size: 85,
                          color: Color(0xFF959595),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 50),
                  
                  // Email Input Field
                  Container(
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
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 30,
                          height: 30,
                          child: Icon(
                            Icons.email_outlined,
                            color: Colors.black.withOpacity(0.6),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 17),
                        Expanded(
                          child: TextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              hintText: 'Email',
                              hintStyle: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 20,
                                fontWeight: FontWeight.w400,
                                color: Colors.black.withOpacity(0.5),
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              isDense: true,
                            ),
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 19),
                  
                  // Password Input Field
                  Container(
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
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 30,
                          height: 30,
                          child: Icon(
                            Icons.lock_outlined,
                            color: Colors.black.withOpacity(0.6),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 17),
                        Expanded(
                          child: TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              hintText: 'Password',
                              hintStyle: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 20,
                                fontWeight: FontWeight.w400,
                                color: Colors.black.withOpacity(0.5),
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              isDense: true,
                            ),
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 9),
                  
                  // Forgot Password Link
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {
                        print('Forgot password tapped');
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(right: 0),
                        child: Text(
                          'ลืมรหัสผ่าน?',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Colors.black.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Login Button (ใช้สำหรับไปหน้าถัดไปใน Flow สมัคร)
                  GestureDetector(
                    onTap: () {
                      // 1. ตรวจสอบว่ากรอกข้อมูลหรือยัง
                      if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
                         ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('กรุณากรอก Email และ Password')),
                        );
                        return;
                      }

                      // 2. บันทึกข้อมูลลง Provider (ถังกลาง)
                      ref.read(userDataProvider.notifier).setLoginInfo(
                        _emailController.text, 
                        _passwordController.text
                      );

                      // 3. ไปหน้าเลือกเพศ (GenderSelection)
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GenderSelectionScreen(),
                        ),
                      );
                    },
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
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'Login',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 28),
                  
                  // "or" Divider
                  SizedBox(
                    width: 274,
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 1,
                            color: const Color(0xFF979797),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            'or',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF979797),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 1,
                            color: const Color(0xFF979797),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 28),
                  
                  // Facebook Login Button
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 259,
                      height: 54,
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0065E7),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 4,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(2.0), 
                              child: Image.network(
                                'https://upload.wikimedia.org/wikipedia/commons/thumb/0/05/Facebook_Logo_%282019%29.png/600px-Facebook_Logo_%282019%29.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                             child: Text(
                              'เข้าสู่ระบบด้วย Facebook',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 13),
                  
                  // Google Login Button
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 259,
                      height: 54,
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 4,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Image.network(
                                'https://cdn1.iconfinder.com/data/icons/google-s-logo/150/Google_Icons-09-512.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'เข้าสู่ระบบด้วย Google',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 13),
                  
                  // Create Account Button
                  GestureDetector(
                    onTap: () {
                      // ถ้าต้องการให้ปุ่มนี้ทำหน้าที่สมัครสมาชิกด้วย ก็ใส่โค้ดเหมือนปุ่ม Login ข้างบน
                    },
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
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'สร้างบัญชีใหม่',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
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