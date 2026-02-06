import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/user_data_provider.dart'; 
import 'gender_selection_screen.dart'; 
import '../../services/auth_service.dart'; 

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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showPasswordRules() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('เงื่อนไขรหัสผ่าน', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold)),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RuleItem(text: 'ความยาวอย่างน้อย 8 ตัวอักษร'),
              _RuleItem(text: 'มีตัวพิมพ์ใหญ่ (A-Z) อย่างน้อย 1 ตัว'),
              _RuleItem(text: 'มีอักขระพิเศษ (เช่น !, @, #) อย่างน้อย 1 ตัว'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('เข้าใจแล้ว', style: TextStyle(color: Color(0xFF628141), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _handleRegister() async {
    String name = _nameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text;
    String confirmPassword = _confirmPasswordController.text;

    // Validation
    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showError('กรุณากรอกข้อมูลให้ครบถ้วน');
      return;
    }
    if (name.length < 4) {
      _showError('ชื่อผู้ใช้ต้องมีความยาวอย่างน้อย 4 ตัวอักษร');
      return;
    }
    if (!email.endsWith('@gmail.com')) {
      _showError('กรุณาใช้อีเมล @gmail.com เท่านั้น');
      return;
    }
    if (password.length < 8) {
      _showError('รหัสผ่านต้องมีความยาวอย่างน้อย 8 ตัวอักษร');
      return;
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      _showError('รหัสผ่านต้องมีตัวพิมพ์ใหญ่อย่างน้อย 1 ตัว (A-Z)');
      return;
    }
    if (!password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) {
      _showError('รหัสผ่านต้องมีอักขระพิเศษอย่างน้อย 1 ตัว');
      return;
    }
    if (password != confirmPassword) {
      _showError('รหัสผ่านยืนยันไม่ตรงกัน');
      return;
    }

    // Call API
    setState(() => _isLoading = true); 

    final result = await _authService.register(name, email, password);

    setState(() => _isLoading = false); 

    if (result['success']) {
      final data = result['data']; 
      
      // ✅ หัวใจสำคัญ: ดึง ID และ Token จาก Backend แล้วยัดใส่ Provider ทันที
      // Backend (FastAPI) ส่งกลับมาเป็น TokenResponse: {"access_token": "...", "user_id": 1, ...}
      final int newId = data['user_id']; 
      final String token = data['access_token'];
      
      ref.read(userDataProvider.notifier).setUserId(newId); 
      ref.read(userDataProvider.notifier).setToken(token); // ✅ Save Token 
      ref.read(userDataProvider.notifier).setLoginInfo(email, password);
      ref.read(userDataProvider.notifier).setPersonalInfo(
          name: name, 
          birthDate: DateTime.now(), // ค่าชั่วคราว เดี๋ยวไปแก้หน้า PersonalInfo
          height: 0, 
          weight: 0
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const GenderSelectionScreen()),
        );
      }
    } else {
      if (mounted) {
        _showError(result['message'] ?? 'สมัครสมาชิกไม่สำเร็จ');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFE8EFCF),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 19, top: 31),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1D1B20)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    'สร้างบัญชีผู้ใช้ใหม่',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 32, fontWeight: FontWeight.w400, color: Colors.black),
                  ),
                ),
                const SizedBox(height: 50),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 62),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('ชื่อ - นามสกุล *'),
                      _buildTextField(_nameController),
                      const SizedBox(height: 20),
                      _buildLabel('E-mail *'),
                      _buildTextField(_emailController),
                      const SizedBox(height: 20),
                      _buildLabel('Password *', onInfoTap: _showPasswordRules),
                      _buildTextField(_passwordController, isPassword: true),
                      const SizedBox(height: 20),
                      _buildLabel('Confirm password *'),
                      _buildTextField(_confirmPasswordController, isPassword: true),
                    ],
                  ),
                ),
                const SizedBox(height: 80),
                Center(
                  child: GestureDetector(
                    onTap: _isLoading ? null : _handleRegister, 
                    child: Container(
                      width: 259, height: 54,
                      decoration: BoxDecoration(
                        color: const Color(0xFF628141),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 4, offset: const Offset(0, 4))],
                      ),
                      child: Center(
                        child: _isLoading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Done', style: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, {VoidCallback? onInfoTap}) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 6),
      child: Row(
        children: [
          Text(text, style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w400, color: Colors.black.withOpacity(0.5))),
          if (onInfoTap != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onInfoTap,
              child: const Icon(Icons.help_outline, size: 20, color: Color(0xFF628141)),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, {bool isPassword = false}) {
    return Container(
      width: 266, height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Center(
        child: TextField(
          controller: controller,
          obscureText: isPassword,
          decoration: const InputDecoration(border: InputBorder.none, isDense: true),
          style: const TextStyle(fontFamily: 'Inter', fontSize: 16, color: Colors.black),
        ),
      ),
    );
  }
}

class _RuleItem extends StatelessWidget {
  final String text;
  const _RuleItem({required this.text});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontFamily: 'Inter', fontSize: 14))),
        ],
      ),
    );
  }
}