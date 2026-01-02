import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/user_data_provider.dart'; 
import 'gender_selection_screen.dart'; 
import '../../services/auth_service.dart'; // ✅ 1. อย่าลืม Import Service นี้

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // ✅ 2. สร้างตัวแปร Service และ Loading
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ✅ 3. ฟังก์ชันสมัครสมาชิก (เชื่อม Database)
  void _handleRegister() async {
    // --- Validation (ตรวจสอบความถูกต้อง) ---
    if (_nameController.text.isEmpty || 
        _emailController.text.isEmpty || 
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบถ้วน')),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('รหัสผ่านไม่ตรงกัน')),
      );
      return;
    }

    // --- เริ่มเชื่อมต่อ API ---
    setState(() => _isLoading = true); // แสดง Loading

    // เรียก API ไปที่ Python Backend
    // ส่ง: username (ชื่อ), email, password
    final result = await _authService.register(
      _nameController.text, 
      _emailController.text,
      _passwordController.text,
    );

    setState(() => _isLoading = false); // หยุด Loading

    if (result['success']) {
  // 1. ดึง ID จาก JSON ที่ Backend ส่งกลับมา (อิงตามโครงสร้าง FastAPI ที่เราทำ)
  final int newId = result['data']['user']['user_id'];
  
  // 2. สั่งให้ Provider บันทึก ID นี้ลงใน State ของแอป
  ref.read(userDataProvider.notifier).setUserId(newId); 

  // 3. ไปหน้าเลือกเพศต่อ
  if (mounted) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GenderSelectionScreen()),
    );
  }
} else {
      // ❌ สมัครไม่ผ่าน (เช่น อีเมลซ้ำ หรือ Server Error)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'สมัครสมาชิกไม่สำเร็จ'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EFCF),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header ---
              Padding(
                padding: const EdgeInsets.only(left: 19, top: 31),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1D1B20)),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              const SizedBox(height: 20),

              // --- Title ---
              const Center(
                child: Text(
                  'สร้างบัญชีผู้ใช้ใหม่',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 32,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
              ),

              const SizedBox(height: 50),

              // --- Form Fields ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 62),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('ชื่อ - นามสกุล *'),
                    const SizedBox(height: 6),
                    _buildTextField(_nameController),

                    const SizedBox(height: 20),

                    _buildLabel('E-mail *'),
                    const SizedBox(height: 6),
                    _buildTextField(_emailController),

                    const SizedBox(height: 20),

                    _buildLabel('Password *'),
                    const SizedBox(height: 6),
                    _buildTextField(_passwordController, isPassword: true),

                    const SizedBox(height: 20),

                    _buildLabel('Confirm password *'),
                    const SizedBox(height: 6),
                    _buildTextField(_confirmPasswordController, isPassword: true),
                  ],
                ),
              ),

              const SizedBox(height: 80),

              // --- Submit Button (Done) ---
              Center(
                child: GestureDetector(
                  onTap: _isLoading ? null : _handleRegister, // ถ้าโหลดอยู่กดไม่ได้
                  child: Container(
                    width: 259,
                    height: 54,
                    decoration: BoxDecoration(
                      color: const Color(0xFF628141),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 4,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      // ถ้าโหลดอยู่ให้โชว์หมุนๆ
                      child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Done',
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
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets ---
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Colors.black.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, {bool isPassword = false}) {
    return Container(
      width: 266,
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: TextField(
          controller: controller,
          obscureText: isPassword,
          decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true,
          ),
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}