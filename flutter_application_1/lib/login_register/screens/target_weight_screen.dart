import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/user_data_provider.dart';
// 👇 Import ไฟล์ MainScreen
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

  @override
  void dispose() {
    _targetWeightController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // กำหนดตัวแปรสำหรับ UI ตาม Goal ที่เลือก
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
                // Back Button
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 19, top: 31),
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.chevron_left,
                        size: 40,
                        color: Color(0xFF1D1B20),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Title
                Text(
                  titleText,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: subTitleColor,
                  ),
                ),

                const SizedBox(height: 30),

                // Image
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Input Fields
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

                // --- ปุ่มเสร็จสิ้น (ไปหน้า MainScreen) ---
                GestureDetector(
                  onTap: () {
                    // 1. บันทึกข้อมูลลง Provider
                    double targetW = double.tryParse(_targetWeightController.text) ?? 0.0;
                    int dur = int.tryParse(_durationController.text) ?? 0;
                    
                    ref.read(userDataProvider.notifier).setGoalInfo(
                      targetWeight: targetW, 
                      duration: dur
                    );

                    // 2. 🔥 จบ Flow สมัคร: ไปหน้า MainScreen
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const MainScreen()),
                      (route) => false, // ล้างประวัติหน้าสมัครทิ้ง
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
                        'เสร็จสิ้น',
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
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              controller: controller,
              keyboardType: isNumber
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.text,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF909090),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.only(bottom: 8),
              ),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }
}