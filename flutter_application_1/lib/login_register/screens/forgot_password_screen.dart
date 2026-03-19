import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_service.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  int _step = 0;
  Timer? _timer;
  int _remainingTime = 0;

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _codeController.dispose();
    _birthDateController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showMessage(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg),
          backgroundColor: isError ? Colors.red : Colors.green),
    );
  }

  void _startTimer() {
    setState(() => _remainingTime = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingTime > 0) {
        setState(() => _remainingTime--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _resendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    
    setState(() => _isLoading = true);
    final result = await _authService.requestPasswordReset(email);
    setState(() => _isLoading = false);
    
    if (result['success']) {
      _showMessage(result['message'] ?? 'ส่งรหัสยืนยันใหม่แล้ว');
      _startTimer();
    } else {
      _showMessage(result['message'] ?? 'ส่งรหัสไม่สำเร็จ', isError: true);
    }
  }

  Future<void> _sendResetCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showMessage('กรุณากรอกอีเมล', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    final result = await _authService.requestPasswordReset(email);
    setState(() => _isLoading = false);
    if (result['success']) {
      _showMessage(result['message'] ?? 'ส่งโค้ดสำเร็จ');
      setState(() => _step = 1);
      _startTimer();
    } else {
      _showMessage(result['message'] ?? 'ส่งโค้ดไม่สำเร็จ', isError: true);
    }
  }

  Future<void> _verifyCode() async {
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();
    final birth = _birthDateController.text.trim();
    if (email.isEmpty || code.isEmpty || birth.isEmpty) {
      _showMessage('กรุณากรอกข้อมูลให้ครบ', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    final result = await _authService.verifyResetCode(email, code, birth);
    setState(() => _isLoading = false);
    if (result['success']) {
      _showMessage(result['message'] ?? 'ยืนยันโค้ดสำเร็จ');
      setState(() => _step = 2);
    } else {
      _showMessage(result['message'] ?? 'ยืนยันโค้ดไม่สำเร็จ', isError: true);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();
    final birth = _birthDateController.text.trim();
    final password = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    if (email.isEmpty ||
        code.isEmpty ||
        birth.isEmpty ||
        password.isEmpty ||
        confirm.isEmpty) {
      _showMessage('กรุณากรอกข้อมูลให้ครบ', isError: true);
      return;
    }
    if (password.length < 6) {
      _showMessage('รหัสผ่านต้องอย่างน้อย 6 ตัวอักษร', isError: true);
      return;
    }
    if (password != confirm) {
      _showMessage('รหัสผ่านไม่ตรงกัน', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    final result =
        await _authService.confirmResetPassword(email, code, birth, password);
    setState(() => _isLoading = false);
    if (result['success']) {
      _showMessage(result['message'] ?? 'รีเซ็ตรหัสผ่านสำเร็จ');
      if (mounted) Navigator.pop(context);
    } else {
      _showMessage(result['message'] ?? 'รีเซ็ตรหัสผ่านไม่สำเร็จ',
          isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EFCF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4C6414),
        title: const Text('ลืมรหัสผ่าน'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ระบบรีเซ็ตรหัสผ่านด้วยโค้ดยืนยันทางอีเมล',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 18),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                    labelText: 'อีเมล', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 14),
              if (_step >= 1) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _codeController,
                        decoration: const InputDecoration(
                            labelText: 'รหัสยืนยัน', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 56, // ให้เข้ากับความสูง TextField โดยประมาณ
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _remainingTime > 0 ? Colors.grey : const Color(0xFF4C6414),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))
                        ),
                        onPressed: _remainingTime > 0 || _isLoading ? null : _resendCode,
                        child: Text(
                          _remainingTime > 0 ? 'รอ $_remainingTime วิ' : 'รับรหัสใหม่',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _birthDateController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _DateTextFormatter(),
                  ],
                  decoration: const InputDecoration(
                      labelText: 'วันเกิด (YYYY-MM-DD)',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 14),
              ],
              if (_step == 2) ...[
                TextField(
                  controller: _newPasswordController,
                  decoration: const InputDecoration(
                      labelText: 'รหัสผ่านใหม่', border: OutlineInputBorder()),
                  obscureText: true,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _confirmPasswordController,
                  decoration: const InputDecoration(
                      labelText: 'ยืนยันรหัสผ่านใหม่',
                      border: OutlineInputBorder()),
                  obscureText: true,
                ),
                const SizedBox(height: 14),
              ],
              const SizedBox(height: 16),
              Center(
                child: SizedBox(
                  width: 260,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4C6414)),
                    onPressed: _isLoading
                        ? null
                        : _step == 0
                            ? _sendResetCode
                            : _step == 1
                                ? _verifyCode
                                : _resetPassword,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text(
                            _step == 0
                                ? 'ยืนยัน'
                                : _step == 1
                                    ? 'ยืนยันตัวตน'
                                    : 'รีเซ็ตรหัสผ่าน',
                            style: const TextStyle(fontSize: 16, color: Colors.white),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (text.length > 8) text = text.substring(0, 8);

    String masked = '';
    for (int i = 0; i < text.length; i++) {
      masked += text[i];
      if ((i == 3 || i == 5) && i != text.length - 1) {
        masked += '-';
      }
    }

    return TextEditingValue(
      text: masked,
      selection: TextSelection.collapsed(offset: masked.length),
    );
  }
}
