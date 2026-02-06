import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/user_data_provider.dart';
import '../../services/auth_service.dart';
import '/widget/bottom_bar.dart'; 

class TargetWeightScreen extends ConsumerStatefulWidget {
  final GoalOption selectedGoal;

  const TargetWeightScreen({
    super.key,
    required this.selectedGoal,
  });

  @override
  ConsumerState<TargetWeightScreen> createState() => _TargetWeightScreenState();
}

class _TargetWeightScreenState extends ConsumerState<TargetWeightScreen> {
  final TextEditingController _targetWeightController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _targetWeightController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  // ✅ ฟังก์ชันบันทึกข้อมูล (รวมแคลอรี่และสารอาหาร) และจบ Flow
  void _saveAndFinish() async {
    if (_targetWeightController.text.isEmpty || _durationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบถ้วน')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // 1. เตรียมข้อมูลพื้นฐาน
    double targetW = double.tryParse(_targetWeightController.text) ?? 0.0;
    int weeks = int.tryParse(_durationController.text) ?? 0;
    
    // คำนวณวันที่เป้าหมาย
    DateTime targetDate = DateTime.now().add(Duration(days: weeks * 7));
    String targetDateStr = "${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}";

    // 2. 🔥 ดึงค่าแคลอรี่และคำนวณสารอาหาร
    // จำลอง UserData ชั่วคราวเพื่อคำนวณค่า TDEE
    final currentGoal = widget.selectedGoal;
    final currentUserData = ref.read(userDataProvider);
    final tempUserData = currentUserData.copyWith(goal: currentGoal);
    
    // 2.1 คำนวณแคลอรี่เป้าหมาย (TDEE +/- ตาม Goal)
    int calculatedCalories = tempUserData.targetCalories.toInt();

    // 2.2 🔥 คำนวณสารอาหาร (Macros) ตรงนี้เลย 
    // สัดส่วนมาตรฐาน: Protein 30% / Carbs 40% / Fat 30%
    int targetProtein = (calculatedCalories * 0.30 / 4).round(); // 1g Protein = 4 kcal
    int targetCarbs = (calculatedCalories * 0.40 / 4).round();   // 1g Carbs = 4 kcal
    int targetFat = (calculatedCalories * 0.30 / 9).round();     // 1g Fat = 9 kcal

    // 3. ส่งข้อมูลทั้งหมดไป Backend
    final token = ref.read(userDataProvider).token;
    if (token == null) return;

    bool success = await _authService.updateProfile(token, {
      "target_weight_kg": targetW,
      "goal_target_date": targetDateStr,
      "target_calories": calculatedCalories,
      "target_protein": targetProtein, // ✅ ส่งโปรตีน
      "target_carbs": targetCarbs,     // ✅ ส่งคาร์บ
      "target_fat": targetFat,         // ✅ ส่งไขมัน
    });

    setState(() => _isLoading = false);

    if (success) {
      // 4. บันทึกสำเร็จ: อัปเดต Provider แล้วเข้าหน้าหลัก
      ref.read(userDataProvider.notifier).setGoalInfo(
        targetWeight: targetW, 
        duration: weeks
      );
      
      // อัปเดต Goal ใน Provider ให้ตรงกับปัจจุบัน
      ref.read(userDataProvider.notifier).setGoal(widget.selectedGoal);

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()), 
          (route) => false, 
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกข้อมูลไม่สำเร็จ กรุณาลองใหม่')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // กำหนดค่า UI ตามเป้าหมายที่เลือก
    String titleText = '';
    Color subTitleColor = Colors.black;
    String imageUrl = '';

    switch (widget.selectedGoal) {
      case GoalOption.loseWeight:
        titleText = 'การลดน้ำหนัก ควบคุมแคลอรี่';
        subTitleColor = const Color(0xFFD76A3C);
        imageUrl = 'https://api.builder.io/api/v1/image/assets/TEMP/c692273e970a0499647242c74577239038234857ef0d94f2430263f33ce23992?width=438'; 
        break;
      case GoalOption.maintainWeight:
        titleText = 'การรักษาน้ำหนัก รักษาสุขภาพ';
        subTitleColor = const Color(0xFF67B054);
        imageUrl = 'https://api.builder.io/api/v1/image/assets/TEMP/39e9f9449f802c6d70233e72dc4f6733224422206772740922634356e72c0c7b?width=438';
        break;
      case GoalOption.buildMuscle:
        titleText = 'การเพิ่มกล้ามเนื้อ สร้างความแข็งแรง';
        subTitleColor = const Color(0xFF3C7DD7);
        imageUrl = 'https://api.builder.io/api/v1/image/assets/TEMP/f2df200020a67972049e6329c32f83737ec3802e340794c49742469837a77d70?width=438';
        break;
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFFE8EFCF),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 19, top: 31),
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.chevron_left, size: 40, color: Color(0xFF1D1B20)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  titleText,
                  style: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w600, color: subTitleColor),
                ),
                const SizedBox(height: 30),
                Container(
                  width: 250, height: 250,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      _buildInputRow('น้ำหนักเป้าหมาย', '60', _targetWeightController, isNumber: true),
                      const SizedBox(height: 20),
                      _buildInputRow('ระยะเวลา (สัปดาห์)', '12', _durationController, isNumber: true),
                    ],
                  ),
                ),
                const SizedBox(height: 50),
                
                // --- ปุ่มเสร็จสิ้น ---
                GestureDetector(
                  onTap: _isLoading ? null : _saveAndFinish, // ✅ เรียกฟังก์ชันบันทึก
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
                      child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('เสร็จสิ้น', style: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white)),
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

  Widget _buildInputRow(String label, String hintText, TextEditingController controller, {bool isNumber = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 160,
          child: Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 40,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: TextField(
              controller: controller,
              keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFF909090)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.only(bottom: 8),
              ),
              style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w400, color: Colors.black),
            ),
          ),
        ),
      ],
    );
  }
}