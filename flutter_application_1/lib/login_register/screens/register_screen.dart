import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/user_data_provider.dart'; // Import Provider
import 'gender_selection_screen.dart'; // ไปหน้าเลือกเพศต่อ

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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EFCF), // พื้นหลังสีครีมเขียว
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. Header (ปุ่มย้อนกลับ) ---
              Padding(
                padding: const EdgeInsets.only(left: 19, top: 31),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1D1B20)),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              const SizedBox(height: 20),

              // --- 2. Title ---
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

              // --- 3. Form Fields ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 62), // ตาม CSS (left: 62)
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ชื่อ - นามสกุล
                    _buildLabel('ชื่อ - นามสกุล *'),
                    const SizedBox(height: 6),
                    _buildTextField(_nameController),

                    const SizedBox(height: 20),

                    // E-mail
                    _buildLabel('E-mail *'),
                    const SizedBox(height: 6),
                    _buildTextField(_emailController),

                    const SizedBox(height: 20),

                    // Password
                    _buildLabel('Password *'),
                    const SizedBox(height: 6),
                    _buildTextField(_passwordController, isPassword: true),

                    const SizedBox(height: 20),

                    // Confirm password
                    _buildLabel('Confirm password *'),
                    const SizedBox(height: 6),
                    _buildTextField(_confirmPasswordController, isPassword: true),
                  ],
                ),
              ),

              const SizedBox(height: 80),

              // --- 4. Submit Button (Login/Register) ---
              Center(
                child: GestureDetector(
                  onTap: _handleRegister,
                  child: Container(
                    width: 259,
                    height: 54,
                    decoration: BoxDecoration(
                      color: const Color(0xFF628141), // สีเขียวเข้ม
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
                        'Done', // ตามในรูปเขียนว่า Login (แต่บริบทคือ Register)
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

  // Helper: สร้าง Label หัวข้อ
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

  // Helper: สร้างช่องกรอก (กรอบขาวมน)
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

  // Logic การกดปุ่มสมัคร
  void _handleRegister() {
    // 1. Validate
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

    // 2. Save Data to Provider
    // เก็บชื่อ (ไว้ใช้ทีหลังถ้าต้องการ) และ Login Info
    ref.read(userDataProvider.notifier).setLoginInfo(
      _emailController.text, 
      _passwordController.text,
    );
    // (ถ้าอยากเก็บชื่อด้วย ต้องไปเพิ่ม field 'name' ใน setLoginInfo หรือแยกฟังก์ชัน setRegisterInfo)
    
    // 3. Go to Gender Selection (เริ่ม Flow เลือกเพศต่อ)
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GenderSelectionScreen()),
    );
  }
}