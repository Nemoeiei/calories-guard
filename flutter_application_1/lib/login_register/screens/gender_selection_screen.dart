import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/user_data_provider.dart'; 
import '../../services/auth_service.dart'; // ✅ เรียกใช้ Service ตัวเดิม
import 'personal_info_screen.dart';

class GenderSelectionScreen extends ConsumerStatefulWidget {
  const GenderSelectionScreen({super.key});

  @override
  ConsumerState<GenderSelectionScreen> createState() => _GenderSelectionScreenState();
}

class _GenderSelectionScreenState extends ConsumerState<GenderSelectionScreen> {
  String? selectedGender;
  final AuthService _authService = AuthService(); // ✅ สร้างตัวแปร Service
  bool _isLoading = false;

  // 🔥 ฟังก์ชันใหม่: ส่งค่าเพศไปเก็บใน Database
  void _saveGenderToDb() async {
    if (selectedGender == null) return;

    setState(() => _isLoading = true);

    // 1. ดึง user_id ของคนที่เพิ่งสมัคร/ล็อกอิน มาจาก Provider
    final userId = ref.read(userDataProvider).userId; 

    // 2. ยิง API ไปที่ Backend (ใช้คำสั่ง PUT ที่เราเขียนไว้)
    bool isSuccess = await _authService.updateProfile(userId, {
      "gender": selectedGender, 
    });

    setState(() => _isLoading = false);

    if (isSuccess) {
      // ✅ ถ้าสำเร็จ อัปเดตข้อมูลในแอปด้วย แล้วไปหน้าถัดไป
      ref.read(userDataProvider.notifier).setGender(selectedGender!);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PersonalInfoScreen()),
        );
      }
    } else {
      // ❌ ถ้าไม่สำเร็จ
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่สามารถบันทึกเพศได้ กรุณาลองใหม่'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EFCF),
      body: SafeArea(
        child: Column(
          children: [
            // ... (ส่วน Header และปุ่มย้อนกลับ เหมือนเดิม) ...
            const SizedBox(height: 50),
            const Text('เลือกเพศของคุณ', style: TextStyle(fontSize: 32)),
            
            const SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildGenderCard('female', 'หญิง', 'assets/images/picture/girl.png'),
                const SizedBox(width: 20),
                _buildGenderCard('male', 'ชาย', 'assets/images/picture/boy.png'),
              ],
            ),
            
            const Spacer(),
            
            // ✅ ปุ่มถัดไปที่เรียกใช้ฟังก์ชันบันทึกข้อมูลจริง
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: GestureDetector(
                onTap: (selectedGender != null && !_isLoading) ? _saveGenderToDb : null,
                child: Container(
                  width: 259, height: 54,
                  decoration: BoxDecoration(
                    color: selectedGender != null ? const Color(0xFF4C6414) : Colors.grey,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('ถัดไป', style: TextStyle(color: Colors.white, fontSize: 20)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper สร้าง Card เพศ
  Widget _buildGenderCard(String gender, String label, String imgPath) {
    bool isSelected = selectedGender == gender;
    return GestureDetector(
      onTap: () => setState(() => selectedGender = gender),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.withOpacity(0.2) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: isSelected ? Border.all(color: Colors.green, width: 2) : null,
        ),
        child: Column(
          children: [
            Image.asset(imgPath, width: 100, height: 100),
            Text(label, style: const TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
}